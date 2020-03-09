from generate import *

STM_GLOBAL_STORAGE_START = 0x1000 # Need 2 global bytes for lock and version
GLOBAL_VERSION = STM_GLOBAL_STORAGE_START
GLOBAL_LOCK = STM_GLOBAL_STORAGE_START + 8

# TInit
TInit = CodeBlock('TInit')
TInit.STQ(R31, R31, GLOBAL_VERSION)
TInit.STQ(R31, R31, GLOBAL_LOCK)
TInit.MEXIT(0)
print(TInit.get())

# TStart
# Log struct must be allocated at least (2 + MAX_TRANSACTIONAL_WRITES * 2) words by application
TStart = CodeBlock('TStart (Input: Log address in R0)')
TStart.MWPCR(R1, R8, 0x0) # Backup R1 in Metal R8 (reserve Metal R0 to R7 for now)
TStart.LDQ(R1, R31, GLOBAL_VERSION)
TStart.STQ(R1, R0, 0) # read_version = GLOBAL_VERSION
TStart.STQ(R31, R0, 8) # write_count = 0
TStart.MRPCR(R1, R8, 0x0) # Restore backup
TStart.MEXIT(0)
print(TStart.get())

# TRead
TRead = CodeBlock('TRead (Input: Log in R0, Read Address in R1, Result in R2)')
TRead.MWPCR(R3, R8, 0x0) # Backup R3
TRead.MWPCR(R4, R9, 0x0) # Backup R4
TRead.MWPCR(R5, R10, 0x0) # Backup R5
TRead.MWPCR(R6, R11, 0x0) # Backup R6
TRead.LDQ(R2, R0, 8) # R2 = write_count
TRead.ADDQ(R31, R31, R3, 0, False) # R3 = 0 (write index)
# Loop start
TRead.CMPLT(R3, R2, R4, 0, False) # R4 = write_index < write_count
TRead.BEQ(R4, +9)
TRead.SLL(R3, 0, R4, 4, True)
TRead.ADDQ(R0, R4, R4, 0, False) # R4 = Log + write_index * 2 words
TRead.LDQ(R5, R4, 16) # R5 = Address in Write Log
TRead.CMPEQ(R5, R1, R6, 0, False) # R6 = entry address == read_address
TRead.BEQ(R6, +2)
# If Equal
TRead.LDQ(R2, R4, 24)
TRead.BR(R31, +3)
# End Equal
TRead.ADDQ(R3, 0, R3, 1, True)
TRead.BR(R31, -11)
# Loop End
TRead.LDQ(R2, R1, 0)
TRead.MRPCR(R3, R8, 0x0)
TRead.MRPCR(R4, R9, 0x0)
TRead.MRPCR(R5, R10, 0x0)
TRead.MRPCR(R6, R11, 0x0)
TRead.MEXIT(0)
print(TRead.get())

# TWrite
TWrite = CodeBlock('TWrite (Input: Log in R0, Write Address in R1, Write Data in R2)')
TWrite.MWPCR(R3, R8, 0x0) # Backup R3
TWrite.MWPCR(R4, R9, 0x0) # Backup R4
TWrite.MWPCR(R5, R10, 0x0) # Backup R5
TWrite.MWPCR(R6, R11, 0x0) # Backup R6
TWrite.MWPCR(R7, R12, 0x0) # Backup R7
TWrite.LDQ(R3, R0, 8) # R3 = write_count
TWrite.ADDQ(R31, R31, R4, 0, False) # R4 = 0 (write index)
# Loop start
TWrite.CMPLT(R4, R3, R5, 0, False) # R5 = write_index < write_count
TWrite.BEQ(R5, +9)
TWrite.SLL(R4, 0, R5, 4, True)
TWrite.ADDQ(R0, R5, R5, 0, False) # R5 = Log + write_index * 2 words
TWrite.LDQ(R6, R5, 16) # R6 = Address in Write Log
TWrite.CMPEQ(R6, R1, R7, 0, False) # R7 = entry address == read_address
TWrite.BEQ(R7, +2)
# If Equal
TWrite.STQ(R2, R5, 24)
TWrite.BR(R31, +8)
# End Equal
TWrite.ADDQ(R4, 0, R4, 1, True)
TWrite.BR(R31, -11)
# Loop End
TWrite.SLL(R3, 0, R4, 4, True)
TWrite.ADDQ(R0, R4, R4, 0, False)
TWrite.STQ(R1, R4, 16)
TWrite.STQ(R2, R4, 24)
TWrite.ADDQ(R3, 0, R3, 1, True)
TWrite.STQ(R3, R0, 8)
TWrite.MRPCR(R3, R8, 0x0)
TWrite.MRPCR(R4, R9, 0x0)
TWrite.MRPCR(R5, R10, 0x0)
TWrite.MRPCR(R6, R11, 0x0)
TWrite.MRPCR(R7, R12, 0x0)
TWrite.MEXIT(0)
print(TWrite.get())

