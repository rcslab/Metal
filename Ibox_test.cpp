#include <verilated.h>          // Defines common routines
#include <iostream>             // Need std::cout
#include <stdlib.h>
#include <random>
#include "VIbox.h"               // From Verilating "top.v"

using namespace std;

unsigned int opcode[] = {
1024, // LDA
1152, // LDAH
1280, // LDBU
1408, // LDQ_U
1536, // LDWU
1664, // STW
1792, // STB
1920, // STQ_U
5120, // LDL
5248, // LDQ
5376, // LDL_L
5504, // LDQ_L
5632, // STL
5760, // STQ
5888, // STL_C
6016, // STQ_C

2048, // ADDL
2050, // S4ADDL
2057, // SUBL
2059, // S4SUBL
2063, // CMPBGE
2066, // S8ADDL
2075, // S8SUBL
2077, // CMPULT
2080, // ADDQ
2082, // S4ADDQ
2089, // SUBQ
2091, // S4SUBQ
2093, // CMPEQ
2098, // S8ADDQ
2107, // S8SUBQ
2109, // CMPULE
2112, // ADDL/V
2121, // SUBL/V
2125, // CMPLT
2144, // ADDQ/V
2153, // SUBQ/V
2157, // CMPLE
2176, // AND
2184, // BIC
2196, // CMOVLBS
2198, // CMOVLBC
2208, // BIS
2212, // CMOVEQ
2214, // CMOVNE
2216, // ORNOT
2240, // XOR
2244, // CMOVLT
2246, // CMOVGE
2248, // EQV
2276, // CMOVLE
2278, // CMOVGT
2306, // MSKBL
2310, // EXTBL
2315, // INSBL
2322, // MSKWL
2326, // EXTWL
2331, // INSWL
2338, // MSKLL
2342, // EXTLL
2347, // INSLL
2352, // ZAP
2353, // ZAPNOT
2354, // MSKQL
2356, // SRL
2358, // EXTQL
2361, // SLL
2363, // INSQL
2364, // SRA
2386, // MSKWH
2391, // INSWH
2394, // EXTWH
2402, // MSKLH
2407, // INSLH
2410, // EXTLH
2418, // MSKQH
2423, // INSQH
2426, // EXTQH
2432, // MULL
2464, // MULQ
2480, // UMULH
2496, // MULL/V
2528 // MULQ/V
};

long long int zap (long long int a, unsigned char mask) {
    long long int result = 0;
    for (int i = 7; i >= 0; i--) {
        result += ((mask >> i) % 2) ? 0 : (a >> (i * 8)) % 256;
        if (i > 0) result = result << 8;
    }
    return result;
}

long long int ext_ins (int ext, long long int ra, long long int rb, int size, int high) {
    int byteloc;    
    int mask = 0;
    switch (size) {
        case 0: mask = 1; break;
        case 1: mask = 3; break;
        case 2: mask = 15; break;
        case 3: mask = 255; break;
    }
    int rbp = rb % 8;
    byteloc = rbp << 3;
    if (high) byteloc = 64 - byteloc;

    if (ext) {
        if (high) return zap(ra << byteloc, ~mask);
        else return zap(ra >> byteloc, ~mask);
    }
    else {
        mask = mask << rbp;
        if (high) return zap(ra >> byteloc, ~mask >> 8);
        else return zap(ra << byteloc, ~mask);
    }
    return 0;
}

