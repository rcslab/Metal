#!/bin/bash

verilator -Wall --cc CacheTestBench.v --exe Cache_test.cpp
make -j -C obj_dir -f VCacheTestBench.mk
./obj_dir/VCacheTestBench
