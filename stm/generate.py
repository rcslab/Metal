# Enum Declaration
for i in range(32):
    exec('MR%d = %d' % (i, i))
    exec('R%d = %d' % (i, i))

meta = {
    'LDA': {'code': 0x08, 'format': 'MIF'},
    'LDAH': {'code': 0x09, 'format': 'MIF'},
    'LDBU': {'code': 0x0A, 'format': 'MIF'},
    'LDQ_U': {'code': 0x0B, 'format': 'MIF'},
    'LDWU': {'code': 0x0C, 'format': 'MIF'},
    'STW': {'code': 0x0D, 'format': 'MIF'},
    'STB': {'code': 0x0E, 'format': 'MIF'},
    'STQ_U': {'code': 0x0F, 'format': 'MIF'},
    'LDL': {'code': 0x28, 'format': 'MIF'},
    'LDQ': {'code': 0x29, 'format': 'MIF'},
    'LDL_L': {'code': 0x2A, 'format': 'MIF'},
    'LDQ_L': {'code': 0x2B, 'format': 'MIF'},
    'STL': {'code': 0x2C, 'format': 'MIF'},
    'STQ': {'code': 0x2D, 'format': 'MIF'},
    'STL_C': {'code': 0x2E, 'format': 'MIF'},
    'STQ_C': {'code': 0x2F, 'format': 'MIF'},

    'ADDL': {'code': 0x10, 'format': 'OIF', 'func': 0x00},
    'S4ADDL': {'code': 0x10, 'format': 'OIF', 'func': 0x02},
    'SUBL': {'code': 0x10, 'format': 'OIF', 'func': 0x09},
    'S4SUBL': {'code': 0x10, 'format': 'OIF', 'func': 0x0B},
    'CMPBGE': {'code': 0x10, 'format': 'OIF', 'func': 0x0F},
    'S8ADDL': {'code': 0x10, 'format': 'OIF', 'func': 0x12},
    'S8SUBL': {'code': 0x10, 'format': 'OIF', 'func': 0x1B},
    'CMPULT': {'code': 0x10, 'format': 'OIF', 'func': 0x1D},
    'ADDQ': {'code': 0x10, 'format': 'OIF', 'func': 0x20},
    'S4ADDQ': {'code': 0x10, 'format': 'OIF', 'func': 0x22},
    'SUBQ': {'code': 0x10, 'format': 'OIF', 'func': 0x29},
    'S4SUBQ': {'code': 0x10, 'format': 'OIF', 'func': 0x2B},
    'CMPEQ': {'code': 0x10, 'format': 'OIF', 'func': 0x2D},
    'S8ADDQ': {'code': 0x10, 'format': 'OIF', 'func': 0x32},
    'S8SUBQ': {'code': 0x10, 'format': 'OIF', 'func': 0x3B},
    'CMPULE': {'code': 0x10, 'format': 'OIF', 'func': 0x3D},
    'ADDL/V': {'code': 0x10, 'format': 'OIF', 'func': 0x40},
    'SUBL/V': {'code': 0x10, 'format': 'OIF', 'func': 0x49},
    'CMPLT': {'code': 0x10, 'format': 'OIF', 'func': 0x4D},
    'ADDQ/V': {'code': 0x10, 'format': 'OIF', 'func': 0x60},
    'SUBQ/V': {'code': 0x10, 'format': 'OIF', 'func': 0x69},
    'CMPLE': {'code': 0x10, 'format': 'OIF', 'func': 0x6D},

    'AND': {'code': 0x11, 'format': 'OIF', 'func': 0x00},
    'BIC': {'code': 0x11, 'format': 'OIF', 'func': 0x08},
    'CMOVLBS': {'code': 0x11, 'format': 'OIF', 'func': 0x14},
    'CMOVLBC': {'code': 0x11, 'format': 'OIF', 'func': 0x16},
    'BIS': {'code': 0x11, 'format': 'OIF', 'func': 0x20},
    'CMOVEQ': {'code': 0x11, 'format': 'OIF', 'func': 0x24},
    'CMOVNE': {'code': 0x11, 'format': 'OIF', 'func': 0x26},
    'ORNOT': {'code': 0x11, 'format': 'OIF', 'func': 0x28},
    'XOR': {'code': 0x11, 'format': 'OIF', 'func': 0x40},
    'CMOVLT': {'code': 0x11, 'format': 'OIF', 'func': 0x44},
    'CMOVGE': {'code': 0x11, 'format': 'OIF', 'func': 0x46},
    'EQV': {'code': 0x11, 'format': 'OIF', 'func': 0x48},
    'CMOVLE': {'code': 0x11, 'format': 'OIF', 'func': 0x64},
    'CMOVGT': {'code': 0x11, 'format': 'OIF', 'func': 0x66},

    'MSKBL': {'code': 0x12, 'format': 'OIF', 'func': 0x02},
    'EXTBL': {'code': 0x12, 'format': 'OIF', 'func': 0x06},
    'INSBL': {'code': 0x12, 'format': 'OIF', 'func': 0x0B},
    'MSKWL': {'code': 0x12, 'format': 'OIF', 'func': 0x12},
    'EXTWL': {'code': 0x12, 'format': 'OIF', 'func': 0x16},
    'INSWL': {'code': 0x12, 'format': 'OIF', 'func': 0x1B},
    'MSKLL': {'code': 0x12, 'format': 'OIF', 'func': 0x22},
    'EXTLL': {'code': 0x12, 'format': 'OIF', 'func': 0x26},
    'INSLL': {'code': 0x12, 'format': 'OIF', 'func': 0x2B},
    'ZAP': {'code': 0x12, 'format': 'OIF', 'func': 0x30},
    'ZAPNOT': {'code': 0x12, 'format': 'OIF', 'func': 0x31},
    'MSKQL': {'code': 0x12, 'format': 'OIF', 'func': 0x32},
    'SRL': {'code': 0x12, 'format': 'OIF', 'func': 0x34},
    'EXTQL': {'code': 0x12, 'format': 'OIF', 'func': 0x36},
    'SLL': {'code': 0x12, 'format': 'OIF', 'func': 0x39},
    'INSQL': {'code': 0x12, 'format': 'OIF', 'func': 0x3B},
    'SRA': {'code': 0x12, 'format': 'OIF', 'func': 0x3C},
    'MSKWH': {'code': 0x12, 'format': 'OIF', 'func': 0x52},
    'INSWH': {'code': 0x12, 'format': 'OIF', 'func': 0x57},
    'EXTWH': {'code': 0x12, 'format': 'OIF', 'func': 0x5A},
    'MSKLH': {'code': 0x12, 'format': 'OIF', 'func': 0x62},
    'INSLH': {'code': 0x12, 'format': 'OIF', 'func': 0x67},
    'EXTLH': {'code': 0x12, 'format': 'OIF', 'func': 0x6A},
    'MSKQH': {'code': 0x12, 'format': 'OIF', 'func': 0x72},
    'INSQH': {'code': 0x12, 'format': 'OIF', 'func': 0x77},
    'EXTQH': {'code': 0x12, 'format': 'OIF', 'func': 0x7A},

    'MULL': {'code': 0x13, 'format': 'OIF', 'func': 0x00},
    'MULQ': {'code': 0x13, 'format': 'OIF', 'func': 0x20},
    'UMULH': {'code': 0x13, 'format': 'OIF', 'func': 0x30},
    'MULL/V': {'code': 0x13, 'format': 'OIF', 'func': 0x40},
    'MULQ/V': {'code': 0x13, 'format': 'OIF', 'func': 0x60},

    'SEXTB': {'code': 0x1C, 'format': 'OIF', 'func': 0x00},
    'SEXTW': {'code': 0x1C, 'format': 'OIF', 'func': 0x01},

    'CTPOP': {'code': 0x1C, 'format': 'OIF', 'func': 0x30},
    'PERR': {'code': 0x1C, 'format': 'OIF', 'func': 0x31},
    'CTLZ': {'code': 0x1C, 'format': 'OIF', 'func': 0x32},
    'CTTZ': {'code': 0x1C, 'format': 'OIF', 'func': 0x33},
    'UNPKBW': {'code': 0x1C, 'format': 'OIF', 'func': 0x34},
    'UNPKBL': {'code': 0x1C, 'format': 'OIF', 'func': 0x35},
    'PKWB': {'code': 0x1C, 'format': 'OIF', 'func': 0x36},
    'PKLB': {'code': 0x1C, 'format': 'OIF', 'func': 0x37},
    'MINSB8': {'code': 0x1C, 'format': 'OIF', 'func': 0x38},
    'MINSW4': {'code': 0x1C, 'format': 'OIF', 'func': 0x39},
    'MINSUB8': {'code': 0x1C, 'format': 'OIF', 'func': 0x3A},
    'MINSUW4': {'code': 0x1C, 'format': 'OIF', 'func': 0x3B},
    'MAXUB8': {'code': 0x1C, 'format': 'OIF', 'func': 0x3C},
    'MAXUW4': {'code': 0x1C, 'format': 'OIF', 'func': 0x3D},
    'MAXSB8': {'code': 0x1C, 'format': 'OIF', 'func': 0x3E},
    'MAXSW4': {'code': 0x1C, 'format': 'OIF', 'func': 0x3F},

    'JMP': {'code': 0x1A, 'format': 'MIF'},
    'JSR': {'code': 0x1A, 'format': 'MIF'},
    'RET': {'code': 0x1A, 'format': 'MIF'},
    'JSR_COROUTINE': {'code': 0x1A, 'format': 'MIF'},

    'BR': {'code': 0x30, 'format': 'BIF'},
    'BSR': {'code': 0x34, 'format': 'BIF'},
    'BLBC': {'code': 0x38, 'format': 'BIF'},
    'BEQ': {'code': 0x39, 'format': 'BIF'},
    'BLT': {'code': 0x3A, 'format': 'BIF'},
    'BLE': {'code': 0x3B, 'format': 'BIF'},
    'BLBS': {'code': 0x3C, 'format': 'BIF'},
    'BNE': {'code': 0x3D, 'format': 'BIF'},
    'BGE': {'code': 0x3E, 'format': 'BIF'},
    'BGT': {'code': 0x3F, 'format': 'BIF'},

    'MENTER': {'code': 0x19, 'format': 'PIF'},
    'MEXIT': {'code': 0x1B, 'format': 'PIF'},
    'MRPCR': {'code': 0x1D, 'format': 'MIF'},
    'MWPCR': {'code': 0x1E, 'format': 'MIF'},

    'ICEBP': {'code': 0x06, 'format': 'ICE'},
    'ICEEX': {'code': 0x07, 'format': 'ICE'},
}

