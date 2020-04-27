from generate import *

# R1 - R8 : temporary registers
# R9 - R14 : saved registers
# R16 - R21 : argument registers
# R26 : return address
# R27 : return value

STM_GLOBAL_STORAGE_START = 0x1000 # Need 2 global bytes for lock and version
GLOBAL_VERSION = STM_GLOBAL_STORAGE_START
GLOBAL_LOCK = STM_GLOBAL_STORAGE_START + 8

# Metal Table:
Metal = CodeBlock('Metal_table')
Metal.BR(R0, 0) # 0
Metal.BR(R0, 0) # 1
Metal.BR(R0, 0) # 2
Metal.BR(R0, 0) # 3
Metal.BR(R0, 'TInit')   # 4
Metal.BR(R0, 'TStart')  # 5
Metal.BR(R0, 'TRead')   # 6
Metal.BR(R0, 'TWrite')  # 7
Metal.BR(R0, 'TCommit') # 8


# TInit
TInit = CodeBlock('TInit')
TInit.STQ(R31, R31, GLOBAL_VERSION)
TInit.STQ(R31, R31, GLOBAL_LOCK)
TInit.MEXIT(0)

# TStart
# Log struct must be allocated at least (2 + MAX_TRANSACTIONAL_WRITES * 2) words by application
TStart = CodeBlock('TStart') # Input: Log address in R16
TStart.LDQ(R1, R31, GLOBAL_VERSION)
TStart.STQ(R1, R16, 0) # read_version = GLOBAL_VERSION
TStart.STQ(R31, R16, 8) # write_count = 0
TStart.MEXIT(0)

# TRead
TRead = CodeBlock('TRead') # Input: Log in R16, Read Address in R17, Result in R27
TRead.LDQ(R27, R16, 8) # R27 = write_count
TRead.ADDQ(R31, R31, R3) # R3 = 0 (write index)

TRead.label('tr_loop_start')
TRead.CMPLT(R3, R27, R4) # R4 = write_index < write_count
TRead.BEQ(R4, 'tr_loop_end')
TRead.SLL(R3, 4, R4, True)
TRead.ADDQ(R16, R4, R4) # R4 = Log + write_index * 2 words
TRead.LDQ(R5, R4, 16) # R5 = Address in Write Log
TRead.CMPEQ(R5, R17, R6) # R6 = entry address == read_address
TRead.BEQ(R6, 'tr_end_equal')

TRead.label('tr_if_equal')
TRead.LDQ(R27, R4, 24)
TRead.BR(R31, 'tr_loop_end')

TRead.label('tr_end_equal')
TRead.ADDQ(R3, 1, R3, True)
TRead.BR(R31, 'tr_loop_start')

TRead.label('tr_loop_end')
TRead.LDQ(R27, R17, 0)
TRead.MEXIT(0)

# TWrite
TWrite = CodeBlock('TWrite') # Input: Log in R16, Write Address in R17, Write Data in R18
TWrite.LDQ(R3, R16, 8) # R3 = write_count
TWrite.ADDQ(R31, R31, R4) # R4 = 0 (write index)
# Loop start
TWrite.label('tw_loop_start')
TWrite.CMPLT(R4, R3, R5) # R5 = write_index < write_count
TWrite.BEQ(R5, 'tw_loop_end')
TWrite.SLL(R4, 4, R5, True)
TWrite.ADDQ(R16, R5, R5) # R5 = Log + write_index * 2 words
TWrite.LDQ(R6, R5, 16) # R6 = Address in Write Log
TWrite.CMPEQ(R6, R17, R7) # R7 = entry address == read_address
TWrite.BEQ(R7, 'tw_end_equal')
# If Equal
TWrite.label('tw_if_equal')
TWrite.STQ(R18, R5, 24)
TWrite.BR(R31, 'tw_exit')
# End Equal
TWrite.label('tw_end_equal')
TWrite.ADDQ(R4, 1, R4, True)
TWrite.BR(R31, 'tw_loop_start')
# Loop End
TWrite.label('tw_loop_end')
TWrite.SLL(R3, 4, R4, True)
TWrite.ADDQ(R16, R4, R4)
TWrite.STQ(R17, R4, 16)
TWrite.STQ(R18, R4, 24)
TWrite.ADDQ(R3, 1, R3, True)
TWrite.STQ(R3, R16, 8)
TWrite.label('tw_exit')
TWrite.MEXIT(0)

# New_val should not be zero (Result = was_successful)
def compare_and_swap(code, addr, old_val_lit, new_val_lit, result_reg, temp_reg):
    code.LDQ_L(result_reg, R31, addr) # Temp0 (Result) = Read Val
    code.CMPEQ(result_reg,  old_val_lit, temp_reg, True) # Temp1 (temp) = Read Val == Expected
    code.BNE(temp_reg, +2) # Compare Successful -> +2
    code.ADDQ(R31, 0, result_reg, True)
    code.BR(R31, +2)
    code.ADDQ(R31, new_val_lit, result_reg, True) # Temp0 (Result) = New Val
    code.STQ_C(result_reg, R31, addr) # Result will be 0 if not successful

# TCommit
TCommit = CodeBlock('TCommit') # Input: Log in R16, Result in R27
compare_and_swap(TCommit, GLOBAL_LOCK, 0, 1, R27, R2)
TCommit.BEQ(R27, 'tc_exit') # Exit
#Lock Taken
TCommit.LDQ(R2, R31, GLOBAL_VERSION) # R2 = current verion
TCommit.LDQ(R3, R16, 0) # R3 = expected version
TCommit.CMPEQ(R2, R3, R27)
TCommit.BEQ(R27, 'tc_release') # Exit and Release Lock
# Start Updates
TCommit.LDQ(R2, R16, 8) # R2 = write_count
TCommit.BEQ(R2, 'tc_release') # Exit and Release Lock (with success) if no writes
TCommit.ADDQ(R31, R31, R3) # R3 = 0 (write index)
# Loop start
TCommit.label('tc_loop_start')
TCommit.CMPLT(R3, R2, R4) # R4 = write_index < write_count
TCommit.BEQ(R4, 'tc_loop_end') # Break Loop
TCommit.SLL(R3, 4, R4, True)
TCommit.ADDQ(R16, R4, R4) # R4 = Log + write_index * 2 words
TCommit.LDQ(R5, R4, 16) # R5 = Write Address
TCommit.LDQ(R6, R4, 24) # R6 = Write Data
TCommit.STQ(R6, R5, 0) # Store R6 in *R5
TCommit.ADDQ(R3, 1, R3, True)
TCommit.BR(R31, 'tc_loop_start')
# Loop End
# Increase Version
TCommit.label('tc_loop_end')
TCommit.LDQ(R2, R31, GLOBAL_VERSION)
TCommit.ADDQ(R2, 1, R2, True)
TCommit.STQ(R2, R31, GLOBAL_VERSION)
# Unlock
TCommit.label('tc_release')
TCommit.STQ(R31, R31, GLOBAL_LOCK)
# Exit
TCommit.label('tc_exit')
TCommit.MEXIT(0)

m_linker = Linker()
m_linker.add(Metal, 0)
m_linker.add(TInit, 0x100)
m_linker.add(TStart)
m_linker.add(TRead)
m_linker.add(TWrite)
m_linker.add(TCommit)

MMem = open('metal.mem', 'w')
print(m_linker.link(), file = MMem)
