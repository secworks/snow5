#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#=======================================================================
#
# snow5.py
# --------
# Simple, pure Python reference model of the SNOW-V stream cipher:
# https://eprint.iacr.org/2018/1143.pdf
#
# The model is used as a functional reference for the hardware
# implementation.
#
#
# Author: Joachim Strömbergson
# Copyright (c) 2019, Assured AB AB
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or
# without modification, are permitted provided that the following
# conditions are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#=======================================================================

#-------------------------------------------------------------------
# Python module imports.
#-------------------------------------------------------------------
import sys


#-------------------------------------------------------------------
# AES()
#-------------------------------------------------------------------
class SNOW5():
    VERBOSE = True

    #-------------------------------------------------------------------
    #-------------------------------------------------------------------
    def __init__(self, verbose = False):
        self.verbose = verbose
        self.A = [0] * 16
        self.B = [0] * 16
        self.R1 = 0
        self.R2 = 0
        self.R3 = 0
        self.T1 = [0] * 8
        self.T2 = [0] * 8
        self.z  = 0


    #-------------------------------------------------------------------
    #-------------------------------------------------------------------
    def init(self, key, iv):
        assert (len(key) == 16)
        assert (len(iv) == 8)

        for i in range(8):
            self.A[(15 - i)] = key[(7 - i)]
            self.A[(7 - i)]  = iv[(7 - i)]
            self.B[(15 - i)] = key[(15 - i)]
            self.B[i]        = 0

        self.R1          = 0
        self.R2          = 0
        self.R3          = 0

        for t in range(16):
            self.T = 0
            self.FSM_update()
            self.LFSR_update()


    #-------------------------------------------------------------------
    #-------------------------------------------------------------------
    def next(self):
        pass


    #-------------------------------------------------------------------
    #-------------------------------------------------------------------
    def LFSR_update():
        pass


    #-------------------------------------------------------------------
    #-------------------------------------------------------------------
    def FSM_update():
        pass


    #-------------------------------------------------------------------
    # selftest()
    #
    # Test the implementation using the official test vectors and
    # additional test vectors.
    #-------------------------------------------------------------------
    def selftest(self):
        pass


#-------------------------------------------------------------------
# __name__
#-------------------------------------------------------------------
if __name__=="__main__":
    print("Testing the SNOW-V cipher model")
    print("===============================")
    print("")

    my_snow5 = SNOW5(True)
    my_snow.selftest()
    sys.exit(0)


#=======================================================================
# EOF snow5.py
#=======================================================================
