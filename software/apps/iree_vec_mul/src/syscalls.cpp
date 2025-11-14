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

#include <stdlib.h>
#include <errno.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdint.h>

void* __dso_handle = (void*) &__dso_handle;

extern "C" void* _sbrk(int nbytes) {
  extern char __heap_start, __heap_end;
  static char* ptr = &__heap_start;

  if (nbytes < 0 || (ptr + nbytes > &__heap_end)) {
    errno = ENOMEM;
    return (void*) -1;
  }

  void* base = ptr;
  ptr += nbytes;
  return base;
}

extern "C" int _read(int file, char* ptr, int len) {
  if (file != STDIN_FILENO) {
    errno = EBADF;
    return -1;
  }
  return 0;
}

extern "C" int _write(int file, char* buf, int nbytes) {
  if (file != STDOUT_FILENO && file != STDERR_FILENO) {
    errno = EBADF;
    return -1;
  }
  if (nbytes <= 0 || buf == nullptr) {
    if (buf == nullptr) errno = EFAULT;
    return (nbytes < 0) ? 0 : -1;
  }
  // Simply acknowledge bytes written without buffering
  return nbytes;
}

extern "C" int _close(int file) {
  errno = EBADF;
  return -1;
}

extern "C" int _lseek(int file, int offset, int whence) {
  if (file != STDOUT_FILENO && file != STDERR_FILENO) {
    errno = EBADF;
    return -1;
  }
  return 0;
}

extern "C" int _fstat(int file, struct stat* st) {
  if (file != STDOUT_FILENO && file != STDERR_FILENO) {
    errno = EBADF;
    return -1;
  }
  if (st == nullptr) {
    errno = EFAULT;
    return -1;
  }
  st->st_mode = S_IFCHR;
  return 0;
}

extern "C" int _isatty(int file) {
  if (file != STDOUT_FILENO && file != STDERR_FILENO) {
    errno = EBADF;
    return -1;
  }
  return 1;
}

void operator delete(void* p) noexcept {
  free(p);
}

extern "C" void operator delete(void* p, unsigned long) noexcept {
  operator delete(p);
}
