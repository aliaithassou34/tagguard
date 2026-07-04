# TagGuard — Peripheral-to-Pipeline Hardware DIFT for Bare-Metal RISC-V

This branch adds **TagGuard**, an end-to-end hardware Dynamic Information Flow
Tracking (DIFT) extension, to the [ADAM](https://gite.lirmm.fr/adac/adam/) RISC-V
SoC. It is the artifact accompanying the paper *"TagGuard: Peripheral-to-Pipeline
Hardware DIFT for Bare-Metal RISC-V"* (DSD 2026).


TagGuard tags untrusted bytes the moment they enter the SoC through a peripheral,
carries the tags through the interconnect and data memory, and checks them inside
the CV32E40P pipeline, with no software instrumentation of the application
firmware and no pipeline stalls. 

On a Xilinx Artix-7 it adds 2.52 % LUTs / 2.32 %
FFs and detects 16 bare-metal exploits across 15 CWEs with zero false positives on
the evaluated workloads.

## Architecture at a glance

TagGuard adds a tag path next to the normal datapath of the ADAM SoC:

| Component | What it does | Where |
|---|---|---|
| **I/O Security Unit** | Auto-tags peripheral reads (`DTSR`) and blocks tainted MMIO writes (`MPM`/`MPS`) | [`rtl/adam_dift_periph_guard.sv`](rtl/adam_dift_periph_guard.sv), [`rtl/syscfg/adam_syscfg.sv`](rtl/syscfg/adam_syscfg.sv) |
| **SoC-level tag transport** | Carries 4 byte-lane tags on the AXI4-Lite `user` sideband | [`patches/axi/0002-Add-AXI-Lite-user-signal-support.patch`](patches/axi/0002-Add-AXI-Lite-user-signal-support.patch), [`rtl/fabric/adam_fabric.sv`](rtl/fabric/adam_fabric.sv) |
| **Per-byte memory tagging** | Stores 4 tag bits per 32-bit word (36-bit RAM) | [`rtl/adam_mem.sv`](rtl/adam_mem.sv) |
| **In-core DIFT (D-CV32E40P)** | Parallel tag register file, tag propagation (`TPR`) and checking (`TCR`) | [`patches/cv32e40p/0001-Add-DIFT-support.patch`](patches/cv32e40p/0001-Add-DIFT-support.patch) |
| **Trusted startup (DIFTBoot)** | Configures the policy and trusted-runtime table before `main`; runs unmodified firmware | [`software/lib/DIFTBoot/`](software/lib/DIFTBoot/) |

The evaluated policy is `TPR=0x0000A8A2`, `TCR=0x00200018` (branch + execute-PC
checks).

## Repository layout

```
rtl/                     SoC RTL (fabric, syscfg, memory, I/O security unit)
patches/                 DIFT patches applied to the cv32e40p and axi submodules
bhv/adam_dift_tb.sv      DIFT testbench (attack + false-positive cases)
software/lib/DIFTBoot/   Trusted startup: boot config, trap handler, trusted table
software/apps/           CWE COTS benchmarks + FP benchmarks
cmake/adam_targets/      Build targets
scripts/                 run_cots_whitelist_suite.sh (full CWE suite)
docs/                    Documentation and tutorials
```

## Setup

Everything runs inside the provided Docker environment. Simulation needs
**Questa/ModelSim**; FPGA bitstreams and area/timing reports need **Vivado**.
See [`docs/tutorials/setup.rst`](docs/tutorials/setup.rst) for the full guide.

```bash
git clone git@gite.lirmm.fr:adac/adam/adam.git
cd adam
git checkout dift-camera-ready

# Point at your tools
export ADAM_QUESTA_PATH=/opt/questa           # simulator
export ADAM_XILINX_PATH=/tools/Xilinx         # Vivado
export LM_LICENSE_FILE=<your-license>         # simulator license

./docker.sh --build      # build image + enter container (first time)
# later sessions: ./docker.sh
```

All commands below run inside the container (`(adam) /adam $` prompt).

## Build

```bash
# Compile app
adam build --targets nexys_video --software-targets hello_world \
  --enable-vunit false --enable-vivado false

# Generate an FPGA bitstream for a target
adam build --dirty --target nexys_video
# -> work/build/targets/nexys_video/vivado/bitstream.bit
```

## Reproducing the paper results

Detection and false-positive results are validated in simulation, where the DIFT
testbench ([`bhv/adam_dift_tb.sv`](bhv/adam_dift_tb.sv)) has full pipeline
visibility. Each case pairs a build target (`nexys_video_<name>`) with a testbench
case (`adam_dift_tb.<name>`). Add `-g` to any `adam run vunit` command to open the
waveforms in Questa.

### 1. Attack coverage — 16 exploits across 15 CWEs (Table VIII)

Run the whole CWE suite under the single boot-time COTS policy:

```bash
./scripts/run_cots_whitelist_suite.sh
```

Run a single CWE case:

```bash
adam run vunit --target nexys_video_cwe_121_rop_cots \
  --top adam_dift_tb.dift_cwe_121_rop_cots        # CWE-121 stack ROP, EXECUTE check
```

### 2. False positives — legitimate workloads (Table VIII, FP)

```bash
adam run vunit --target nexys_video_bench_cots_trusted_runtime \
  --top adam_dift_tb.bench_cots_trusted_runtime   # libc/allocator over tainted input
adam run vunit --target nexys_video_bench_uart_command_fp \
  --top adam_dift_tb.bench_uart_command_fp        # UART command parser
adam run vunit --target nexys_video_bench_uart_data_integrity \
  --top adam_dift_tb.bench_uart_data_integrity    # UART checksum
```

Each passes when it completes without an `ATTACK` status (trusted branches are
transparently resolved).

### 3. Hardware overhead (Table V)

Synthesize the base SoC and a DIFT-enabled SoC with Vivado, then compare the
post-implementation utilization/timing reports written under
`work/build/targets/<target>/vivado/`:

```bash
adam build --dirty --target nexys_video                  --enable-vivado true  # base
adam build --dirty --target nexys_video_cwe_121_rop_cots --enable-vivado true  # DIFT
```

## Documentation

Full tutorials (setup, simulation, FPGA, software/debug) are in [`docs/`](docs/)

## Citation

```bibtex
@inproceedings{tagguard2026,
  author    = {Ali Ait Hassou, William Pensec, Florent Bruguier, Pascal Benoit},
  title     = {{TagGuard}: Peripheral-to-Pipeline Hardware {DIFT} for Bare-Metal {RISC-V}},
  booktitle = {Euromicro Conference on Digital System Design (DSD)},
  year      = {2026},
}
```

## Acknowledgement

This work was supported by the French National Research Agency (ANR) through the
government grant SCREAM (ANR-24-CE39-0199-02).

