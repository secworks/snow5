# SNOW-V in C

This is a cleaned-up C11 implementation of the SNOW-V stream cipher. The
algorithm is described in [A new SNOW stream cipher called SNOW-V][snowv-paper]
by Patrik Ekdahl, Thomas Johansson, Alexander Maximov, and Jing Yang.

The implementation uses a 256-bit key and a 128-bit IV and produces 128 bits
of keystream per call. All mutable state is stored in a `snowv_ctx`, allowing
multiple instances to be used independently.

## Files

- `snowv_core.h` declares the context and API.
- `snowv_core.c` implements SNOW-V.
- `snowv.c` provides a command-line encryption and decryption tool.
- `snowv_test.c` contains the tests.
- `Makefile` builds the CLI and test program.

## Building and testing

Build both programs:

```sh
make
```

Run the tests:

```sh
make test
```

The test program checks the following cases against known keystream blocks:

- the reference key and IV from the original test code;
- an all-zero key and IV;
- a single set bit in the key;
- an all-one key and IV in AEAD mode;
- two simultaneously active contexts using different key material.

## CLI

```text
snowv --key HEX --iv HEX [--aead] [-o FILE] [INPUT]
```

`--key` requires exactly 64 hexadecimal characters and `--iv` exactly 32.
Input is read from `INPUT`, or from standard input when the file is omitted or
specified as `-`. Output is written to standard output unless `-o` is used.

SNOW-V is a stream cipher, so the same operation is used for encryption and
decryption. The following example encrypts and restores a file:

```sh
./snowv \
  --key 505152535455565758595a5b5c5d5e5f0a1a2a3a4a5a6a7a8a9aaabacadaeafa \
  --iv 0123456789abcdeffedcba9876543210 \
  message.txt -o message.enc

./snowv \
  --key 505152535455565758595a5b5c5d5e5f0a1a2a3a4a5a6a7a8a9aaabacadaeafa \
  --iv 0123456789abcdeffedcba9876543210 \
  message.enc -o message.dec
```

The `--aead` option selects the algorithm's AEAD initialization constant. The
tool does not calculate an authentication tag and therefore does not provide
authenticated encryption on its own.

Never reuse the same key and IV combination for different messages. The key is
passed on the command line and may therefore be exposed through shell history
or process listings; this program is primarily intended as a reference and
testing tool.

[snowv-paper]: https://eprint.iacr.org/2018/1143
