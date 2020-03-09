LINES = 65536
BYTES_PER_ROW = 64
start = 0
with open('test.mem', 'w') as f:
    for _ in range(LINES):
        ctr = start
        for _ in range(BYTES_PER_ROW):
            f.write(hex(ctr)[2:].zfill(2))
            ctr = (ctr + 1) % 256
        f.write('\n')
        start = (start + 1) % 256
