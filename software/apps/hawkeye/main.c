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

#include <stdint.h>
#include <stdlib.h>

#include "hawkeye.h"

#define PERIPH 0x00090000

typedef struct __attribute__((packed)) {
  uint64_t paddr;
  uint32_t set;
  uint64_t pc;
  uint8_t way;
  uint8_t hit : 1;
  uint8_t init : 1;
  uint32_t _reserved : 22;
} req_t;

typedef struct __attribute__((packed)) {
  uint8_t victimWay;
  uint32_t _reserved : 24;
} rsp_t;

static req_t read_req(void) {
  volatile uint32_t *base = (volatile uint32_t *)PERIPH;
  uint32_t w0, w1, w2, w3, w4, w5;

  asm volatile("lw %0, 0(%6)\n"
               "lw %1, 4(%6)\n"
               "lw %2, 8(%6)\n"
               "lw %3, 12(%6)\n"
               "lw %4, 16(%6)\n"
               "lw %5, 20(%6)\n"
               : "=r"(w0), "=r"(w1), "=r"(w2), "=r"(w3), "=r"(w4), "=r"(w5)
               : "r"(base)
               : "memory");

  uint32_t words[6];

  words[0] = w0;
  words[1] = w1;
  words[2] = w2;
  words[3] = w3;
  words[4] = w4;
  words[5] = w5;

  req_t req;
  memcpy(&req, words, sizeof(req));

  return req;
}

static void write_rsp(rsp_t rsp) {
  volatile uint32_t *base = (volatile uint32_t *)PERIPH;
  uint32_t word = 0;

  memcpy(&word, &rsp, sizeof(rsp));

  asm volatile("sw %0, 0(%1)\n" : : "r"(word), "r"(base) : "memory");
}

int main() {
  hawkeye(1, 0, 0, 0, 0, 0);

  while (1) {
    req_t req = read_req();
    rsp_t rsp = {0};
    rsp.victimWay =
        hawkeye(req.init, req.paddr, req.set, req.pc, req.way, req.hit);
    write_rsp(rsp);
  }
}
