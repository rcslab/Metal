#include <verilated.h>
#include <iostream>
#include <stdlib.h>
#include <bitset>
#include <vector>
#include "VCacheTestBench.h"

using namespace std;

vluint64_t main_time = 0;       // Current simulation time

double sc_time_stamp () {       // Called by $time in Verilog
    return main_time;           // converts to double, to match
                                // what SystemC does
}

struct Query {
    bool read;
    bool write;
    unsigned long long addr;
    unsigned long long value;
    Query() {}
    Query(bool read, bool write, unsigned long long addr, unsigned long long value) : read(read), write(write), value(value), addr(addr) {}
};

vector<Query> l1c_queries, l1d_queries;
int next_l1c_query = 0;
int next_l1d_query = 0;

void addQueries(vector<Query> &queries, int base_address) {
    queries.push_back(Query(true, false, base_address + 0, 0));
    queries.push_back(Query(true, true, base_address + 1, 0xffffffffffffffffull));
    queries.push_back(Query(true, false, base_address + 8, 0));
    queries.push_back(Query(true, true, base_address + 67, 0x0000000000000029ull));
    queries.push_back(Query(true, false, base_address + 4, 0));
    queries.push_back(Query(true, false, base_address + 67, 0));

    queries.push_back(Query(true, true, base_address + 0, 1));
    queries.push_back(Query(true, true, base_address + 4096, 2));
    queries.push_back(Query(true, false, base_address + 4096*2, 0));
    queries.push_back(Query(true, true, base_address + 4096*3, 4));
    queries.push_back(Query(true, true, base_address + 4096*4, 5));
    queries.push_back(Query(true, true, base_address + 4096*5, 6));
    queries.push_back(Query(true, true, base_address + 4096*6, 7));
    queries.push_back(Query(true, true, base_address + 4096*7, 8));
    // Set Full
    queries.push_back(Query(true, true, base_address + 4096*8, 9));
    queries.push_back(Query(true, false, base_address + 4096, 0));
    queries.push_back(Query(true, true, base_address + 4096*9, 10));
    queries.push_back(Query(false, false, base_address + 0, 0));
    queries.push_back(Query(true, false, base_address + 0, 0));
}

bool askNextCQuery(VCacheTestBench *top) {
    if (next_l1c_query < l1c_queries.size()) {
        top->l1c_addr = l1c_queries[next_l1c_query].addr;
        top->l1c_write_en = l1c_queries[next_l1c_query].write;
        top->l1c_read_en = l1c_queries[next_l1c_query].read;
        top->l1c_write_data = l1c_queries[next_l1c_query].value;
        printf("Asking L1C Query: Addr: %016llx, Data: %016llx, Write: %d, Read: %d\n", top->l1c_addr, top->l1c_write_data, top->l1c_write_en, top->l1c_read_en);
        ++next_l1c_query;
        return true;
    } else return false;
}

bool askNextDQuery(VCacheTestBench *top) {
    if (next_l1d_query < l1d_queries.size()) {
        top->l1d_addr = l1d_queries[next_l1d_query].addr;
        top->l1d_write_en = l1d_queries[next_l1d_query].write;
        top->l1d_read_en = l1d_queries[next_l1d_query].read;
        top->l1d_write_data = l1d_queries[next_l1d_query].value;
        printf("Asking L1D Query: Addr: %016llx, Data: %016llx, Write: %d, Read: %d\n", top->l1d_addr, top->l1d_write_data, top->l1d_write_en, top->l1d_read_en);
        ++next_l1d_query;
        return true;
    } else return false;
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    VCacheTestBench *top = new VCacheTestBench();

    addQueries(l1c_queries, 0);
    addQueries(l1d_queries, 64);

    // Reset
    top->rst = 1;
    top->clk = 0;
    top->eval();
    top->clk = 1;
    top->eval();
    top->rst = 0;

    bool l1c_done = false, l1d_done = false;
    while (!l1c_done || !l1d_done) {
        top->clk = 0;
        top->eval();
        top->clk = 1;
        top->eval();
        printf("Time: %d, L1C-State: %d, L1C-Stall: %d, L1C-Data: %016llx, L1C-Hits: %x, L1C-Which_Block: %d, L1C-LRU idx: %d, L1C-next LRU bits: %x, L1C-LRU_bits(0): %x\n", main_time, top->CacheTestBench__DOT__l1c__DOT__state, top->l1c_stall, top->l1c_read_data, top->CacheTestBench__DOT__l1c__DOT__tf__DOT__hits, top->CacheTestBench__DOT__l1c__DOT__which_block, top->CacheTestBench__DOT__l1c__DOT__lru_index, top->CacheTestBench__DOT__l1c__DOT__next_lru_bits, top->CacheTestBench__DOT__l1c__DOT__lru_bits[0]);
        printf("Time: %d, L1D-State: %d, L1D-Stall: %d, L1D-Data: %016llx, L1D-Hits: %x, L1D-Which_Block: %d, L1D-LRU idx: %d, L1D-next LRU bits: %x, L1D-LRU_bits(0): %x\n", main_time, top->CacheTestBench__DOT__l1d__DOT__state, top->l1d_stall, top->l1d_read_data, top->CacheTestBench__DOT__l1d__DOT__tf__DOT__hits, top->CacheTestBench__DOT__l1d__DOT__which_block, top->CacheTestBench__DOT__l1d__DOT__lru_index, top->CacheTestBench__DOT__l1d__DOT__next_lru_bits, top->CacheTestBench__DOT__l1d__DOT__lru_bits[0]);
        printf("Time: %d, Arbiter-State: %s, Arbiter-Serving: %d, Arbiter-Time: %d, Grant[0]: %d, Grant[1]: %d\n", main_time, top->CacheTestBench__DOT__l2_arbiter__DOT__state ? "WAIT" : "GRANT", top->CacheTestBench__DOT__l2_arbiter__DOT__serving, top->CacheTestBench__DOT__l2_arbiter__DOT__time_passed, top->CacheTestBench__DOT__l2_arbiter_grant[0], top->CacheTestBench__DOT__l2_arbiter_grant[1]);
        printf("Time: %d, L2-State: %d, L2-Stall: %d, L2-Data(0): %016llx, L2-Hits: %x, L2-Which_Block: %d, L2-LRU idx: %d, L2-next LRU bits: %x, L2-LRU_bits(0): %x\n", main_time, top->CacheTestBench__DOT__l2__DOT__state, top->CacheTestBench__DOT__l2_stall, 0, top->CacheTestBench__DOT__l2__DOT__tf__DOT__hits, top->CacheTestBench__DOT__l2__DOT__which_block, top->CacheTestBench__DOT__l2__DOT__lru_index, top->CacheTestBench__DOT__l2__DOT__next_lru_bits, top->CacheTestBench__DOT__l2__DOT__lru_bits[0]);
        main_time++;
        top->l1c_addr = 0;
        top->l1c_write_en = 0;
        top->l1c_read_en = 0;
        top->l1c_write_data = 0;
        top->l1d_addr = 0;
        top->l1d_write_en = 0;
        top->l1d_read_en = 0;
        top->l1d_write_data = 0;
        if (!top->l1c_stall && !l1c_done) {
            if (rand() % 2 == 0) {
                if (!askNextCQuery(top)) l1c_done = true;
            }
        }
        if (!top->l1d_stall && !l1d_done) {
            if (rand() % 2 == 0) {
                if (!askNextDQuery(top)) l1d_done = true;
            }
        }
    }

    top->final();
    delete top;
}
