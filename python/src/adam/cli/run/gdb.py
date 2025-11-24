import inspect
from argparse import ArgumentParser, Namespace, RawDescriptionHelpFormatter
from pathlib import Path
from typing import Sequence

from adam.run.gdb import run_gdb


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
        "--emulate",
        action="store_true",
        help="Use emulator."
    )

    parser.add_argument(
        "--batch",
        action="store_true",
        help="Run in batch mode."
    )

    parser.add_argument(
        "--semihost",
        action="store_true",
        help="Automatically start semihosting"
    )

    parser.add_argument(
        "--isa",
        default="rv32imfc_zicsr",
        help="RISC-V ISA string to pass to Spike (default: %(default)s)."
    )

    parser.add_argument(
        "--spike-exe",
        dest="spike_path",
        type=Path,
        help="Path to the Spike executable (defaults to finding it on PATH)."
    )

    parser.add_argument(
        "--openocd-exe",
        dest="openocd_path",
        type=Path,
        help="Path to the OpenOCD executable (defaults to finding it on PATH)."
    )

    parser.add_argument(
        "--gdb-exe",
        dest="gdb_path",
        type=Path,
        help="Path to the GDB executable (defaults to finding it on PATH)."
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
        return run_gdb(
            elf_path=ns.elf_path,
            emulate=ns.emulate,
            batch=ns.batch,
            semihost=ns.semihost,
            isa=ns.isa,
            spike_path=ns.spike_path,
            openocd_path=ns.openocd_path,
            gdb_path=ns.gdb_path,
        )

    except KeyboardInterrupt:
        print("\nInterrupted. Exiting.")
        return 130
