from pathlib import Path
from subprocess import DEVNULL
from adam.process import GdbProcess, OpenocdProcess, SpikeProcess
from adam.resources import get_resource_path


def run_gdb(
    elf_path: Path,
    emulate: bool = True,
    batch: bool = False,
    semihost: bool = False,
    isa: str = "rv32imfc_zicsr",
    spike_path: Path | None = None,
    openocd_path: Path | None = None,
    gdb_path: Path | None = None,
) -> int:

    if emulate:
        spike_proc = SpikeProcess(
            spike_path=spike_path,
            elf_path=elf_path,
            isa=isa,
            stdin=DEVNULL,
            stdout=DEVNULL
        )
        rbb_port = spike_proc.rbb_port
        cfg_path = get_resource_path("openocd/spike.cfg")
    else:
        rbb_port = None
        cfg_path = get_resource_path("openocd/hs2.cfg")

    openocd_proc = OpenocdProcess(
        openocd_path=openocd_path,
        cfg_path=cfg_path,
        rbb_port=rbb_port,
        stdin=DEVNULL,
        stdout=DEVNULL
    )
    gdb_port = openocd_proc.gdb_port

    proc = GdbProcess(
        gdb_path=gdb_path,
        gdb_port=gdb_port,
        elf_path=elf_path,
        batch=batch,
        semihost=semihost
    )
    proc.wait()
    return proc.returncode
