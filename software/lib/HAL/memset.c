/*
 * Copyright 2025 LIRMM
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <stddef.h>
#include <stdint.h>

void *memset(void *dest, int c, size_t n) {
  unsigned char *p = dest;
  size_t i;
  uintptr_t word;
  size_t word_size = sizeof(uintptr_t);

  /* Expand byte to full machine word */
  word = (unsigned char)c;
  word |= word << 8;
  word |= word << 16;
#if UINTPTR_MAX > 0xffffffff
  word |= word << 32;
#endif

  /* Align pointer to word boundary */
  while (n > 0 && ((uintptr_t)p & (word_size - 1)) != 0) {
    *p++ = (unsigned char)c;
    n--;
  }

  /* Unrolled word stores: 8 words per iteration */
  while (n >= word_size * 8) {
    ((uintptr_t *)p)[0] = word;
    ((uintptr_t *)p)[1] = word;
    ((uintptr_t *)p)[2] = word;
    ((uintptr_t *)p)[3] = word;
    ((uintptr_t *)p)[4] = word;
    ((uintptr_t *)p)[5] = word;
    ((uintptr_t *)p)[6] = word;
    ((uintptr_t *)p)[7] = word;
    p += word_size * 8;
    n -= word_size * 8;
  }

  /* Remaining word stores */
  while (n >= word_size) {
    *(uintptr_t *)p = word;
    p += word_size;
    n -= word_size;
  }

  /* Tail bytes */
  for (i = 0; i < n; i++) {
    p[i] = (unsigned char)c;
  }

  return dest;
}
