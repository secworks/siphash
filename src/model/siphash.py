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
    def hash_message(self, key, m):
        blocks = self._m2blocks(m)
        self.set_key(key)
        return 0x55aa55aadeadbeef


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
        self.v[2] ^= 0x00000000000000ff
        for i in range(self.frounds):
            self._siphash_round()
        return self.v[0] ^ self.v[1] ^ self.v[2] ^ self.v[3]


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
    # _m2blocks()
    #
    # Divide the message m into a set of blocks including padding
    # of the final block.
    #---------------------------------------------------------------
    def _m2blocks(self, m):
        return m


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
# long_tests()
#-------------------------------------------------------------------
def long_tests():
    expected = [0xa3817f04ba25a8e66df67214c7550293, 0xda87c1d86b99af44347659119b22fc45,
                0x8177228da4a45dc7fca38bdef60affe4, 0x9c70b60c5267a94e5f33b6b02985ed51,
                0xf88164c12d9c8faf7d0f6e7c7bcd5579, 0x1368875980776f8854527a07690e9627,
                0x14eeca338b208613485ea0308fd7a15e, 0xa1f1ebbed8dbc153c0b84aa61ff08239,
                0x3b62a9ba6258f5610f83e264f31497b4, 0x264499060ad9baabc47f8b02bb6d71ed,
                0x00110dc378146956c95447d3f3d0fbba, 0x0151c568386b6677a2b4dc6f81e5dc18,
                0xd626b266905ef35882634df68532c125, 0x9869e247e9c08b10d029934fc4b952f7,
                0x31fcefac66d7de9c7ec7485fe4494902, 0x5493e99933b0a8117e08ec0f97cfc3d9,
                0x6ee2a4ca67b054bbfd3315bf85230577, 0x473d06e8738db89854c066c47ae47740,
                0xa426e5e423bf4885294da481feaef723, 0x78017731cf65fab074d5208952512eb1,
                0x9e25fc833f2290733e9344a5e83839eb, 0x568e495abe525a218a2214cd3e071d12,
                0x4a29b54552d16b9a469c10528eff0aae, 0xc9d184ddd5a9f5e0cf8ce29a9abf691c,
                0x2db479ae78bd50d8882a8a178a6132ad, 0x8ece5f042d5e447b5051b9eacb8d8f6f,
                0x9c0b53b4b3c307e87eaee08678141f66, 0xabf248af69a6eae4bfd3eb2f129eeb94,
                0x0664da1668574b88b935f3027358aef4, 0xaa4b9dc4bf337de90cd4fd3c467c6ab7,
                0xea5c7f471faf6bde2b1ad7d4686d2287, 0x2939b0183223fafc1723de4f52c43d35,
                0x7c3956ca5eeafc3e363e9d556546eb68, 0x77c6077146f01c32b6b69d5f4ea9ffcf,
                0x37a6986cb8847edf0925f0f1309b54de, 0xa705f0e69da9a8f907241a2e923c8cc8,
                0x3dc47d1f29c448461e9e76ed904f6711, 0x0d62bf01e6fc0e1a0d3c4751c5d3692b,
                0x8c03468bca7c669ee4fd5e084bbee7b5, 0x528a5bb93baf2c9c4473cce5d0d22bd9,
                0xdf6a301e95c95dad97ae0cc8c6913bd8, 0x801189902c857f39e73591285e70b6db,
                0xe617346ac9c231bb3650ae34ccca0c5b, 0x27d93437efb721aa401821dcec5adf89,
                0x89237d9ded9c5e78d8b1c9b166cc7342, 0x4a6d8091bf5e7d651189fa94a250b14c,
                0x0e33f96055e7ae893ffc0e3dcf492902, 0xe61c432b720b19d18ec8d84bdc63151b,
                0xf7e5aef549f782cf379055a608269b16, 0x438d030fd0b7a54fa837f2ad201a6403,
                0xa590d3ee4fbf04e3247e0d27f286423f, 0x5fe2c1a172fe93c4b15cd37caef9f538,
                0x2c97325cbd06b36eb2133dd08b3a017c, 0x92c814227a6bca949ff0659f002ad39e,
                0xdce850110bd8328cfbd50841d6911d87, 0x67f14984c7da791248e32bb5922583da,
                0x1938f2cf72d54ee97e94166fa91d2a36, 0x74481e9646ed49fe0f6224301604698e,
                0x57fca5de98a9d6d8006438d0583d8a1d, 0x9fecde1cefdc1cbed4763674d9575359,
                0xe3040c00eb28f15366ca73cbd872e740, 0x7697009a6a831dfecca91c5993670f7a,
                0x5853542321f567a005d547a4f04759bd, 0x5150d1772f50834a503e069a973fbd7c]


