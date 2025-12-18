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

#include <assert.h>
#include <inttypes.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "hawkeye.h"

int main() {
  FILE *fp = fopen("lib/Binary/hawkeye_oracle.txt", "r");
  if (fp == NULL)
    return 1;

  // Skip header
  while (true) {
    int c = fgetc(fp);
    if (c == '\n' || c == '\0') {
      break;
    }
  }

  hawkeye(1, 0, 0, 0, 0, 0);

  while (1) {
    uint64_t paddr;
    uint8_t set;
    uint32_t pc;
    uint8_t way;
    uint8_t hit;
    uint8_t expected;
    uint8_t actual;

    int cnt = 0;
    cnt += fscanf(fp, "%" SCNx64 ";", &paddr);
    cnt += fscanf(fp, "%" SCNx8 ";", &set);
    cnt += fscanf(fp, "%" SCNx32 ";", &pc);
    cnt += fscanf(fp, "%" SCNx8 ";", &hit);
    cnt += fscanf(fp, "%" SCNx8 ";", &way);
    cnt += fscanf(fp, "%" SCNx8 ";", &expected);
    if (cnt != 6) {
      break;
    }

    actual = hawkeye(0, paddr, set, pc, way, hit);

    printf("%d %d\n", actual, expected);

    assert(actual == expected);
  }

  return 0;
}
