#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>

#include "kuma_asm.h"

#define KUMA_XOR_KEY 0x5A

__attribute__((used, section(".kuma_cr")))
static const unsigned char kuma_cr_obf[] = {
    0x08, 0x1b, 0x13, 0x12, 0x1b, 0x14, 0x7a, 0x14, 0x0f, 0x1d,
    0x08, 0x15, 0x12, 0x15, 0x7a, 0x72, 0x19, 0x73, 0x7a, 0x11,
    0x0f, 0x17, 0x1b, 0x7a, 0x1b, 0x14, 0x13, 0x17, 0x1f,
};

static const int kuma_cr_len = 29;

static unsigned char kuma_xor_byte(unsigned char b, unsigned char k) {
    return (unsigned char)(kuma_asm_xor((unsigned int)b, (unsigned int)k) & 0xFF);
}

static uint64_t kuma_rotl(uint64_t x, unsigned r) {
#if defined(__aarch64__)
    uint64_t res;
    uint64_t rr = (uint64_t)(64u - r);
    __asm__ volatile("ror %0, %1, %2" : "=r"(res) : "r"(x), "r"(rr));
    return res;
#else
    return (x << r) | (x >> (64u - r));
#endif
}

__attribute__((visibility("default")))
const char *kuma_copyright(void) {
    static char buf[64];
    int i;
    for (i = 0; i < kuma_cr_len && i < 63; i++) {
        buf[i] = (char)kuma_xor_byte(kuma_cr_obf[i], KUMA_XOR_KEY);
    }
    buf[i] = '\0';
    return buf;
}

__attribute__((visibility("default")))
uint32_t kuma_copyright_hash(void) {
    uint32_t h = 2166136261u;
    for (int i = 0; i < kuma_cr_len; i++) {
        unsigned char c = kuma_xor_byte(kuma_cr_obf[i], KUMA_XOR_KEY);
        h ^= c;
        h *= 16777619u;
    }
    return h;
}

__attribute__((visibility("default")))
uint32_t kuma_self_checksum(void) {
    uint32_t sum = 0x9E3779B9u;
    for (int i = 0; i < kuma_cr_len; i++) {
        sum = (sum << 5) + sum + kuma_cr_obf[i];
    }
    return sum;
}

__attribute__((visibility("default")))
uint64_t kuma_session_token(uint64_t hw_seed, uint64_t timestamp) {
    uint64_t t = kuma_asm_mix(hw_seed, 0xA5A5A5A5A5A5A5A5ull);
    t = kuma_rotl(t, 13) + timestamp;
    t ^= kuma_rotl(timestamp, 27);
    t *= 0x100000001B3ull;
    return t;
}

__attribute__((visibility("default")))
int kuma_validate_token(uint64_t token, uint64_t hw_seed, uint64_t timestamp) {
    return kuma_session_token(hw_seed, timestamp) == token ? 1 : 0;
}

__attribute__((visibility("default")))
int kuma_anti_debug(void) {
    volatile long pid = kuma_asm_getpid();
    (void)pid;

    int fd = open("/proc/self/status", O_RDONLY);
    if (fd < 0) return 0;

    char buf[512];
    long n = read(fd, buf, sizeof(buf) - 1);
    close(fd);
    if (n <= 0) return 0;
    buf[n] = '\0';

    const char *p = strstr(buf, "TracerPid:");
    if (!p) return 0;
    p += 10;
    while (*p == ' ' || *p == '\t') p++;
    return (*p != '0') ? 1 : 0;
}

__attribute__((visibility("default")))
void kuma_xor_buffer(uint8_t *buffer, uint32_t length, const uint8_t *key, uint32_t key_len) {
    if (!buffer || !key || key_len == 0) return;
    
    for (uint32_t i = 0; i < length; i++) {
        buffer[i] ^= key[i % key_len];
    }
}

__attribute__((visibility("default")))
uint64_t kuma_derive_seed(uint64_t base, uint64_t salt) {
    uint64_t result = kuma_rotl(base, 17);
    result ^= salt;
    result = kuma_rotl(result, 31);
    result *= 0x100000001B3ull;
    result ^= kuma_rotl(salt, 7);
    return result;
}

__attribute__((visibility("default")))
int kuma_check_root(void) {
    const char *paths[] = {
        "/system/bin/su",
        "/system/xbin/su",
        "/sbin/su",
        "/system/su",
        NULL
    };
    
    for (int i = 0; paths[i] != NULL; i++) {
        if (access(paths[i], F_OK) == 0) {
            return 1;
        }
    }
    return 0;
}

__attribute__((visibility("default")))
void kuma_secure_zero(void *ptr, size_t len) {
    if (!ptr || len == 0) return;
    volatile uint8_t *vptr = (volatile uint8_t *)ptr;
    for (size_t i = 0; i < len; i++) {
        vptr[i] = 0;
    }
}
