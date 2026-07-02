#ifndef KUMA_ASM_H
#define KUMA_ASM_H

#include <stdint.h>

long kuma_asm_getpid(void);
unsigned int kuma_asm_xor(unsigned int a, unsigned int b);
uint64_t kuma_asm_mix(uint64_t a, uint64_t b);

#endif
