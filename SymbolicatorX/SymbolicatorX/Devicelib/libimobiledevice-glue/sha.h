#ifndef __SHA_H
#define __SHA_H

#include <stddef.h>
#include <stdint.h>

#include <libimobiledevice-glue/glue.h>

#ifdef __cplusplus
extern "C" {
#endif

/* LibTomCrypt, modular cryptographic library -- Tom St Denis
 *
 * LibTomCrypt is a library that provides various cryptographic
 * algorithms in a highly modular and flexible manner.
 *
 * The library is free for all purposes without any express
 * guarantee it works.
 *
 * Tom St Denis, tomstdenis@gmail.com, http://libtom.org
 */

/* SHA-1 */
typedef struct sha1_context_ {
    uint64_t length;
    uint32_t state[5];
    size_t curlen;
    unsigned char buf[64];
} sha1_context;

#define SHA1_DIGEST_LENGTH 20

LIMD_GLUE_API int sha1_init(sha1_context * md);
LIMD_GLUE_API int sha1_final(sha1_context * md, unsigned char *out);
LIMD_GLUE_API int sha1_update(sha1_context * md, const void *data, size_t inlen);
LIMD_GLUE_API int sha1(const unsigned char *message, size_t message_len, unsigned char *out);

/* SHA-256 */
typedef struct sha256_context_ {
    uint64_t length;
    uint32_t state[8];
    size_t curlen;
    unsigned char buf[64];
    int num_dwords;
} sha256_context;

#define SHA256_DIGEST_LENGTH 32

LIMD_GLUE_API int sha256_init(sha256_context * md);
LIMD_GLUE_API int sha256_final(sha256_context * md, unsigned char *out);
LIMD_GLUE_API int sha256_update(sha256_context * md, const void *data, size_t inlen);
LIMD_GLUE_API int sha256(const unsigned char *message, size_t message_len, unsigned char *out);

/* SHA-224 */
#define sha224_context sha256_context

#define SHA224_DIGEST_LENGTH 28

LIMD_GLUE_API int sha224_init(sha224_context * md);
LIMD_GLUE_API int sha224_final(sha224_context * md, unsigned char *out);
LIMD_GLUE_API int sha224_update(sha224_context * md, const void *data, size_t inlen);
LIMD_GLUE_API int sha224(const unsigned char *message, size_t message_len, unsigned char *out);

/* SHA-512 */
typedef struct sha512_context_ {
    uint64_t length, state[8];
    size_t curlen;
    unsigned char buf[128];
    int num_qwords;
} sha512_context;

#define SHA512_DIGEST_LENGTH 64

LIMD_GLUE_API int sha512_init(sha512_context * md);
LIMD_GLUE_API int sha512_final(sha512_context * md, unsigned char *out);
LIMD_GLUE_API int sha512_update(sha512_context * md, const void *data, size_t inlen);
LIMD_GLUE_API int sha512(const unsigned char *message, size_t message_len, unsigned char *out);

/* SHA-384 */
#define sha384_context sha512_context

#define SHA384_DIGEST_LENGTH 48

LIMD_GLUE_API int sha384_init(sha384_context * md);
LIMD_GLUE_API int sha384_final(sha384_context * md, unsigned char *out);
LIMD_GLUE_API int sha384_update(sha384_context * md, const void *data, size_t inlen);
LIMD_GLUE_API int sha384(const unsigned char *message, size_t message_len, unsigned char *out);

#ifdef __cplusplus
}
#endif

#endif
