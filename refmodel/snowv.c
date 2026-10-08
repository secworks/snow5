//======================================================================
//
// snowv.c
// -------
// Command-line interface for encrypting and decrypting data with SNOW-V.
//
// Author: Joachim Strömbergson
// SPDX-License-Identifier: BSD-2-Clause
//
//======================================================================

#include "snowv_core.h"

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

enum {
    IO_BUFFER_SIZE = 4096
};

typedef struct {
    const char *key_hex;
    const char *iv_hex;
    const char *input_path;
    const char *output_path;
    bool aead_mode;
} cli_options;

typedef enum {
    PARSE_OK,
    PARSE_HELP,
    PARSE_ERROR
} parse_result;

static void print_usage(FILE *stream, const char *program)
{
    fprintf(stream,
            "Usage: %s --key HEX --iv HEX [--aead] [-o FILE] [INPUT]\n"
            "\n"
            "Encrypt or decrypt data with SNOW-V. Input is read from INPUT,\n"
            "or from standard input when INPUT is omitted or '-'. Output is\n"
            "written to standard output unless -o is specified.\n"
            "\n"
            "Options:\n"
            "  -k, --key HEX   256-bit key as 64 hexadecimal characters\n"
            "  -i, --iv HEX    128-bit IV as 32 hexadecimal characters\n"
            "  -a, --aead      Enable the AEAD initialization constant\n"
            "  -o FILE         Write output to FILE\n"
            "  -h, --help      Show this help\n",
            program);
}

static bool take_option_value(int argc, char **argv, int *index,
                              const char **value)
{
    if (*index + 1 >= argc) {
        fprintf(stderr, "Missing value after %s\n", argv[*index]);
        return false;
    }

    *index += 1;
    *value = argv[*index];
    return true;
}

static parse_result parse_options(int argc, char **argv, cli_options *options)
{
    bool positional_only = false;

    memset(options, 0, sizeof(*options));

    for (int i = 1; i < argc; ++i) {
        const char *argument = argv[i];

        if (!positional_only && strcmp(argument, "--") == 0) {
            positional_only = true;
        } else if (!positional_only &&
                   (strcmp(argument, "-h") == 0 ||
                    strcmp(argument, "--help") == 0)) {
            return PARSE_HELP;
        } else if (!positional_only &&
                   (strcmp(argument, "-a") == 0 ||
                    strcmp(argument, "--aead") == 0)) {
            options->aead_mode = true;
        } else if (!positional_only &&
                   (strcmp(argument, "-k") == 0 ||
                    strcmp(argument, "--key") == 0)) {
            if (!take_option_value(argc, argv, &i, &options->key_hex)) {
                return PARSE_ERROR;
            }
        } else if (!positional_only &&
                   (strcmp(argument, "-i") == 0 ||
                    strcmp(argument, "--iv") == 0)) {
            if (!take_option_value(argc, argv, &i, &options->iv_hex)) {
                return PARSE_ERROR;
            }
        } else if (!positional_only && strcmp(argument, "-o") == 0) {
            if (!take_option_value(argc, argv, &i, &options->output_path)) {
                return PARSE_ERROR;
            }
        } else if (!positional_only && argument[0] == '-' && argument[1] != '\0') {
            fprintf(stderr, "Unknown option: %s\n", argument);
            return PARSE_ERROR;
        } else if (options->input_path == NULL) {
            options->input_path = argument;
        } else {
            fprintf(stderr, "Unexpected argument: %s\n", argument);
            return PARSE_ERROR;
        }
    }

    if (options->key_hex == NULL || options->iv_hex == NULL) {
        fputs("Both --key and --iv are required.\n", stderr);
        return PARSE_ERROR;
    }

    return PARSE_OK;
}

static int hex_value(char digit)
{
    if (digit >= '0' && digit <= '9') {
        return digit - '0';
    }
    if (digit >= 'a' && digit <= 'f') {
        return digit - 'a' + 10;
    }
    if (digit >= 'A' && digit <= 'F') {
        return digit - 'A' + 10;
    }
    return -1;
}