#-------------------------------------------------------------------
# siphash_short_test()
#
# Runs 64 test with siphash in short mode, i.e. with
# 64 bit digest output. This also tests the message padding
# since the generated input varies in size from zero to
# 63 bytes.
#-------------------------------------------------------------------
def siphash_short_test():
    expected = [0x310e0edd47db6f72, 0xfd67dc93c539f874,
                0x5a4fa9d909806c0d, 0x2d7efbd796666785,
                0xb7877127e09427cf, 0x8da699cd64557618,
                0xcee3fe586e46c9cb, 0x37d1018bf50002ab,
                0x6224939a79f5f593, 0xb0e4a90bdf82009e,
                0xf3b9dd94c5bb5d7a, 0xa7ad6b22462fb3f4,
                0xfbe50e86bc8f1e75, 0x903d84c02756ea14,
                0xeef27a8e90ca23f7, 0xe545be4961ca29a1,
                0xdb9bc2577fcc2a3f, 0x9447be2cf5e99a69,
                0x9cd38d96f0b3c14b, 0xbd6179a71dc96dbb,
                0x98eea21af25cd6be, 0xc7673b2eb0cbf2d0,
                0x883ea3e395675393, 0xc8ce5ccd8c030ca8,
                0x94af49f6c650adb8, 0xeab8858ade92e1bc,
                0xf315bb5bb835d817, 0xadcf6b0763612e2f,
                0xa5c91da7acaa4dde, 0x716595876650a2a6,
                0x28ef495c53a387ad, 0x42c341d8fa92d832,
                0xce7cf2722f512771, 0xe37859f94623f3a7,
                0x381205bb1ab0e012, 0xae97a10fd434e015,
                0xb4a31508beff4d31, 0x81396229f0907902,
                0x4d0cf49ee5d4dcca, 0x5c73336a76d8bf9a,
                0xd0a704536ba93e0e, 0x925958fcd6420cad,
                0xa915c29bc8067318, 0x952b79f3bc0aa6d4,
                0xf21df2e41d4535f9, 0x87577519048f53a9,
                0x10a56cf5dfcd9adb, 0xeb75095ccd986cd0,
                0x51a9cb9ecba312e6, 0x96afadfc2ce666c7,
                0x72fe52975a4364ee, 0x5a1645b276d592a1,
                0xb274cb8ebf87870a, 0x6f9bb4203de7b381,
                0xeaecb2a30b22a87f, 0x9924a43cc1315724,
                0xbd838d3aafbf8db7, 0x0b1a2a3265d51aea,
                0x135079a3231ce660, 0x932b2846e4d70666,
                0xe1915f5cb1eca46c, 0xf325965ca16d629f,
                0x575ff28e60381be5, 0x724506eb4c328a95]

    print("\nRunning test with siphash in short digest mode.")
    key = [0x0706050403020100, 0x0f0e0d0c0b0a0908]
    my_siphash = SipHash()

    for inlen in range(64):
        message = [hex(i) for i in range(inlen)]
        result = my_siphash.hash_message(key, message)
        print("Generated: 0x%016x, expected: 0x%016x" %
                  (result, expected[inlen]))
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


#-------------------------------------------------------------------
# main()
#-------------------------------------------------------------------
def main():
    print("Testing the SipHash Python model")
    print("--------------------------------\n")

    siphash_paper_test()
    siphash_short_test()


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
