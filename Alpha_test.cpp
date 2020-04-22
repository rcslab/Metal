#include <verilated.h>
#include <iostream>
#include <stdlib.h>
#include <bitset>
#include "VAlpha.h"

using namespace std;

bool signal_dump = 1;
vluint64_t main_time = 0;       // Current simulation time

double sc_time_stamp () {       // Called by $time in Verilog
    return main_time;           // converts to double, to match
                                // what SystemC does
}

int main(int argc, char** argv) {
    
    Verilated::commandArgs(argc, argv);
    
    VAlpha *top = new VAlpha;
    
    while(!Verilated::gotFinish()) {
//    for (int i = 0; i < 32; i++) {
        top->clk = 0;
        top->eval();
        top->clk = 1;
        top->eval();
	if (top->inst == 0x1D000000) {
	    printf("ICEBP!\n");
	}

        printf("\npc: 0x%08x\n", top->pc);
        printf("inst1: 0x%08x inst2: 0x%08x, inst3: 0x%08x \ninst4: 0x%08x inst5: 0x%08x\n",
               top->inst, top->inst2, top->inst3, top->inst4, top->inst5);
	// Dump Regular Registers
        for (int i = 0; i < 32; i++) {
            printf("%%r%-2d=%08x, ", i, top->Alpha__DOT__irf__DOT__rf__DOT__register[i]);
            if ((i + 1) % 4 == 0)
		printf("\n");
        }

	// Dump Metal Registers
        for (int i = 0; i < 32; i++) {
	    printf("%%mr%-2d=0x%08x, ", i, top->Alpha__DOT__mbox__DOT__metal_regs__DOT__register[i]);
            if ((i + 1) % 4 == 0)
		printf("\n");
        }

	if (signal_dump) {
	printf("----- SIGNAL DUMP -----\n");
//      cout << "alu in1: " << top->ibox_in1 << " in2: " << top->ibox_in2 << 
//      endl;;
        cout << "alu result: " << top->ibox_result << endl;
//        std::bitset<32> x(top->ibox_ctrl);
//         cout << "ibox_ctrl: " << x << endl;
//         printf("DEBUG: In1: %x, In2: %x\n",
//                top->Alpha__DOT__ibox_in1, top->Alpha__DOT__ibox_in2);
//         cout << "reg_w_addr: " << int(top->reg_w_addr) << " reg_w_data: " << top->reg_w_data << " reg_w_en: " << int(top->reg_w_en) << " reg_w: " << int(top->reg_w) << " m3_sel: " << int(top->mbox_m3_sel) << endl;
        cout << "mux3_sel " << int(top->irf_m3_sel) << " mux4_sel " << int(top->irf_m4_sel) << endl;
//        cout << "mem_addr: " << int(top->ibox_result4) << endl;
//        if (top->mem_w_en == 1) cout << "error" << endl;
//        cout << "mem_out: " << top->mem_out << endl;
        cout << " mexit " << int(top->m_exit) << endl;
//        cout << "cmp_out " << int(top->cmp_out) << endl;
//        cout << "reg_a " << int(top->reg_a) << endl;
//        cout << "irf_m1_sel " << int(top->irf_m1_sel) << endl;
//        cout << "m_reg_data " << top->m_reg_data << endl;
//        cout << "m_reg_addr " << int(top->m_reg_addr) << endl;
//        cout << "m_reg_w_en " << int(top->m_reg_w_en) << endl;
//        printf("br addr %x\n", top->Alpha__DOT__ebox__DOT__mux2_in[1]);
	printf("----- END DUMP -----\n");
	}

        if (top->inst == 0x1C000000) {
	    printf("ICEEX encountered exiting!\n");
            break;
        }
    }
    
    top->final();
    delete top;
}
