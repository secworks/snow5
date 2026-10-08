#=======================================================================
#
# Makefile
# --------
# Build rules for the SNOW-V command-line tool and test program.
#
# Author: Joachim Strömbergson
# SPDX-License-Identifier: BSD-2-Clause
#
#=======================================================================

CC ?= cc
CPPFLAGS ?=
CFLAGS ?= -std=c11 -O2 -Wall -Wextra -Wpedantic -Wconversion -Wshadow
LDFLAGS ?=
LDLIBS ?=

PROGRAMS := snowv snowv_test
CORE_OBJECT := snowv_core.o

.PHONY: all test clean

all: $(PROGRAMS)

snowv: snowv.o $(CORE_OBJECT)
	$(CC) $(LDFLAGS) $^ $(LDLIBS) -o $@

snowv_test: snowv_test.o $(CORE_OBJECT)
	$(CC) $(LDFLAGS) $^ $(LDLIBS) -o $@

snowv.o: snowv.c snowv_core.h
snowv_test.o: snowv_test.c snowv_core.h
snowv_core.o: snowv_core.c snowv_core.h

test: snowv_test
	./snowv_test

clean:
	$(RM) $(PROGRAMS) snowv.o snowv_test.o $(CORE_OBJECT)
