//======================================================================
//
// snowv_core.h
// ------------
// Public API and context definition for the SNOW-V implementation.
//
// Author: Joachim Strömbergson
// SPDX-License-Identifier: BSD-2-Clause
//
//======================================================================

#ifndef SNOWV_CORE_H
#define SNOWV_CORE_H

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

enum {
    SNOWV_KEY_SIZE = 32,
    SNOWV_IV_SIZE = 16,
    SNOWV_BLOCK_SIZE = 16,
    SNOWV_LFSR_WORDS = 16,
    SNOWV_FSM_WORDS = 4
};

typedef struct snowv_ctx {
    uint16_t lfsr_a[SNOWV_LFSR_WORDS];
    uint16_t lfsr_b[SNOWV_LFSR_WORDS];
    uint32_t r1[SNOWV_FSM_WORDS];
    uint32_t r2[SNOWV_FSM_WORDS];
    uint32_t r3[SNOWV_FSM_WORDS];
} snowv_ctx;

void snowv_init(
    snowv_ctx *ctx,
    const uint8_t key[SNOWV_KEY_SIZE],
    const uint8_t iv[SNOWV_IV_SIZE],
    bool aead_mode);

void snowv_generate(
    snowv_ctx *ctx,
    uint8_t output[SNOWV_BLOCK_SIZE]);

void snowv_clear(snowv_ctx *ctx);

#ifdef __cplusplus
}
#endif

#endif