class CodeBlock:
    def __init__(self, name):
        self.name = name
        self.pre_link = []
        self.asm = []
        self.binary = []
        self.labels = {}
        self.labels[name] = 0

    def twos_comp(self, num, bits):
        return num + (1 << bits) if num < 0 else num

    def MIF(self, op, ra, rb, disp):
        opcode = meta[op]['code']
        self.binary.append(opcode << 26 | ra << 21 | rb << 16 | self.twos_comp(disp, 16))
        self.asm.append('%s R%d, %s(R%d)' % (op, ra, hex(disp), rb))

    def BIF(self, op, ra, disp):
        opcode = meta[op]['code']
        self.binary.append(opcode << 26 | ra << 21 | self.twos_comp(disp, 21))
        self.asm.append('%s R%d, %s' % (op, ra, hex(disp)))

    def OIF(self, op, ra, rb, rc, lit = False):
        opcode = meta[op]['code']
        func = meta[op]['func']
        if lit:
            self.binary.append(opcode << 26 | ra << 21 | self.twos_comp(rb, 8) << 13 | 1 << 12 | func << 5 | rc)
            self.asm.append('%s R%d, #%s, R%d' % (op, ra, hex(rb), rc))
        else:
            self.binary.append(opcode << 26 | ra << 21 | rb << 16 | func << 5 | rc)
            self.asm.append('%s R%d, R%d, R%d' % (op, ra, rb, rc))

    def PIF(self, op, disp):
        opcode = meta[op]['code']
        self.binary.append(opcode << 26 | disp)
        self.asm.append('%s %s' % (op, hex(disp)))

    def ICE(self, op):
        opcode = meta[op]['code']
        self.binary.append(opcode << 26)
        self.asm.append('%s' % (op))

    def label(self, label):
        self.labels[label] = len(self.pre_link) * 4

    def __getattr__(self, name):
        op = name.upper()
        return lambda *args: self.pre_link.append((op, list(args)))

    def resolve(self, labels, start):
        for op, args in self.pre_link:
            op_format = meta[op]['format']
            for i in range(len(args)):
                if isinstance(args[i], str):
                    if op_format == 'BIF':
                        args[i] = labels[args[i]] // 4 - (start // 4 + len(self.asm)) - 1
                    else:
                        args[i] = labels[args[i]]
            getattr(self, op_format)(op, *args)

    def get(self):
        result = '// %s\n' % self.name
        for bin_code, asm_code in zip(self.binary, self.asm):
            instr = hex(bin_code)[2:].zfill(8)
            instr = ' '.join([instr[i:i+2] for i in range(0, len(instr), 2)])
            result += '%s // %s\n' % (instr, asm_code)
        return result

