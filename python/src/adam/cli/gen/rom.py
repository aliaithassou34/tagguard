import inspect
from argparse import ArgumentParser, Namespace, RawDescriptionHelpFormatter
from typing import Sequence

from adam.cli.util import add_output_argument
from adam.gen.rom import gen_rom


def configure_parser(parser: ArgumentParser) -> ArgumentParser:

    doc = inspect.getdoc(__import__(__name__)) or ""
    parser.description = doc
    parser.help = doc
    parser.formatter_class = RawDescriptionHelpFormatter

    parser.add_argument(
        "input",
        type=str,
        help="Input ELF file."
    )

    add_output_argument(parser)

    parser.add_argument(
        "-f", "--format",
        type=str,
        required=True,
        help="Output file format."
    )

    parser.add_argument(
        "-m", "--module-name",
        type=str,
        required=False,
        default='rom',
        help='Module name (sverilog)'
    )

    return parser


def main(args: Namespace | Sequence[str] | None = None) -> int:

    if isinstance(args, Namespace):
        ns = args
    else:
        parser = ArgumentParser()
        configure_parser(parser)
        ns = parser.parse_args(args)

    gen_rom(ns.input, ns.output, ns.format, ns.module_name)

    return 0