# New_val should not be zero (Result = was_successful)
def compare_and_swap(code, addr, old_val_lit, new_val_lit, result_reg, temp_reg):
    code.LDQ_L(result_reg, R31, addr) # Temp0 (Result) = Read Val
    code.CMPEQ(result_reg, 0, temp_reg, old_val_lit, True) # Temp1 (temp) = Read Val == Expected
    code.BNE(temp_reg, +2) # Compare Successful -> +2
    code.ADDQ(R31, 0, result_reg, 0, True)
    code.BR(R31, +2)
    code.ADDQ(R31, 0, result_reg, new_val_lit, True) # Temp0 (Result) = New Val
    code.STQ_C(result_reg, R31, addr) # Result will be 0 if not successful

# TCommit
TCommit = CodeBlock('TCommit (Input: Log in R0, Result in R1)')
TCommit.MWPCR(R2, R8, 0x0) # Backup R2
TCommit.MWPCR(R3, R9, 0x0) # Backup R3
TCommit.MWPCR(R4, R10, 0x0) # Backup R4
TCommit.MWPCR(R5, R11, 0x0) # Backup R5
TCommit.MWPCR(R6, R12, 0x0) # Backup R6
compare_and_swap(TCommit, GLOBAL_LOCK, 0, 1, R1, R2)
TCommit.BEQ(R1, +20) # Exit
#Lock Taken
TCommit.LDQ(R2, R31, GLOBAL_VERSION) # R2 = current verion
TCommit.LDQ(R3, R0, 0) # R3 = expected version
TCommit.CMPEQ(R2, R3, R1, 0, False)
TCommit.BEQ(R1, +15) # Exit and Release Lock
# Start Updates
TCommit.LDQ(R2, R0, 8) # R2 = write_count
TCommit.BEQ(R2, +13) # Exit and Release Lock (with success) if no writes
TCommit.ADDQ(R31, R31, R3, 0, False) # R3 = 0 (write index)
# Loop start
TCommit.CMPLT(R3, R2, R4, 0, False) # R4 = write_index < write_count
TCommit.BEQ(R4, +7) # Break Loop
TCommit.SLL(R3, 0, R4, 4, True)
TCommit.ADDQ(R0, R4, R4, 0, False) # R4 = Log + write_index * 2 words
TCommit.LDQ(R5, R4, 16) # R5 = Write Address
TCommit.LDQ(R6, R4, 24) # R6 = Write Data
TCommit.STQ(R6, R5, 0) # Store R6 in *R5
TCommit.ADDQ(R3, 0, R3, 1, True)
TCommit.BR(R31, -9)
# Loop End
# Increase Version
TCommit.LDQ(R2, R31, GLOBAL_VERSION)
TCommit.ADDQ(R2, 0, R2, 1, True)
TCommit.STQ(R2, R31, GLOBAL_VERSION)
# Unlock
TCommit.STQ(R31, R31, GLOBAL_LOCK)
# Exit
TCommit.MRPCR(R2, R8, 0x0)
TCommit.MRPCR(R3, R9, 0x0)
TCommit.MRPCR(R4, R10, 0x0)
TCommit.MRPCR(R5, R11, 0x0)
TCommit.MRPCR(R6, R12, 0x0)
TCommit.MEXIT(0)
print(TCommit.get())
