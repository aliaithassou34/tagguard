import inspect
from argparse import ArgumentParser, Namespace, RawDescriptionHelpFormatter
from typing import Sequence

from .cfg import (
    configure_parser as configure_cfg_parser,
    main as cfg_main
)
from .ldscript import (
    configure_parser as configure_ldscript_parser,
    main as ldscript_main
)
from .pkg import (
    configure_parser as configure_pkg_parser,
    main as pkg_main
)
from .ral import (
    configure_parser as configure_ral_parser,
    main as ral_main
)
from .rom import (
    configure_parser as configure_rom_parser,
    main as rom_main
)
from .vivado import (
    configure_parser as configure_vivado_parser,
    main as vivado_main
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
        dest="gen_command",
        required=True,
        metavar="COMMAND"
    )

    configure_cfg_parser(subparsers.add_parser("cfg"))
    configure_ldscript_parser(subparsers.add_parser("ldscript"))
    configure_pkg_parser(subparsers.add_parser("pkg"))
    configure_ral_parser(subparsers.add_parser("ral"))
    configure_rom_parser(subparsers.add_parser("rom"))
    configure_vivado_parser(subparsers.add_parser("vivado"))
    configure_vunit_parser(subparsers.add_parser("vunit"))

    return parser


def main(args: Namespace | Sequence[str] | None = None) -> int:

    if isinstance(args, Namespace):
        ns = args
    else:
        parser = ArgumentParser()
        configure_parser(parser)
        ns = parser.parse_args(args)

    if ns.gen_command == "cfg":
        cfg_main(ns)
    elif ns.gen_command == "ldscript":
        ldscript_main(ns)
    elif ns.gen_command == "pkg":
        pkg_main(ns)
    elif ns.gen_command == "ral":
        ral_main(ns)
    elif ns.gen_command == "rom":
        rom_main(ns)
    elif ns.gen_command == "vivado":
        vivado_main(ns)
    elif ns.gen_command == "vunit":
        vunit_main(ns)
    else:
        parser.print_help()

    return 0
