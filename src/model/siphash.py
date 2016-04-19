#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#=======================================================================
#
# siphash.py
# ---------
# Simple model of the Siphash shor-input PRF. Used as a reference for
# the HW implementation. The code follows the structure of the
# HW implementation as much as possible.
#
#
# Copyright (c) 2013 Secworks Sweden AB
# Author: Joachim Strömbergson
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
# Constants.
#-------------------------------------------------------------------
TAU   = [0x61707865, 0x3120646e, 0x79622d36, 0x6b206574]
SIGMA = [0x61707865, 0x3320646e, 0x79622d32, 0x6b206574]
MAX64 = 2**64 - 1

#-------------------------------------------------------------------
# SipHash()
#-------------------------------------------------------------------
class SipHash():

    #---------------------------------------------------------------
    # __init__()
    #---------------------------------------------------------------
    def __init__(self, crounds = 2, frounds = 4, mode = "short", verbose = 0):
        self.v = [0] * 4
        self.crounds = crounds
        self.frounds = frounds
        self.mode = mode
        self.verbose = verbose


    #---------------------------------------------------------------
    # hash_message(key, message)
    #
    # hash_message and return the result.
    #---------------------------------------------------------------
    def hash_message(self, key, message):
        self.set_key(key)
        for block in message:
            self.compression(block)
        return self.finalization()


    #---------------------------------------------------------------
    # set_key()
    #
    # Initalize the hash state based on the given key.
    #---------------------------------------------------------------
    def set_key(self, key):
        self.v[0] = key[0] ^ 0x736f6d6570736575
        self.v[1] = key[1] ^ 0x646f72616e646f6d
        self.v[2] = key[0] ^ 0x6c7967656e657261
        self.v[3] = key[1] ^ 0x7465646279746573

        if self.mode == "long":
            self.v[1] = self.v[1] ^ 0x00000000000000ee

        if self.verbose > 0:
            print("State after set_key:")
            self._print_state()


    #---------------------------------------------------------------
    # compression()
    #
    # Process the message word m
    #---------------------------------------------------------------
    def compression(self, m):
        self.v[3] ^= m

        if self.verbose > 0:
            print("State after v3 init in compression:")
            self._print_state()

        for i in range(self.crounds):
            self._siphash_round()
        self.v[0] ^= m

        if self.verbose > 0:
            print("State after compression:")
            self._print_state()


    #---------------------------------------------------------------
    # finalization()
    #
    # Do the finalization processing and return the hash value.
    #---------------------------------------------------------------
    def finalization(self):
        if self.mode == "long":
            self.v[2] ^= 0x00000000000000ee

        else:
            self.v[2] ^= 0x00000000000000ff

        for i in range(self.frounds):
            self._siphash_round()

        if self.mode == "short":
            return self.v[0] ^ self.v[1] ^ self.v[2] ^ self.v[3]

        else:
            first = self.v[0] ^ self.v[1] ^ self.v[2] ^ self.v[3]
            self.v[1] = self.v[1] ^ 0x00000000000000dd

            for i in range(self.frounds):
                self._siphash_round()

            second = self.v[0] ^ self.v[1] ^ self.v[2] ^ self.v[3]
        return ((second << 64) + first)


    #---------------------------------------------------------------
    # _siphash_round()
    # The state updating round function used in compression as
    # well as in finalization operations.
    #---------------------------------------------------------------
    def _siphash_round(self):
        self.v[0] = (self.v[0] + self.v[1]) & MAX64
        self.v[2] = (self.v[2] + self.v[3]) & MAX64
        self.v[1] = ((self.v[1] << 13) & MAX64) | (self.v[1] >> 51 & MAX64)
        self.v[3] = ((self.v[3] << 16) & MAX64) | (self.v[3] >> 48 & MAX64)
        self.v[1] = self.v[1] ^ self.v[0]
        self.v[3] = self.v[3] ^self.v[2]
        self.v[0] = ((self.v[0] << 32) & MAX64) | (self.v[0] >> 32 & MAX64)
        self.v[2] = (self.v[2] + self.v[1]) & MAX64
        self.v[0] = (self.v[0] + self.v[3]) & MAX64
        self.v[1] = ((self.v[1] << 17) % MAX64) | (self.v[1] >> 47 % MAX64)
        self.v[3] = ((self.v[3] << 21) % MAX64) | (self.v[3] >> 43 % MAX64)
        self.v[1] = self.v[1] ^ self.v[2]
        self.v[3] = self.v[3] ^ self.v[0]
        self.v[2] = ((self.v[2] << 32) % MAX64) | (self.v[2] >> 32 % MAX64)


    #---------------------------------------------------------------
    # _print_state()
    #
    # Print the internal state.
    #---------------------------------------------------------------
    def _print_state(self):
        print("v0 = 0x%016x, v1 = 0x%016x, v2 = 0x%016x, v3 = 0x%016x" %
                  (self.v[0], self.v[1], self.v[2], self.v[3]))
        print("")


