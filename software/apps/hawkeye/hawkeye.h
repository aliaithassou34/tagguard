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

/*
 * Hawkeye with Belady's Algorithm Replacement Policy
 * Header-only implementation for Hawkeye configurations of 1 and 2
 * in ChampSim.
 */

#ifndef HAWKEYE_H
#define HAWKEYE_H

#include <stdbool.h>
#include <stdint.h>
#include <string.h>

#define NUM_CORE 1
#define LLC_SETS (NUM_CORE * 1024)
#define LLC_WAYS 8
#define MAX_PCMAP 31
#define PCMAP_SIZE 1024
#define SAMPLER_ENTRIES 2800
#define SAMPLER_HIST 8
#define SAMPLER_SETS 350 /* SAMPLER_ENTRIES / SAMPLER_HIST */
#define TIMER_SIZE 1024
#define MAXRRIP 7
#define OPTGEN_SIZE 128
#define OPTGEN_CACHE_SIZE 6

typedef struct {
  uint16_t live[OPTGEN_SIZE];
  uint16_t numCache;
  uint16_t accessCount;
} OPTgen;

typedef struct {
  uint32_t pc;
  uint16_t previous;
  uint8_t tag;
  uint8_t lru;
  uint8_t valid;
} SamplerEntry;

typedef struct {
  uint8_t rrip[LLC_SETS][LLC_WAYS];
  uint16_t timer[LLC_SETS];
  uint8_t pcMap[PCMAP_SIZE];
  OPTgen optgen[LLC_SETS];
  uint32_t signature[LLC_SETS][LLC_WAYS];
  SamplerEntry sampler[SAMPLER_SETS][LLC_WAYS];
} Hawkeye;

static uint64_t bitMask(uint64_t len) {
  if (len >= 64) {
    return UINT64_MAX;
  }
  return (UINT64_C(1) << len) - UINT64_C(1);
}

static uint64_t bits(uint64_t val, uint64_t idx, uint64_t len) {
  return (val >> idx) & bitMask(len);
}

static uint64_t log2U64(uint64_t val) {
  uint64_t res = 0;
  while (val >>= 1) {
    ++res;
  }
  return res;
}

static int isSampledSet(uint32_t set) {
  return bits(set, 0, 6) == bits(set, log2U64(LLC_SETS) - 6, 6);
}

static uint32_t crc32(uint32_t address) {
  const uint32_t crc_polynomial = 0xEDB88320U;
  uint32_t result = address;

  for (uint32_t i = 0; i < 32; i++) {
    if (result & 1U) {
      result = (result >> 1) ^ crc_polynomial;
    } else {
      result >>= 1;
    }
  }

  return result;
}

static uint32_t modulo(uint64_t a, int b) {
  if (b == 0) {
    return 0;
  }

  /* Simple, well-defined modulo */
  return (uint32_t)(a % (uint64_t)b);
}

static bool HawkeyeIsCache(Hawkeye *h, uint32_t val, uint32_t endVal,
                           uint32_t cacheSize, uint32_t set) {
  bool cache = true;

  if (endVal < val) {
    for (uint32_t i = endVal; i < val; i++) {
      if (h->optgen[set].live[i] >= cacheSize) {
        cache = false;
      }
    }
  } else {
    for (uint32_t i = endVal; i < OPTGEN_SIZE; i++) {
      if (h->optgen[set].live[i] >= cacheSize) {
        cache = false;
      }
    }
    for (uint32_t i = 0; i < val; i++) {
      if (h->optgen[set].live[i] >= cacheSize) {
        cache = false;
      }
    }
  }

  if (cache) {
    if (endVal < val) {
      for (uint32_t i = endVal; i < val; i++) {
        h->optgen[set].live[i]++;
      }
    } else {
      for (uint32_t i = endVal; i < OPTGEN_SIZE; i++) {
        h->optgen[set].live[i]++;
      }
      for (uint32_t i = 0; i < val; i++) {
        h->optgen[set].live[i]++;
      }
    }
    h->optgen[set].numCache++;
  }

  return cache;
}

static void HawkeyeUpdateHistory(Hawkeye *h, uint32_t sampleSet,
                                 uint32_t curVal) {
  for (int i = 0; i < LLC_WAYS; i++) {
    if (h->sampler[sampleSet][i].lru < curVal) {
      h->sampler[sampleSet][i].lru++;
    }
  }
}

static void HawkeyeInit(Hawkeye *h) {
  memset(h, 0, sizeof(Hawkeye));

  for (int i = 0; i < PCMAP_SIZE; i++) {
    h->pcMap[i] = (MAX_PCMAP + 1) / 2;
  }

  for (int i = 0; i < LLC_SETS; i++) {
    for (int j = 0; j < LLC_WAYS; j++) {
      h->rrip[i][j] = MAXRRIP;
    }
  }
}

static uint8_t HawkeyeGetVictim(Hawkeye *h, uint32_t set, uint8_t way,
                                uint8_t hit) {
  int victim = -1;

  if (hit) {
    victim = way;
  } else {
    bool hasMaxRrip = false;

    /* Find a line with RRPV == MAXRRIP */
    for (uint8_t i = 0; i < LLC_WAYS; i++) {
      if (h->rrip[set][i] == MAXRRIP) {
        if (!hasMaxRrip) {
          victim = (int)i;
          hasMaxRrip = true;
        }
      }
    }

    if (!hasMaxRrip) {
      /* No RRPV == MAXRRIP; use oldest cache-friendly line */
      uint8_t maxRrpv = 0;

      for (uint8_t i = 0; i < LLC_WAYS; i++) {
        if (h->rrip[set][i] >= maxRrpv) {
          maxRrpv = h->rrip[set][i];
          victim = (int)i;
        }
      }

      if (isSampledSet(set) && victim != -1) {
        uint32_t idx = crc32(h->signature[set][(uint8_t)victim]) % PCMAP_SIZE;

        if (h->pcMap[idx] != 0) {
          h->pcMap[idx]--;
        } else {
          h->pcMap[idx] = 0;
        }
      }
    }
  }

  return (uint8_t)victim;
}

