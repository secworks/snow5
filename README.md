# snow5
Hardware implementation of the SNOW-V stream cipher.

## Status
Not completed. Does not work. Do **not** use.


## Introduction
The [SNOW-V stream cipher](https://eprint.iacr.org/2018/1143.pdf) is a
new cipher in the family of SNOW stream ciphers. SNOW-V is designed to
meet requirements in terms of performance for 5G applications.

This hardware implementation reuse the AES encryption round function
from the [AES core](https://github.com/secworks/aes).
