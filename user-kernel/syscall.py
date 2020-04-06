from generate import *

imem = open('instruction.mem', 'w')
dmem = open('data.mem', 'w')
mmem = open('metal.mem', 'w')

####### user code: 
user = CodeBlock('User')
user.ADDQ(R31, R31, R1, 0, False)
user.MENTER(0) # reset_ctr
user.ADDQ(R31, 0, R1, 1, True)
user.MENTER(0) # inc_ctr
user.ADDQ(R31, 0, R1, 1, True)
user.MENTER(0) # inc_ctr
user.ADDQ(R31, 0, R1, 2, True)
user.MENTER(0) # read_ctr
user.BR(R0, -1)
print(user.get(), file = imem)

####### syscalls code:
reset = CodeBlock('reset_ctr()') # address 0x80
reset.ADDQ(R31, R31, R1, 0, False)
reset.MENTER(2) # write_secret
reset.RET(R0, R0, 0)

inc = CodeBlock('inc_ctr()') # address 0x8c
inc.MENTER(1) # read_secret
inc.ADDQ(R1, 0, R1, 1, True)
inc.MENTER(2) # write secret
inc.RET(R0, R0, 0)

read = CodeBlock('read_ctr() (Output: R1)') # address 0x9c
read.MENTER(1) # read_secret
read.RET(R0, R0, 0)

print('\n@80\n', file = imem) # start address for syscalls
print(reset.get(), file = imem)
print(inc.get(), file = imem)
print(read.get(), file = imem)


####### Metal code:
metal = CodeBlock('Subroutine Addresses') # Metal address 0x0
metal.BR(R0, 0X1f) # 32 - 1
metal.BR(R0, 0X2b) # 45 - 2
metal.BR(R0, 0X30) # 51 - 3

print (metal.get(), file = mmem)
print ('\n@20\n', file = mmem)

syscall = CodeBlock('syscall (Input: R1)') # Metal address 32 * 4
#backup:
syscall.MWPCR(R2, R8, 0)
syscall.MWPCR(R3, R9, 0)
syscall.MRPCR(R3, R0, 0) # backup mode reg (Metal register 0) 

syscall.ADDQ(R31, 0, R2, 1, True)
syscall.MWPCR(R2, R0, 0) # set to kernel mode
syscall.AND(R1, 0, R2, 0X1f, True)
syscall.SLL(R2, 0, R2, 3, True)
syscall.LDQ(R2, R2, 0) # read syscall table (located in address 0)
syscall.JSR(R0, R2, 0)

#restore:
syscall.MWPCR(R3, R0, 0)
syscall.MRPCR(R2, R8, 0)
syscall.MRPCR(R3, R9, 0)

syscall.MEXIT(0)

# Metal R1 is the secret register
read_secret = CodeBlock('read_secret (Output: R1)') # Metal address 45 * 4
read_secret.MWPCR(R2, R8, 0) # backup R2 in Metal R8
read_secret.MRPCR(R2, R0, 0)
read_secret.BEQ(R2, 1) # check kernel mode
read_secret.MRPCR(R1, R1, 0) 
read_secret.MRPCR(R2, R8, 0) # restore R2
read_secret.MEXIT(0)

write_secret = CodeBlock('write_secret (Input: R1)') # Metal address 51 * 4
write_secret.MWPCR(R2, R8, 0) # backup R2 in Metal R8
write_secret.MRPCR(R2, R0, 0)
write_secret.BEQ(R2, 1) # check kernel mode
write_secret.MWPCR(R1, R1, 0)
write_secret.MRPCR(R2, R8, 0) # restore R2
write_secret.MEXIT(0)

print(syscall.get(), file = mmem)
print(read_secret.get(), file = mmem)
print(write_secret.get(), file = mmem)

print('80\n8c\n9c\n', file = dmem)



