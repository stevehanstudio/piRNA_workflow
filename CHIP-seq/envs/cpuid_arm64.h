/*
 * ARM64 stub for cpuid.h - x86 cpuid is not available on ARM.
 * Replace third_party/cpuid.h with this file when building on aarch64.
 * Bowtie uses this for POPCNT detection; we report "no POPCNT" so it uses
 * the portable fallback.
 */
#ifndef CPUID_ARM64_STUB_H_
#define CPUID_ARM64_STUB_H_

/* Minimal bit defines in case referenced (values match x86 cpuid.h) */
#define bit_POPCNT (1 << 23)
#define bit_SSE4_2 (1 << 20)

/* Stub __cpuid - no-op on ARM */
#define __cpuid(level, a, b, c, d) do { (void)(level); (a)=0; (b)=0; (c)=0; (d)=0; } while(0)
#define __cpuid_count(level, count, a, b, c, d) do { (void)(level); (void)(count); (a)=0; (b)=0; (c)=0; (d)=0; } while(0)

static __inline unsigned int
__get_cpuid_max(unsigned int __ext, unsigned int *__sig)
{
  (void)__ext;
  if (__sig) *__sig = 0;
  return 0;  /* No cpuid on ARM - use fallback code paths */
}

static __inline int
__get_cpuid(unsigned int __level,
            unsigned int *__eax, unsigned int *__ebx,
            unsigned int *__ecx, unsigned int *__edx)
{
  (void)__level;
  if (__eax) *__eax = 0;
  if (__ebx) *__ebx = 0;
  if (__ecx) *__ecx = 0;
  if (__edx) *__edx = 0;
  return 0;  /* Unsupported */
}

#endif