static bool parse_hex(const char *text, uint8_t *output, size_t output_size,
                      const char *description)
{
    const size_t expected_length = output_size * 2U;

    if (strlen(text) != expected_length) {
        fprintf(stderr, "%s must contain exactly %zu hexadecimal characters.\n",
                description, expected_length);
        return false;
    }

    for (size_t i = 0; i < output_size; ++i) {
        const int high = hex_value(text[2U * i]);
        const int low = hex_value(text[2U * i + 1U]);

        if (high < 0 || low < 0) {
            fprintf(stderr, "%s contains a non-hexadecimal character.\n",
                    description);
            return false;
        }
        output[i] = (uint8_t)((unsigned int)high << 4U | (unsigned int)low);
    }

    return true;
}

static void clear_bytes(void *memory, size_t size)
{
    volatile uint8_t *byte = memory;
    while (size > 0U) {
        *byte++ = 0;
        --size;
    }
}

static bool transform(FILE *input, FILE *output, snowv_ctx *ctx)
{
    uint8_t buffer[IO_BUFFER_SIZE];
    uint8_t keystream[SNOWV_BLOCK_SIZE];
    size_t keystream_offset = SNOWV_BLOCK_SIZE;
    size_t count;

    while ((count = fread(buffer, 1, sizeof(buffer), input)) > 0U) {
        for (size_t i = 0; i < count; ++i) {
            if (keystream_offset == SNOWV_BLOCK_SIZE) {
                snowv_generate(ctx, keystream);
                keystream_offset = 0;
            }
            buffer[i] ^= keystream[keystream_offset++];
        }

        if (fwrite(buffer, 1, count, output) != count) {
            perror("Could not write output");
            clear_bytes(buffer, sizeof(buffer));
            clear_bytes(keystream, sizeof(keystream));
            return false;
        }
    }

    clear_bytes(buffer, sizeof(buffer));
    clear_bytes(keystream, sizeof(keystream));

    if (ferror(input)) {
        perror("Could not read input");
        return false;
    }
    return true;
}

int main(int argc, char **argv)
{
    cli_options options;
    uint8_t key[SNOWV_KEY_SIZE];
    uint8_t iv[SNOWV_IV_SIZE];
    snowv_ctx ctx;
    FILE *input = stdin;
    FILE *output = stdout;
    int status = EXIT_FAILURE;

    const parse_result result = parse_options(argc, argv, &options);
    if (result == PARSE_HELP) {
        print_usage(stdout, argv[0]);
        return EXIT_SUCCESS;
    }
    if (result == PARSE_ERROR) {
        print_usage(stderr, argv[0]);
        return EXIT_FAILURE;
    }

    if (!parse_hex(options.key_hex, key, sizeof(key), "Key") ||
        !parse_hex(options.iv_hex, iv, sizeof(iv), "IV")) {
        clear_bytes(key, sizeof(key));
        return EXIT_FAILURE;
    }

    if (options.input_path != NULL && options.output_path != NULL &&
        strcmp(options.input_path, "-") != 0 &&
        strcmp(options.output_path, "-") != 0 &&
        strcmp(options.input_path, options.output_path) == 0) {
        fputs("Input and output must be different files.\n", stderr);
        goto cleanup;
    }

    if (options.input_path != NULL && strcmp(options.input_path, "-") != 0) {
        input = fopen(options.input_path, "rb");
        if (input == NULL) {
            fprintf(stderr, "Could not open input '%s': %s\n",
                    options.input_path, strerror(errno));
            goto cleanup;
        }
    }

    if (options.output_path != NULL && strcmp(options.output_path, "-") != 0) {
        output = fopen(options.output_path, "wb");
        if (output == NULL) {
            fprintf(stderr, "Could not open output '%s': %s\n",
                    options.output_path, strerror(errno));
            goto cleanup;
        }
    }

    snowv_init(&ctx, key, iv, options.aead_mode);
    if (transform(input, output, &ctx)) {
        status = EXIT_SUCCESS;
    }
    snowv_clear(&ctx);

cleanup:
    clear_bytes(key, sizeof(key));
    clear_bytes(iv, sizeof(iv));

    if (output != NULL && output != stdout && fclose(output) != 0) {
        perror("Could not close output");
        status = EXIT_FAILURE;
    } else if (output == stdout && fflush(output) != 0) {
        perror("Could not flush output");
        status = EXIT_FAILURE;
    }
    if (input != NULL && input != stdin && fclose(input) != 0) {
        perror("Could not close input");
        status = EXIT_FAILURE;
    }

    return status;
}
