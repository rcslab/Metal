from generate import *

# R1 - R8 : temporary registers
# R9 - R14 : saved registers
# R16 - R21 : argument registers
# R26 : return address
# R27 : return value

# Metal:
# MR0 : privilege mode
# MR1 : secret register
# MR14 : exception return address
# MR15 : metal return address

imem = open('instruction.mem', 'w')
dmem = open('data.mem', 'w')
mmem = open('metal.mem', 'w')

####### user code: 
user = CodeBlock('User')
user.ADDQ(R31, R31, R16)
user.MENTER(0) # reset_ctr
user.ADDQ(R31, 1, R16, True)
user.MENTER(0) # inc_ctr
user.ADDQ(R31, 1, R16, True)
user.MENTER(0) # inc_ctr
user.ADDQ(R31, 2, R16, True)
user.MENTER(0) # read_ctr
user.ICEEX()
user.BR(R0, -1)
print(user.get(), file = imem)

####### syscalls code:
reset = CodeBlock('reset_ctr()') # address 0x80
reset.ADDQ(R31, R26, R9) # save the return address (we can't protect it without stack)
reset.ADDQ(R31, R31, R16)
reset.MENTER(3) # write_secret
reset.ADDQ(R31, R9, R26) # restore return address
reset.MENTER(1) # sys_return

inc = CodeBlock('inc_ctr()') # address 0x94
inc.ADDQ(R31, R26, R9) # save return address
inc.MENTER(2) # read_secret
inc.ADDQ(R27, 1, R16, True)
inc.MENTER(3) # write_secret
inc.ADDQ(R31, R9, R26)
inc.MENTER(1) # sys_return


read = CodeBlock('read_ctr() (Output: R27)') # address 0xac
read.ADDQ(R31, R26, R9) # save return address
read.MENTER(2) # read_secret
read.ADDQ(R31, R9, R26)
read.MENTER(1) # sys_return

print('\n@80\n', file = imem) # start address for syscalls
print(reset.get(), file = imem)
print(inc.get(), file = imem)
print(read.get(), file = imem)


####### Metal code:
metal = CodeBlock('Subroutine Addresses') # Metal address 0x0
metal.BR(R0, 0X3f) # (64 - 1) 1-syscall
metal.BR(R0, 0X45) # (71 - 2) 2-sys_return
metal.BR(R0, 0X48) # (75 - 3) 3-read_secret
metal.BR(R0, 0X4b) # (79 - 4) 3-write_secret

print (metal.get(), file = mmem)
print ('\n@100\n', file = mmem)

syscall = CodeBlock('syscall (Input: R16)') # Metal address 64 * 4
syscall.MWPCR(R31, MR0, 0) # set to kernel mode
syscall.AND(R16, 0x3f, R1, True) # syscall number range
syscall.SLL(R1, 3, R1, True)
syscall.LDQ(R1, R1, 0) # read syscall table (located in address 0 of data memory)
syscall.MRPCR(R26, MR15, 0) # pass the saved pc to the kernel code
syscall.MWPCR(R1, MR15, 0)
syscall.MEXIT(0) # jump to kernel code

sys_return = CodeBlock('sys_return (Return Address: R26)') # Metal address 71 * 4
sys_return.ADDQ(R31, 1, R1, True)
sys_return.MWPCR(R1, MR0, 0) # set to user mode
sys_return.MWPCR(R26, MR15, 0)
sys_return.MEXIT(0) # return to user code

# Metal R1 is the secret register
read_secret = CodeBlock('read_secret (Output: R27)') # Metal address 75 * 4
read_secret.MRPCR(R1, MR0, 0)
read_secret.BNE(R1, 1) # check kernel mode
read_secret.MRPCR(R27, MR1, 0)
read_secret.MEXIT(0)

write_secret = CodeBlock('write_secret (Input: R16)') # Metal address 79 * 4
write_secret.MRPCR(R1, MR0, 0)
write_secret.BNE(R1, 1) # check kernel mode
write_secret.MWPCR(R16, MR1, 0)
write_secret.MEXIT(0)

print(syscall.get(), file = mmem)
print(sys_return.get(), file = mmem)
print(read_secret.get(), file = mmem)
print(write_secret.get(), file = mmem)

print('@7 80\n@f 94\n@17 ac\n', file = dmem)



