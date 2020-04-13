from generate import *

# R1 - R8 : temporary registers
# R9 - R14 : saved registers
# R16 - R21 : argument registers
# R26 : return address
# R27 : return value

# Metal:
# R0 - R7 : reserved
# R8 - R16 : saved
# R0 : privilege mode
# R1 : secret register
# R6 : exception return address
# R7 : Mexit address

imem = open('instruction.mem', 'w')
dmem = open('data.mem', 'w')
mmem = open('metal.mem', 'w')

####### user code: 
user = CodeBlock('User')
user.ADDQ(R31, R31, R16, 0, False)
user.MENTER(0) # reset_ctr
user.ADDQ(R31, 0, R16, 1, True)
user.MENTER(0) # inc_ctr
user.ADDQ(R31, 0, R16, 1, True)
user.MENTER(0) # inc_ctr
user.ADDQ(R31, 0, R16, 2, True)
user.MENTER(0) # read_ctr
user.BR(R0, -1)
print(user.get(), file = imem)

####### syscalls code:
reset = CodeBlock('reset_ctr()') # address 0x80
reset.ADDQ(R31, R31, R16, 0, False)
reset.MENTER(2) # write_secret
reset.RET(R26, R26, 0)

inc = CodeBlock('inc_ctr()') # address 0x8c
inc.MENTER(1) # read_secret
inc.ADDQ(R27, 0, R16, 1, True)
inc.MENTER(2) # write secret
inc.RET(R26, R26, 0)

read = CodeBlock('read_ctr() (Output: R27)') # address 0x9c
read.MENTER(1) # read_secret
read.RET(R26, R26, 0)

print('\n@20\n', file = imem) # start address for syscalls (/4 because of readmemh format)
print(reset.get(), file = imem)
print(inc.get(), file = imem)
print(read.get(), file = imem)


####### Metal code:
metal = CodeBlock('Subroutine Addresses') # Metal address 0x0
metal.BR(R0, 0X1f) # 32 - 1
metal.BR(R0, 0X2b) # 45 - 2
metal.BR(R0, 0X2e) # 49 - 3

print (metal.get(), file = mmem)
print ('\n@20\n', file = mmem)

syscall = CodeBlock('syscall (Input: R16)') # Metal address 32 * 4
syscall.MRPCR(R2, MR0, 0) # backup mode reg (Metal register 0) 
syscall.ADDQ(R31, 0, R1, 1, True)
syscall.MWPCR(R1, MR0, 0) # set to kernel mode
syscall.AND(R16, 0, R1, 0X1f, True) # syscall number range
syscall.SLL(R1, 0, R1, 3, True)
syscall.LDQ(R1, R1, 0) # read syscall table (located in address 0)
syscall.MRPCR(R3, MR7, 0) # backup saved pc for Mexit
syscall.MWPCR(R3, MR8, 0)
syscall.JSR(R26, R1, 0) # jump to syscall
syscall.MRPCR(R3, MR8, 0) # restore saved pc
syscall.MWPCR(R3, MR7, 0)
syscall.MWPCR(R2, MR0, 0) # restore mode reg
syscall.MEXIT(0)

# Metal R1 is the secret register
read_secret = CodeBlock('read_secret (Output: R27)') # Metal address 45 * 4
read_secret.MRPCR(R1, MR0, 0)
read_secret.BEQ(R1, 1) # check kernel mode
read_secret.MRPCR(R27, MR1, 0)
read_secret.MEXIT(0)

write_secret = CodeBlock('write_secret (Input: R16)') # Metal address 49 * 4
write_secret.MRPCR(R1, MR0, 0)
write_secret.BEQ(R1, 1) # check kernel mode
write_secret.MWPCR(R16, MR1, 0)
write_secret.MEXIT(0)

print(syscall.get(), file = mmem)
print(read_secret.get(), file = mmem)
print(write_secret.get(), file = mmem)

print('80\n8c\n9c\n', file = dmem)