class Linker:
    def __init__(self):
        self.blocks = []
        self.cur_addr = 0

    def add(self, block, start=None):
        if start is None:
            start = self.cur_addr
        self.blocks.append((start, block))
        self.cur_addr = start + len(block.pre_link) * 4

    def link(self):
        self.blocks.sort()
        labels = {}
        for start, block in self.blocks:
            for label in block.labels:
                labels[label] = start + block.labels[label]
        for start, block in self.blocks:
            block.resolve(labels, start)
        memory = ''
        addr = 0
        idx = 0
        while idx < len(self.blocks):
            if addr == self.blocks[idx][0]:
                memory += self.blocks[idx][1].get()
                addr += len(self.blocks[idx][1].asm) * 4
                idx += 1
            else: 
                for _ in range((self.blocks[idx][0] - addr) // 4):
                    memory += '00 00 00 00 // Padding\n'
                addr = self.blocks[idx][0]
        return memory

if __name__ == '__main__':
    code = CodeBlock('Fibonacci')
    code.ADDQ(R31, 10, R0, True)
    code.ADDQ(R31, 0, R1, True)
    code.ADDQ(R31, 1, R2, True)
    code.ADDQ(R31, 0, R3, True)
    code.label('loop_start')
    code.SUBQ(R3, R0, R4)
    code.BEQ(R4, 'loop_end')
    code.ADDQ(R1, R2, R4)
    code.ADDQ(R31, R2, R1)
    code.ADDQ(R31, R4, R2)
    code.ADDQ(R3, 1, R3, True)
    code.BR(R31, 'loop_start')
    code.label('loop_end')
    code.STQ(R1, R31, 0)
    linker = Linker()
    linker.add(code)
    print(linker.link())

