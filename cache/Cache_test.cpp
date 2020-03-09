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

vector<Query> queries;
int next_query;

void addQueries() {
    queries.push_back(Query(true, false, 0, 0));
    queries.push_back(Query(true, true, 1, 0xffffffffffffffffull));
    queries.push_back(Query(true, false, 8, 0));
    queries.push_back(Query(true, true, 67, 0x0000000000000029ull));
    queries.push_back(Query(true, false, 4, 0));
    queries.push_back(Query(true, false, 67, 0));
    
    queries.push_back(Query(true, true, 0, 1));
    queries.push_back(Query(true, true, 4096, 2));
    queries.push_back(Query(true, false, 4096*2, 0));
    queries.push_back(Query(true, true, 4096*3, 4));
    queries.push_back(Query(true, true, 4096*4, 5));
    queries.push_back(Query(true, true, 4096*5, 6));
    queries.push_back(Query(true, true, 4096*6, 7));
    queries.push_back(Query(true, true, 4096*7, 8));
    // Set Full
    queries.push_back(Query(true, true, 4096*8, 9));
    queries.push_back(Query(true, false, 4096, 0));
    queries.push_back(Query(true, true, 4096*9, 10));
    queries.push_back(Query(false, false, 0, 0));
    queries.push_back(Query(true, false, 0, 0));
    next_query = 0;
}

bool askNextQuery(VCacheTestBench *top) {
    if (next_query < queries.size()) {
        top->p_addr = queries[next_query].addr;
        top->p_write_en = queries[next_query].write;
        top->p_read_en = queries[next_query].read;
        top->p_write_data = queries[next_query].value;
        printf("Asking Query: Addr: %016llx, Data: %016llx, Write: %d, Read: %d\n", top->p_addr, top->p_write_data, top->p_write_en, top->p_read_en);
        ++next_query;
        return true;
    } else return false;
}

int main(int argc, char** argv) {
    
    Verilated::commandArgs(argc, argv);
    
    VCacheTestBench *top = new VCacheTestBench();
    
    addQueries();
    
    // Reset
    top->rst = 1;
    top->clk = 0;
    top->eval();
    top->clk = 1;
    top->eval();
    top->rst = 0;

    while (true) {
        top->clk = 0;
        top->eval();
        top->clk = 1;
        top->eval();
        printf("Time: %d, L1-State: %d, L1-Stall: %d, L1-Data: %016llx, L1-Hits: %x, L1-Which_Block: %d, L1-LRU idx: %d, L1-next LRU bits: %x, L1-LRU_bits(0): %x\n", main_time, top->CacheTestBench__DOT__l1__DOT__state, top->stall, top->p_read_data, top->CacheTestBench__DOT__l1__DOT__tf__DOT__hits, top->CacheTestBench__DOT__l1__DOT__which_block, top->CacheTestBench__DOT__l1__DOT__lru_index, top->CacheTestBench__DOT__l1__DOT__next_lru_bits, top->CacheTestBench__DOT__l1__DOT__lru_bits[0]);
//         printf("Time: %d, L2-State: %d, L2-Stall: %d, L2-Data: %016llx, L2-Hits: %x, L2-Which_Block: %d, L2-LRU idx: %d, L2-next LRU bits: %x, L2-LRU_bits(0): %x\n", main_time, top->CacheTestBench__DOT__l2__DOT__state, top->CacheTestBench__DOT__l2_stall, 0, top->CacheTestBench__DOT__l2__DOT__tf__DOT__hits, top->CacheTestBench__DOT__l2__DOT__which_block, top->CacheTestBench__DOT__l2__DOT__lru_index, top->CacheTestBench__DOT__l2__DOT__next_lru_bits, top->CacheTestBench__DOT__l2__DOT__lru_bits[0]);
        main_time++;
        if (!top->stall) {
            if (rand() % 2 == 0) {
                if (!askNextQuery(top)) break;
            }
        }
    }
    
    top->final();
    delete top;
}
