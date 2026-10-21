#!/usr/bin/env bash

# Attack coverage suite (paper Table VII): attacks #1-#15 run under the
# single boot-time COTS policy, attack #16 exercises the MMIO write guard.

set -uo pipefail

cases=(
  cwe_119_oob_index_cots
  cwe_120_bss_cots
  cwe_121_rop_cots
  cwe_121_var_ovf_cots
  cwe_122_heap_cots
  cwe_125_oob_read_cots
  cwe_134_fmt_cots
  cwe_190_intovf_cots
  cwe_193_offbyone_err_cots
  cwe_415_double_free_cots
  cwe_416_use_after_free_cots
  cwe_476_null_deref_cots
  cwe_676_dangerous_strcpy_cots
  cwe_787_funcptr_cots
  cwe_824_uninit_ptr_cots
  dift_mmio_guard
)

passed=()
failed=()

for c in "${cases[@]}"; do
  echo "==> ${c}"
  if adam run vunit --target "nexys_video_${c}" --top "adam_dift_tb.dift_${c#dift_}"; then
    passed+=("${c}")
  else
    failed+=("${c}")
  fi
done

echo
echo "==> Summary: ${#passed[@]}/${#cases[@]} passed"
for c in "${failed[@]}"; do
  echo "    FAIL ${c}"
done

[ ${#failed[@]} -eq 0 ]
