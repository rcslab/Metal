#!/bin/bash

verilator -Wall --cc Alpha.v --exe Alpha_test.cpp
make -j -C obj_dir -f VAlpha.mk
./obj_dir/VAlpha
