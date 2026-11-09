# TagGuard

Hardware DIFT for bare-metal RISC-V. This is the code of the DSD 2026 paper
*TagGuard: Peripheral-to-Pipeline Hardware DIFT for Bare-Metal RISC-V*.

TagGuard tags the data that comes from peripherals in hardware, carries the tags
through the bus and memory of the [ADAM](https://gite.lirmm.fr/adac/adam/) SoC,
and stops the CV32E40P core when tagged data reaches a branch, a jump target or
a protected peripheral register.

## Setup

You need Docker and Questa. Vivado is only needed for the area results.

```bash
git clone https://github.com/aliaithassou34/tagguard.git
cd tagguard
export ADAM_QUESTA_PATH=/path/to/questa   # the folder with bin/vsim
./docker.sh --build                       # first time only, then: ./docker.sh
```

## Reproduce the paper

**Attacks** (16 exploits, 15 CWEs):

```bash
./scripts/run_cots_whitelist_suite.sh
```

It ends with `Summary: 16/16 passed`. The first run builds everything, so it
takes longer.

**Area** (set `ADAM_XILINX_PATH` to your Xilinx folder before `./docker.sh`):

```bash
adam build --dirty --targets nexys_video      --enable-vivado   # without TagGuard
adam build --dirty --targets nexys_video_dift --enable-vivado   # with TagGuard
```

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