long long int alu (long long int a , long long int b , int opcode) {
    int result = 0;
    switch (opcode) {
        case 1024: return a + b; // LDA
        case 1152: return (a << 16) + b; // LDAH
        case 1280: return a + b; // LDBU
        case 1408: return (a + b) & ~7; // LDQ_U
        case 1536: return a + b; // LDWU
        case 1664: return a + b; // STW
        case 1792: return a + b; // STB
        case 1920: return (a + b) & ~7; // STQ_U
        case 5120: return a + b; // LDL
        case 5248: return a + b; // LDQ
        case 5376: return a + b; // LDL_L
        case 5504: return a + b; // LDQ_L
        case 5632: return a + b; // STL
        case 5760: return a + b; // STQ
        case 5888: return a + b; // STL_C
        case 6016: return a + b; // STQ_C
        case 2048: return int(a) + int(b); // ADDL
        case 2050: return int(a << 2) + int(b); // S4ADDL
        case 2057: return int(a) - int(b); // SUBL
        case 2059: return int(a << 2) - int(b); // S4SUBL
        case 2063: {  // CMPBGE
            result = 0;
            for (int i = 7; i >= 0; i--) {
                result += ((a >> (i * 8)) % 256) >= ((b >> (i * 8)) % 256) ? 1 : 0;
                if (i > 0) result = result << 1;
            }
            return result;
        }
        case 2066: return int(a << 3) + int(b); // S8ADDL
        case 2075: return int(a << 3) - int(b); // S8SUBL
        case 2077: return (unsigned long long)(a) < (unsigned long long)(b); // CMPULT
        case 2080: return a + b; // ADDQ
        case 2082: return (a << 2) + b; // S4ADDQ
        case 2089: return a - b; // SUBQ
        case 2091: return (a << 2) - b; // S4SUBQ
        case 2093: return a == b; // CMPEQ
        case 2098: return (a << 3) + b; // S8ADDQ
        case 2107: return (a << 3) - b; // S8SUBQ
        case 2109: return (unsigned long long)(a) <= (unsigned long long)(b); // CMPULE
        case 2112: return int(a) + int(b); // ADDL/V
        case 2121: return int(a) - int(b); // SUBL/V
        case 2125: return a < b; // CMPLT
        case 2144: return a + b; // ADDQ/V
        case 2153: return a - b; // SUBQ/V
        case 2157: return a <= b; // CMPLE
        case 2176: return a & b; // AND
        case 2184: return a & (~b); // BIC
        case 2196: return a % 2; // CMOVLBS
        case 2198: return (a + 1) % 2; // CMOVLBC
        case 2208: return a | b; // BIS
        case 2212: return a == 0; // CMOVEQ
        case 2214: return a != 0; // CMOVNE
        case 2216: return a | (~b); // ORNOT
        case 2240: return a ^ b; // XOR
        case 2244: return a < 0; // CMOVLT
        case 2246: return a >= 0; // CMOVGE
        case 2248: return a ^ (~b); // EQV
        case 2276: return a <= 0; // CMOVLE
        case 2278: return a > 0; // CMOVGT
        case 2306: return zap(a, 1 << (b % 8)); // MSKBL
        case 2310: return ext_ins(1, a, b, 0, 0); // EXTBL
        case 2315: return ext_ins(0, a, b, 0, 0); // INSBL
        case 2322: return zap(a, 3 << (b % 8)); // MSKWL
        case 2326: return ext_ins(1, a, b, 1, 0); // EXTWL
        case 2331: return ext_ins(0, a, b, 1, 0); // INSWL
        case 2338: return zap(a, 15 << (b % 8)); // MSKLL
        case 2342: return ext_ins(1, a, b, 2, 0); // EXTLL
        case 2347: return ext_ins(0, a, b, 2, 0); // INSLL
        case 2352: return zap(a, b); // ZAP
        case 2353: return zap(a, ~b); // ZAPNOT
        case 2354: return zap(a, 255 << (b % 8)); // MSKQL
        case 2356: return (unsigned long long)(a) >> (b & 0x3f); // SRL
        case 2358: return ext_ins(1, a, b, 3, 0); // EXTQL
        case 2361: return a << (b & 0x3f); // SLL
        case 2363: return ext_ins(0, a, b, 3, 0); // INSQL
        case 2364: return a >> (b & 0x3f); // SRA
        case 2386: return zap(a, (3 << (b % 8)) >> 8); // MSKWH
        case 2391: return ext_ins(0, a, b, 1, 1); // INSWH
        case 2394: return ext_ins(1, a, b, 1, 1); // EXTWH
        case 2402: return zap(a, (15 << (b % 8)) >> 8); // MSKLH
        case 2407: return ext_ins(0, a, b, 2, 1); // INSLH
        case 2410: return ext_ins(1, a, b, 2, 1); // EXTLH
        case 2418: return zap(a, (255 << (b % 8)) >> 8); // MSKQH
        case 2423: return ext_ins(0, a, b, 3, 1); // INSQH
        case 2426: return ext_ins(1, a, b, 3, 1); // EXTQH
        case 2432: return int(a) * int(b); // MULL
        case 2464: return a * b; // MULQ
        case 2480: return ((unsigned __int128)(a) * (unsigned long long)(b)) >> 64; // UMULH
        case 2496: return int(a) * int(b); // MULL/V
        case 2528: return a * b; // MULQ/V
    }
}

vluint64_t main_time = 0;       // Current simulation time

double sc_time_stamp () {       // Called by $time in Verilog
    return main_time;           // converts to double, to match
                                // what SystemC does
}

int main(int argc, char** argv) {
    random_device rd;
    mt19937_64 eng(rd());
    uniform_int_distribution<long long> distr;
    
    Verilated::commandArgs(argc, argv);
    
    VIbox *top = new VIbox;
    
    bool fail_flag = false;
    int size = sizeof(opcode) / sizeof(int);
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < 100; j++) {
            long long int a, b, expected, result;
            a = distr(eng) % 100;
            b = distr(eng) % 100;
            expected = alu(a, b, opcode[i]);
            top->a = a;
            top->b = b;
            top->opcode = opcode[i];
            top->eval();            // Evaluate model
            result = top->result;
            if (result != expected) {
                fail_flag = true;
                cout << "test failed. opcode: " << opcode[i] << " a: " << a << " b: " << b <<
                " result: " << result << " expected: " << expected << endl;
                cout << "bloc : " << int(top->bloc) << endl;
                cout << "out1 : " << top->mei_out1 << " out2: " << int(top->mei_out2) << endl;
            }
            main_time++;            // Time passes...
        }
    }
   
    if (!fail_flag)
        cout << "All tests passed." << endl;
    
    top->final();
    delete top;
}
