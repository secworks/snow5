//======================================================================
//
// snowv_test.c
// ------------
// Test vectors and independent-context tests for the SNOW-V implementation.
//
// Author: Joachim Strömbergson
// SPDX-License-Identifier: BSD-2-Clause
//
//======================================================================

#include "snowv_core.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    const char *name;
    uint8_t key[SNOWV_KEY_SIZE];
    uint8_t iv[SNOWV_IV_SIZE];
    bool aead_mode;
    uint8_t expected[SNOWV_BLOCK_SIZE];
} test_vector;

static const test_vector vectors[] = {
    {
        .name = "original",
        .key = {
            0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57,
            0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f,
            0x0a, 0x1a, 0x2a, 0x3a, 0x4a, 0x5a, 0x6a, 0x7a,
            0x8a, 0x9a, 0xaa, 0xba, 0xca, 0xda, 0xea, 0xfa
        },
        .iv = {
            0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef,
            0xfe, 0xdc, 0xba, 0x98, 0x76, 0x54, 0x32, 0x10
        },
        .aead_mode = false,
        .expected = {
            0xaa, 0x81, 0xea, 0xfb, 0x8b, 0x86, 0x16, 0xce,
            0x3e, 0x5c, 0xe2, 0x22, 0x24, 0x61, 0xc5, 0x0a
        }
    },
    {
        .name = "zero key and IV",
        .key = {0},
        .iv = {0},
        .aead_mode = false,
        .expected = {
            0x69, 0xca, 0x6d, 0xaf, 0x9a, 0xe3, 0xb7, 0x2d,
            0xb1, 0x34, 0xa8, 0x5a, 0x83, 0x7e, 0x41, 0x9d
        }
    },
    {
        .name = "single key bit",
        .key = {[SNOWV_KEY_SIZE - 1] = 0x01},
        .iv = {0},
        .aead_mode = false,
        .expected = {
            0xd0, 0x8a, 0x56, 0xa9, 0x7a, 0x49, 0xc9, 0x29,
            0x53, 0xf2, 0x72, 0x2b, 0x07, 0x3c, 0x77, 0xa4
        }
    },
    {
        .name = "all ones, AEAD",
        .key = {
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
        },
        .iv = {
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
        },
        .aead_mode = true,
        .expected = {
            0x71, 0xf1, 0xb1, 0x1b, 0xfd, 0x25, 0x3f, 0xa0,
            0xe4, 0xaf, 0xc8, 0x54, 0x62, 0xbf, 0xaa, 0x99
        }
    }
};

static void print_block(const uint8_t block[SNOWV_BLOCK_SIZE])
{
    for (size_t i = 0; i < SNOWV_BLOCK_SIZE; ++i) {
        printf("%02x%s", (unsigned int)block[i],
               i + 1U == SNOWV_BLOCK_SIZE ? "" : " ");
    }
    putchar('\n');
}

static bool run_vector(const test_vector *vector)
{
    snowv_ctx ctx;
    uint8_t output[SNOWV_BLOCK_SIZE];

    snowv_init(&ctx, vector->key, vector->iv, vector->aead_mode);
    snowv_generate(&ctx, output);
    snowv_clear(&ctx);

    if (memcmp(output, vector->expected, sizeof(output)) == 0) {
        printf("PASS: %s\n", vector->name);
        return true;
    }

    printf("FAIL: %s\nexpected: ", vector->name);
    print_block(vector->expected);
    printf("actual:   ");
    print_block(output);
    return false;
}

static bool run_independent_context_test(void)
{
    snowv_ctx first;
    snowv_ctx second;
    uint8_t first_output[SNOWV_BLOCK_SIZE];
    uint8_t second_output[SNOWV_BLOCK_SIZE];

    snowv_init(&first, vectors[0].key, vectors[0].iv, vectors[0].aead_mode);
    snowv_init(&second, vectors[1].key, vectors[1].iv, vectors[1].aead_mode);

    snowv_generate(&first, first_output);
    snowv_generate(&second, second_output);
    snowv_clear(&first);
    snowv_clear(&second);

    const bool passed =
        memcmp(first_output, vectors[0].expected, sizeof(first_output)) == 0 &&
        memcmp(second_output, vectors[1].expected, sizeof(second_output)) == 0;

    printf("%s: independent contexts\n", passed ? "PASS" : "FAIL");
    return passed;
}

int main(void)
{
    bool passed = true;

    for (size_t i = 0; i < sizeof(vectors) / sizeof(vectors[0]); ++i) {
        passed = run_vector(&vectors[i]) && passed;
    }
    passed = run_independent_context_test() && passed;

    return passed ? EXIT_SUCCESS : EXIT_FAILURE;
}
