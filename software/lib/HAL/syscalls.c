// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <errno.h>
#include <stdint.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <unistd.h>

#include "adam_ral.h"

#define UNUSED __attribute__((unused))

void *_sbrk(int nbytes) {
  extern char __heap_start, __heap_end;
  static char *heap_ptr = &__heap_start;

  if (nbytes < 0 || (heap_ptr + nbytes > &__heap_end)) {
    errno = ENOMEM;
    return (void *)-1;
  }

  void *base = heap_ptr;
  heap_ptr += nbytes;
  return base;
}

int _read(int file, char *ptr, int len) {
  if (file != STDIN_FILENO) {
    errno = EBADF;
    return -1;
  }
    if (len <= 0 || ptr == NULL) {
    if (ptr == NULL)
      errno = EFAULT;
    return (len < 0) ? 0 : -1;
  }

  for (int i = 0; i < len; i++) {
    while (!RAL.LSPA.UART[0]->RBF)
      ;
    ptr[i] = RAL.LSPA.UART[0]->DR;

    // Return early on newline so scanf/fgets work line-by-line
    if (ptr[i] == '\n' || ptr[i] == '\r')
      return i + 1;
  }

  return len;
}


int _write(int file, char *buf, int nbytes) {
  if (file != STDOUT_FILENO && file != STDERR_FILENO) {
    errno = EBADF;
    return -1;
  }
  if (nbytes <= 0 || buf == NULL) {
    if (buf == NULL)
      errno = EFAULT;
    return (nbytes < 0) ? 0 : -1;
  }

  for (int i = 0; i < nbytes; i++) {
    while (!RAL.LSPA.UART[0]->TBE)
      ;
    RAL.LSPA.UART[0]->DR = *buf++;
  }

  return nbytes;
}

int _open(const char *path UNUSED, int flags UNUSED, int mode UNUSED) {
  errno = ENOSYS;
  return -1;
}

int _close(int file UNUSED) {
  errno = ENOSYS;
  return -1;
}

int _lseek(int file UNUSED, int offset UNUSED, int whence UNUSED) {
  errno = ENOSYS;
  return -1;
}

int _fstat(int file, struct stat *st) {
  if (file == STDOUT_FILENO || file == STDERR_FILENO) {
    st->st_mode = S_IFCHR;
  } else {
    st->st_mode = S_IFREG;
  }
  return 0;
}

int _isatty(int file) {
  return (file == STDOUT_FILENO || file == STDERR_FILENO);
}

int _getpid(void) { return 0; }

int _kill(int pid UNUSED, int sig UNUSED) { return 0; }

int _gettimeofday(struct timeval *tp, void *tzp UNUSED) {
  if (tp) {
    tp->tv_sec = 0;
    tp->tv_usec = 0;
  }
  return 0;
}
