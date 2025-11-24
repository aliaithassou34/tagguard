import inspect
from argparse import ArgumentParser, Namespace, RawDescriptionHelpFormatter
from typing import Sequence

from .fpga import (
    configure_parser as configure_fpga_parser,
    main as fpga_main
)
from .gdb import (
    configure_parser as configure_gdb_parser,
    main as gdb_main
)
from .vunit import (
    configure_parser as configure_vunit_parser,
    main as vunit_main
)


def configure_parser(parser: ArgumentParser) -> ArgumentParser:

    doc = inspect.getdoc(__import__(__name__)) or ""
    parser.description = doc
    parser.help = doc
    parser.formatter_class = RawDescriptionHelpFormatter

    subparsers = parser.add_subparsers(
        dest="run_command",
        required=True,
        metavar="COMMAND"
    )

    configure_fpga_parser(subparsers.add_parser("fpga"))
    configure_gdb_parser(subparsers.add_parser("gdb"))
    configure_vunit_parser(subparsers.add_parser("vunit"))

    return parser


def main(args: Namespace | Sequence[str] | None = None) -> int:

    if isinstance(args, Namespace):
        ns = args
    else:
        parser = ArgumentParser()
        configure_parser(parser)
        ns = parser.parse_args(args)

    ret = 0

    if ns.run_command == "fpga":
        ret = fpga_main(ns)
    elif ns.run_command == "gdb":
        ret = gdb_main(ns)
    elif ns.run_command == "vunit":
        ret = vunit_main(ns)
    else:
        parser.print_help()

    return ret
