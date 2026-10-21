# TagGuard — Peripheral-to-Pipeline Hardware DIFT for Bare-Metal RISC-V

Artifact of the paper *"TagGuard: Peripheral-to-Pipeline Hardware DIFT for
Bare-Metal RISC-V"* (DSD 2026). TagGuard adds end-to-end hardware Dynamic
Information Flow Tracking to the [ADAM](https://gite.lirmm.fr/adac/adam/)
RISC-V SoC.

## Repository layout

```
rtl/                     SoC RTL (fabric, syscfg, memory, I/O security unit)
patches/                 DIFT patches applied to the cv32e40p and axi submodules
bhv/adam_dift_tb.sv      DIFT testbench
software/lib/DIFTBoot/   Trusted startup: boot config, trap handler, trusted table
software/apps/           Attack reproducers (dift_cwe_*_cots, dift_mmio_guard) and benchmarks
cmake/adam_targets/      Build targets (nexys_video_<name>)
scripts/                 run_cots_whitelist_suite.sh (attack suite)
docs/                    Documentation and tutorials
```

## Setup

Requires Docker, Questa (simulation) and Vivado (FPGA, the paper used 2025.2).

```bash
git clone https://github.com/aliaithassou34/tagguard.git
cd tagguard

export ADAM_QUESTA_PATH=/opt/questa     # contains bin/vsim
export ADAM_XILINX_PATH=/tools/Xilinx   # contains <version>/Vivado/bin

./docker.sh --build    # first time: builds the image (long) and enters it
# next times: ./docker.sh
```

Inside the container (`(adam) /adam $`), set the simulator license:

```bash
export SALT_LICENSE_SERVER=<port>@<server>
```

Submodules are fetched and patched automatically by the first build.

## Build an app

```bash
adam build --dirty --targets nexys_video --software-targets hello_world
# -> work/build/targets/nexys_video/software/build/apps/hello_world/hello_world.elf
```

## Reproducing the paper results

### Attack coverage — 16 exploits, 15 CWEs (Table VII)

```bash
./scripts/run_cots_whitelist_suite.sh
```

Runs every attack in simulation and prints a pass/fail summary. A single case:

```bash
adam run vunit --target nexys_video_cwe_121_rop_cots --top adam_dift_tb.dift_cwe_121_rop_cots
```

Each case pairs target `nexys_video_<name>` with test `adam_dift_tb.dift_<name>`
(e.g. `cwe_120_bss_cots`); attack #16 is `nexys_video_dift_mmio_guard` /
`adam_dift_tb.dift_mmio_guard`. Add `-g` to open the waveforms.

### Hardware overhead (Table V)

```bash
adam build --dirty --targets nexys_video      --enable-vivado  # base
adam build --dirty --targets nexys_video_dift --enable-vivado  # TagGuard
```

Reports: `work/build/targets/<target>/vivado/adam.runs/impl_1/*_utilization_placed.rpt`
and `*_timing_summary_routed.rpt`.

## Documentation

ADAM tutorials (setup, simulation, FPGA, software) are in [`docs/`](docs/).

## Citation

```bibtex
@inproceedings{tagguard2026,
  author    = {Ait Hassou, Ali and Pensec, William and Bruguier, Florent and Benoit, Pascal},
  title     = {{TagGuard}: Peripheral-to-Pipeline Hardware {DIFT} for Bare-Metal {RISC-V}},
  booktitle = {Euromicro Conference on Digital System Design (DSD)},
  year      = {2026},
}
```

Supported by the French ANR grant SCREAM (ANR-24-CE39-0199-02).
