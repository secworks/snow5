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
        self.R1 = [0] * 4
        self.R2 = [0] * 4
        self.R3 = [0] * 4
        self.T1 = [0] * 8
        self.T2 = [0] * 8
        self.z  = 0


    #-------------------------------------------------------------------
    #-------------------------------------------------------------------
    def init(self, key, iv, aead_mode = False):
        assert (len(key) == 16)
        assert (len(iv) == 8)

        for i in range(8):
            self.A[(15 - i)] = key[(7 - i)]
            self.A[(7 - i)]  = iv[(7 - i)]
            self.B[(15 - i)] = key[(15 - i)]
            self.B[i]        = 0

        if aead_mode:
            self.B[0] = 0x6C41
            self.B[1] = 0x7865
            self.B[2] = 0x6B45
            self.B[3] = 0x2064
            self.B[4] = 0x694A
            self.B[5] = 0x676E
            self.B[6] = 0x6854
            self.B[7] = 0x6D6F

        self.__dump_lfsr_state()

#        for aead
#        self.R1 = 0
#        self.R2 = 0
#        self.R3 = 0
#
#        for t in range(16):
#            self.T = 0
#            self.FSM_update()
#            self.LFSR_update()


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
        self.__dump_lfsr_state()
        self.__dump_fsm_state()
        pass


    def __dump_lfsr_state(self):
        print("LFSR state:")
        print("A: 0x%04x 0x%04x 0x%04x 0x%04x" % (self.A[0],  self.A[1],  self.A[2],  self.A[3]))
        print("   0x%04x 0x%04x 0x%04x 0x%04x" % (self.A[4],  self.A[5],  self.A[6],  self.A[7]))
        print("   0x%04x 0x%04x 0x%04x 0x%04x" % (self.A[8],  self.A[9],  self.A[10], self.A[11]))
        print("   0x%04x 0x%04x 0x%04x 0x%04x" % (self.A[12], self.A[13], self.A[14], self.A[15]))
        print("")
        print("B: 0x%04x 0x%04x 0x%04x 0x%04x" % (self.B[0],  self.B[1],  self.B[2],  self.B[3]))
        print("   0x%04x 0x%04x 0x%04x 0x%04x" % (self.B[4],  self.B[5],  self.B[6],  self.B[7]))
        print("   0x%04x 0x%04x 0x%04x 0x%04x" % (self.B[8],  self.B[9],  self.B[10], self.B[11]))
        print("   0x%04x 0x%04x 0x%04x 0x%04x" % (self.B[12], self.B[13], self.B[14], self.B[15]))
        print("")
        print("")


    def __dump_fsm_state(self):
        print("FSM state:")
        print("R1: 0x%08x 0x%08x 0x%08x 0x%08x" % (self.R1[0],  self.R1[1],  self.R1[2],  self.R1[3]))
        print("R2: 0x%08x 0x%08x 0x%08x 0x%08x" % (self.R2[0],  self.R2[1],  self.R2[2],  self.R2[3]))
        print("R3: 0x%08x 0x%08x 0x%08x 0x%08x" % (self.R3[0],  self.R3[1],  self.R3[2],  self.R3[3]))
        print("")
        print("")


#-------------------------------------------------------------------
# __name__
#-------------------------------------------------------------------
if __name__=="__main__":
    print("Testing the SNOW-V cipher model")
    print("===============================")
    print("")

    my_snow5 = SNOW5(True)
    my_snow5.selftest()
    sys.exit(0)


#=======================================================================
# EOF snow5.py
#=======================================================================
