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

#include <stdio.h>

#include "CppUTest/CommandLineTestRunner.h"

static char stdout_buffer[4096];

int main() {
  setvbuf(stdout, stdout_buffer, _IOLBF, sizeof(stdout_buffer));

  const char *args[] = {"", "-v", "-c"};
  return CommandLineTestRunner::RunAllTests(3, const_cast<char **>(args));
}
