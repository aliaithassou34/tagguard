import subprocess
from pathlib import Path
from typing import Optional, Sequence

from jinja2 import Template

from adam.resources import open_resource
from adam.util import (
    PopenError,
    PopenWithCleanup,
    find_free_port,
    wait_for_port
)


def start_spike(
    elf_path: Path,
    rbb_port: Optional[int] = None,
    isa: str = "rv32imfc_zicsr",
    args: Sequence[str] = (),
    exe_path: Optional[Path] = None,
    log_path: Optional[Path] = None
) -> tuple[PopenWithCleanup, int]:

    if not elf_path.is_file():
        raise FileNotFoundError(f"File not found: '{elf_path}'")

    if rbb_port in (None, 0):
        rbb_port = find_free_port(9824)

    if exe_path is None:
        exe_path = "spike"

    cmd = [
        str(exe_path),
        "-m0x00000000:0x01000000,0x40000000:0x40000000",
        f"--rbb-port={rbb_port}",
        f"--isa={isa}",
        "--halted",
        str(elf_path),
        *args
    ]

    proc = PopenWithCleanup(cmd, log_path=log_path)

    try:
        wait_for_port("127.0.0.1", rbb_port)
    except TimeoutError:
        raise PopenError(proc)

    return proc, rbb_port


def start_openocd(
    rbb_port: int,
    gdb_port: Optional[int] = None,
    args: Sequence[str] = (),
    exe_path: Optional[Path] = None,
    log_path: Optional[Path] = None,
) -> tuple[PopenWithCleanup, int]:

    if exe_path is None:
        exe_path = "openocd"

    if gdb_port in (None, 0):
        gdb_port = find_free_port(3333)

    with open_resource("openocd/spike.cfg.j2", "r") as f:
        template = Template(f.read())

    cfg = template.render(
        rbb_port=rbb_port,
        gdb_port=gdb_port
    )

    cmd = [str(exe_path)]
    for line in cfg.splitlines():
        cmd += ["-c", line]
    cmd += args

    proc = PopenWithCleanup(cmd, log_path=log_path)

    try:
        wait_for_port("127.0.0.1", gdb_port)
    except TimeoutError:
        raise PopenError(proc)

    return proc, gdb_port


def run_gdb(
    elf_path: Path,
    gdb_port: int = 3333,
    args: Sequence[str] = (),
    exe_path: Optional[Path] = None
) -> None:

    if not elf_path.is_file():
        raise FileNotFoundError(f"Program '{elf_path}' not found.")

    if exe_path is None:
        exe_path = "riscv32-unknown-elf-gdb"

    cmd = [
        str(exe_path),
        str(elf_path),
        "-ex", f"target remote localhost:{gdb_port}",
        "-ex", "load",
        *args
    ]

    subprocess.run(cmd, text=True, check=True)


def run_spike(
    elf_path: Path,
    isa: str = "rv32imfc_zicsr",
    rbb_port: Optional[int] = None,
    gdb_port: Optional[int] = None,
    spike_args: Sequence[str] = (),
    spike_exe_path: Optional[Path] = None,
    spike_log_path: Optional[Path] = None,
    openocd_args: Sequence[str] = (),
    openocd_exe_path: Optional[Path] = None,
    openocd_log_path: Optional[Path] = None,
    gdb_exe_path: Optional[Path] = None,
    gdb_args: Sequence[str] = (),
) -> None:

    spike_proc, rbb_port = start_spike(
        elf_path,
        rbb_port,
        isa,
        spike_args,
        spike_exe_path,
        spike_log_path
    )

    openocd_proc, gdb_port = start_openocd(
        rbb_port,
        gdb_port,
        openocd_args,
        openocd_exe_path,
        openocd_log_path
    )

    run_gdb(
        elf_path,
        gdb_port,
        gdb_args,
        gdb_exe_path
    )

    spike_proc.cleanup()
    openocd_proc.cleanup()
