/* Cross-platform assembly routines for the Kuma Anime security module.
 * Covers the ABIs enabled in build.gradle: arm64-v8a, armeabi-v7a, x86_64.
 */

#if defined(__aarch64__)

    .text
    .global kuma_asm_getpid
    .type kuma_asm_getpid, %function
kuma_asm_getpid:
    mov x8, #172
    svc #0
    ret

    .global kuma_asm_xor
    .type kuma_asm_xor, %function
kuma_asm_xor:
    eor w0, w0, w1
    ret

    .global kuma_asm_mix
    .type kuma_asm_mix, %function
kuma_asm_mix:
    eor x0, x0, x1
    ror x0, x0, #17
    ret

#elif defined(__arm__)

    .text
    .global kuma_asm_getpid
    .type kuma_asm_getpid, %function
kuma_asm_getpid:
    mov r7, #20
    svc #0
    bx lr

    .global kuma_asm_xor
    .type kuma_asm_xor, %function
kuma_asm_xor:
    eor r0, r0, r1
    bx lr

    .global kuma_asm_mix
    .type kuma_asm_mix, %function
kuma_asm_mix:
    eor r0, r0, r2
    eor r1, r1, r3
    bx lr

#elif defined(__x86_64__)

    .text
    .global kuma_asm_getpid
kuma_asm_getpid:
    mov $39, %eax
    syscall
    ret

    .global kuma_asm_xor
kuma_asm_xor:
    mov %edi, %eax
    xor %esi, %eax
    ret

    .global kuma_asm_mix
kuma_asm_mix:
    mov %rdi, %rax
    xor %rsi, %rax
    rol $17, %rax
    ret

#endif