#-------------------------------------------------------------------
# load_test_vectors()
#
# Loads test vectors from a given file and return them as a
# list with tuples where each tuple contains the number of
# elements in the message, the message as a list of words
# and the digest that should be generated.
#-------------------------------------------------------------------
def load_test_vectors(filename):
    test_vectors = []
    message_blocks = []
    length = 0
    digest = 0
    first = True

    with open(filename) as tc_file:
        for line in tc_file:
            if "Siphash called" in line:
                if not first:
                    test_vectors.append((length, message_blocks, digest))
                    message_blocks = []
                    digest = 0
                    length += 1
                else:
                    first = False

            if "message block" in line:
                message_blocks += [int(line.split(":")[1][1 : -1], 16)]

            if "final block" in line:
                message_blocks += [int(line.split(":")[1][3 : -1], 16)]

            if "Digest" in line:
                digest = int(line.split(":")[1][8:-1], 16)

        # The final set of test vectors.
        test_vectors.append((length, message_blocks, digest))

    return test_vectors


#-------------------------------------------------------------------
# siphash_short_test()
#
# Runs 64 test with siphash in long mode, i.e. with
# 128 bit digest output.
#-------------------------------------------------------------------
def siphash_long_test():
    print("Running test with test vectors for 128 bit digest.")

    errors = 0
    key = [0x0706050403020100, 0x0f0e0d0c0b0a0908]
    my_siphash = SipHash(mode = "long")

    test_vectors = load_test_vectors("long_test_vectors.txt")
    for test_vector in test_vectors:
        (length, message, digest) = test_vector
        result = my_siphash.hash_message(key, message)

        if result != digest:
            print("Incorrect result: 0x%032x, expected 0x%032x" % (result, digest))
            errors += 1
        else:
            print("Correct result: 0x%032x" % result)

    if errors == 0:
        print("All long test vectors ok.")
    print("")


#-------------------------------------------------------------------
# siphash_short_test()
#
# Runs 64 test with siphash in short mode, i.e. with
# 64 bit digest output.
#-------------------------------------------------------------------
def siphash_short_test():
    print("Running test with test vectors for 64 bit digest.")
    errors = 0
    key = [0x0706050403020100, 0x0f0e0d0c0b0a0908]
    my_siphash = SipHash()

    test_vectors = load_test_vectors("short_test_vectors.txt")
    for test_vector in test_vectors:
        (length, message, digest) = test_vector
        result = my_siphash.hash_message(key, message)

        if result != digest:
            print("Incorrect result: 0x%016x, expected 0x%0x016x" % result, digest)
            errors += 1
        else:
            print("Correct result: 0x%016x" % result)

    if errors == 0:
        print("All short test vectors ok.")
    print("")


#-------------------------------------------------------------------
# siphash_paper_test()
#
# Run test with the test vectors given in Appedix A of the
# SipHash paper: https://131002.net/siphash/siphash.pdf
#-------------------------------------------------------------------
def siphash_paper_test():
    print("Running test with vectors from the SipHash paper.")

    my_siphash = SipHash(verbose=2)
    key = [0x0706050403020100, 0x0f0e0d0c0b0a0908]
    my_siphash.set_key(key)

    m1 = 0x0706050403020100
    my_siphash.compression(m1)

    m2 = 0x0f0e0d0c0b0a0908
    my_siphash.compression(m2)

    result = my_siphash.finalization()
    expected = 0xa129ca6149be45e5

    if result == expected:
        print("Correct result 0x%016x generated." % result)
    else:
        print("Incorrect result 0x%016x generated, expected 0x%016x." % (result, expected))
    print("")


#-------------------------------------------------------------------
# main()
#-------------------------------------------------------------------
def main():
    print("Testing the SipHash Python model")
    print("--------------------------------\n")

    siphash_paper_test()
    siphash_short_test()
    siphash_long_test()


#-------------------------------------------------------------------
# __name__
# Python thingy which allows the file to be run standalone as
# well as parsed from within a Python interpreter.
#-------------------------------------------------------------------
if __name__=="__main__":
    # Run the main function.
    sys.exit(main())

#=======================================================================
# EOF siphash.py
#=======================================================================
