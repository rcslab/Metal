#include <verilated.h>
#include <iostream>
#include <stdlib.h>
#include <bitset>
#include "VAlpha.h"

using namespace std;

vluint64_t main_time = 0;       // Current simulation time

double sc_time_stamp () {       // Called by $time in Verilog
    return main_time;           // converts to double, to match
                                // what SystemC does
}

int main(int argc, char** argv) {
    
    Verilated::commandArgs(argc, argv);
    
    VAlpha *top = new VAlpha;
    
    while(!Verilated::gotFinish()) {
    //for (int i = 0; i < 10; i++) {
        top->clk = 0;
        top->eval();
        top->clk = 1;
        top->eval();
        if (top->pc == 100) {
//             cout << top->Alpha__DOT__irf__DOT__rf__DOT__register[1] << endl;
            break;
        }
        cout << "pc: " << top->pc << endl;
//         cout << "alu result: " << top->ibox_result << endl;
        std::bitset<32> x(top->ibox_ctrl);
//         cout << "ibox_ctrl: " << x << endl;
        printf("inst1: %x \ninst2: %x \ninst3: %x \ninst4: %x \n inst5: %x\n",
               top->inst, top->inst2, top->inst3, top->inst4, top->inst5);
//         printf("DEBUG: In1: %x, In2: %x\n",
//                top->Alpha__DOT__ibox_in1, top->Alpha__DOT__ibox_in2);
//         cout << "reg_w_addr: " << int(top->reg_w_addr) << " reg_w_data: " << top->reg_w_data << " reg_w_en: " << int(top->reg_w_en) << " reg_w: " << int(top->reg_w) << " m3_sel: " << int(top->mbox_m3_sel) << endl;
        cout << "mux3_sel " << int(top->irf_m3_sel) << " mux4_sel " << int(top->irf_m4_sel) << endl;
        for (int i = 0; i < 5; i++) {
            printf("Reg[%d]=%x", i, top->Alpha__DOT__irf__DOT__rf__DOT__register[i]);
            if (i < 31) printf(", ");
        }
        printf("\n");
    }
    
    top->final();
    delete top;
}