static void HawkeyeUpdate(Hawkeye *h, uint32_t set, uint8_t wayU,
                          uint64_t paddr, uint64_t pc, uint8_t hit) {
  if (pc == 0) {
    return;
  }

  uint8_t way = wayU;

  /* Block-align the physical address */
  paddr = (paddr >> 6) << 6;

  if (isSampledSet(set)) {
    uint32_t curVal = h->timer[set] % OPTGEN_SIZE;
    uint64_t sampleTag = crc32(paddr >> 12) % 256;
    uint32_t sampleSet = modulo(paddr >> 6, SAMPLER_SETS);

    bool found = false;

    for (uint8_t i = 0; i < LLC_WAYS; i++) {
      if (h->sampler[sampleSet][i].tag == sampleTag) {
        found = true;
        way = i;
      }
    }

    if (found) {
      uint32_t curTime = h->timer[set];

      if (curTime < h->sampler[sampleSet][way].previous) {
        curTime += TIMER_SIZE;
      }

      uint32_t prevVal = h->sampler[sampleSet][way].previous % OPTGEN_SIZE;

      bool isWrap =
          (curTime - h->sampler[sampleSet][way].previous) > OPTGEN_SIZE;

      bool cache = HawkeyeIsCache(h, curVal, prevVal, OPTGEN_CACHE_SIZE, set);

      uint32_t idx = crc32(h->sampler[sampleSet][way].pc) % PCMAP_SIZE;

      if (!isWrap && cache) {
        if (h->pcMap[idx] < MAX_PCMAP) {
          h->pcMap[idx]++;
        } else {
          h->pcMap[idx] = MAX_PCMAP;
        }
      } else {
        if (h->pcMap[idx] != 0) {
          h->pcMap[idx]--;
        } else {
          h->pcMap[idx] = 0;
        }
      }

      h->optgen[set].accessCount++;
      h->optgen[set].live[curVal] = 0;

      HawkeyeUpdateHistory(h, sampleSet, h->sampler[sampleSet][way].lru);
    } else {
      bool cacheFull = true;

      for (uint8_t i = 0; i < LLC_WAYS; i++) {
        if (!h->sampler[sampleSet][i].valid && cacheFull) {
          h->sampler[sampleSet][i].valid = true;
          h->sampler[sampleSet][i].pc = pc;
          h->sampler[sampleSet][i].previous = 0;
          h->sampler[sampleSet][i].lru = 0;
          h->sampler[sampleSet][i].tag = sampleTag;
          way = i;
          cacheFull = false;
        }
      }

      if (cacheFull) {
        for (uint8_t i = 0; i < LLC_WAYS; i++) {
          if (h->sampler[sampleSet][i].lru == (SAMPLER_HIST - 1)) {
            h->sampler[sampleSet][i].valid = true;
            h->sampler[sampleSet][i].pc = pc;
            h->sampler[sampleSet][i].previous = 0;
            h->sampler[sampleSet][i].lru = 0;
            h->sampler[sampleSet][i].tag = sampleTag;
          }
        }
      }

      h->optgen[set].accessCount++;
      h->optgen[set].live[curVal] = 0;

      HawkeyeUpdateHistory(h, sampleSet, SAMPLER_HIST - 1);
    }

    h->sampler[sampleSet][way].previous = h->timer[set];
    h->sampler[sampleSet][way].pc = pc;
    h->sampler[sampleSet][way].lru = 0;

    h->timer[set] = (uint16_t)((h->timer[set] + 1) % TIMER_SIZE);
  }

  uint32_t idx = crc32(pc) % PCMAP_SIZE;
  bool prediction = (h->pcMap[idx] >= ((MAX_PCMAP + 1) / 2));

  h->signature[set][wayU] = pc;

  if (!prediction) {
    /* Cache-averse: push to tail */
    h->rrip[set][wayU] = MAXRRIP;
  } else {
    /* Cache-friendly */
    h->rrip[set][wayU] = 0;

    if (!hit) {
      uint8_t hasMaxVal = 0;

      for (uint32_t i = 0; i < LLC_WAYS; i++) {
        if (h->rrip[set][i] == (MAXRRIP - 1)) {
          hasMaxVal = 1;
        }
      }

      if (!hasMaxVal) {
        for (uint32_t i = 0; i < LLC_WAYS; i++) {
          if (h->rrip[set][i] < (MAXRRIP - 1)) {
            h->rrip[set][i]++;
          }
        }
      }
    }

    h->rrip[set][wayU] = 0;
  }
}

static uint8_t hawkeye(bool init, uint64_t paddr, uint32_t set, uint64_t pc,
                       uint8_t way, uint8_t hit) {
  static Hawkeye *h;

  if (init) {
    if (h != NULL)
      free(h);
    h = malloc(sizeof(Hawkeye));
    HawkeyeInit(h);
    return 0;
  }

  uint8_t victimWay = HawkeyeGetVictim(h, set, way, hit);
  HawkeyeUpdate(h, set, way, paddr, pc, hit);
  return victimWay;
}

#endif /* HAWKEYE_H */
