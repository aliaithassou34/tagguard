import inspect
from argparse import ArgumentParser, Namespace, RawDescriptionHelpFormatter
from pathlib import Path
from typing import Sequence

from adam.run.spike import run_spike


def configure_parser(parser: ArgumentParser) -> ArgumentParser:
    doc = inspect.getdoc(__import__(__name__)) or ""
    parser.description = doc
    parser.help = doc
    parser.formatter_class = RawDescriptionHelpFormatter

    parser.add_argument(
        "elf_path",
        type=Path,
        help="Path to the ELF to run under Spike."
    )

    parser.add_argument(
        "--isa",
        default="rv32imfc_zicsr",
        help="RISC-V ISA string to pass to Spike (default: %(default)s)."
    )

    parser.add_argument(
        "--rbb-port",
        type=int,
        default=None,
        help="Spike remote bit-bang (RBB) port."
    )

    parser.add_argument(
        "--gdb-port",
        type=int,
        default=None,
        help="OpenOCD GDB server port."
    )

    parser.add_argument(
        "--spike-exe",
        dest="spike_exe_path",
        type=Path,
        help="Path to the Spike executable (defaults to finding it on PATH)."
    )

    parser.add_argument(
        "--openocd-exe",
        dest="openocd_exe_path",
        type=Path,
        help="Path to the OpenOCD executable (defaults to finding it on PATH)."
    )

    parser.add_argument(
        "--gdb-exe",
        dest="gdb_exe_path",
        type=Path,
        help="Path to the GDB executable (defaults to finding it on PATH)."
    )

    parser.add_argument(
        "--spike-log",
        dest="spike_log_path",
        type=Path,
        help="Write Spike output to this file."
    )

    parser.add_argument(
        "--openocd-log",
        dest="openocd_log_path",
        type=Path,
        help="Write OpenOCD output to this file."
    )

    parser.add_argument(
        "--spike-arg",
        dest="spike_args",
        action="append",
        default=[],
        help="Additional argument to pass to Spike (repeatable)."
    )
    parser.add_argument(
        "--openocd-arg",
        dest="openocd_args",
        action="append",
        default=[],
        help="Additional argument to pass to OpenOCD (repeatable)."
    )
    parser.add_argument(
        "--gdb-arg",
        dest="gdb_args",
        action="append",
        default=[],
        help="Additional argument to pass to GDB (repeatable)."
    )

    return parser


def main(args: Namespace | Sequence[str] | None = None) -> int:
    if isinstance(args, Namespace):
        ns = args
    else:
        parser = ArgumentParser()
        configure_parser(parser)
        ns = parser.parse_args(args)

    try:
        run_spike(
            elf_path=ns.elf_path,
            isa=ns.isa,
            rbb_port=ns.rbb_port,
            gdb_port=ns.gdb_port,
            spike_args=tuple(ns.spike_args) if ns.spike_args else (),
            spike_exe_path=ns.spike_exe_path,
            spike_log_path=ns.spike_log_path,
            openocd_args=tuple(ns.openocd_args) if ns.openocd_args else (),
            openocd_exe_path=ns.openocd_exe_path,
            openocd_log_path=ns.openocd_log_path,
            gdb_exe_path=ns.gdb_exe_path,
            gdb_args=tuple(ns.gdb_args) if ns.gdb_args else (),
        )
        return 0

    except KeyboardInterrupt:
        print("\nInterrupted. Exiting.")
        return 130
