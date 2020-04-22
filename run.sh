#!/bin/sh -e

verilator -Wall --cc Alpha.v --exe Alpha_test.cpp

case "$OSTYPE" in
    FreeBSD*) gmake -j -C obj_dir -f VAlpha.mk;;
    Linux*) make -j -C obj_dir -f VAlpha.mk;;
esac

./obj_dir/VAlpha

