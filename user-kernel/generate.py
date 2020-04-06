# Enum Declaration
for i in range(32):
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
}

class CodeBlock:
    def __init__(self, name):
        self.name = name
        self.asm = []
        self.binary = []

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

    def OIF(self, op, ra, rb, rc, literal, lit):
        opcode = meta[op]['code']
        func = meta[op]['func']
        if lit:
            self.binary.append(opcode << 26 | ra << 21 | self.twos_comp(literal, 8) << 13 | 1 << 12 | func << 5 | rc)
            self.asm.append('%s R%d, #%s, R%d' % (op, ra, hex(literal), rc))
        else:
            self.binary.append(opcode << 26 | ra << 21 | rb << 16 | func << 5 | rc)
            self.asm.append('%s R%d, R%d, R%d' % (op, ra, rb, rc))

    def PIF(self, op, disp):
        opcode = meta[op]['code']
        self.binary.append(opcode << 26 | disp)
        self.asm.append('%s %s' % (op, hex(disp)))

    def __getattr__(self, name):
        op = name.upper()
        op_format = meta[op]['format']
        return lambda *args: getattr(self, op_format)(op, *args)

    def get(self):
        result = '// %s\n' % self.name
        for bin_code, asm_code in zip(self.binary, self.asm):
            result += '%s // %s\n' % (hex(bin_code)[2:].zfill(8), asm_code)
        return result

if __name__ == '__main__':
    code = CodeBlock('Fibonacci')
    code.ADDQ(R31, 0, R0, 10, True)
    code.ADDQ(R31, 0, R1, 0, True)
    code.ADDQ(R31, 0, R2, 1, True)
    code.ADDQ(R31, 0, R3, 0, True)
    code.SUBQ(R3, R0, R4, 0, False)
    code.BEQ(R4, +5)
    code.ADDQ(R1, R2, R4, 0, False)
    code.ADDQ(R31, R2, R1, 0, False)
    code.ADDQ(R31, R4, R2, 0, False)
    code.ADDQ(R3, 0, R3, 1, True)
    code.BR(R31, -7)
    code.STQ(R1, R31, 0)
    print(code.get())
