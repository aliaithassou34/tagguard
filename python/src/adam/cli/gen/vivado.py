import inspect
from argparse import ArgumentParser, Namespace, RawDescriptionHelpFormatter
from pathlib import Path
from typing import Sequence
from adam.cli.library import add_library_args, parse_library_args
from adam.cli.util import (
    CompilerStyleCollect,
    add_jobs_argument,
    add_source_argument,
    add_output_argument
)
from adam.gen.vivado import gen_vivado


def configure_parser(parser: ArgumentParser) -> ArgumentParser:

    doc = inspect.getdoc(__import__(__name__)) or ""
    parser.description = doc
    parser.help = doc
    parser.formatter_class = RawDescriptionHelpFormatter

    add_source_argument(parser)

    parser.add_argument(
        "--part",
        required=True,
        help="FPGA device/part (e.g., xc7a35tcpg236-1).",
    )

    parser.add_argument(
        "--top",
        required=True,
        help="Top module name.",
    )

    add_jobs_argument(parser)

    add_library_args(parser)

    parser.add_argument(
        "-X",
        dest="constrs",
        action=CompilerStyleCollect,
        default=[],
        metavar="XDC",
        help="Constraint xdc file (repeatable).",
        nargs=1,
    )

    add_output_argument(parser)

    return parser


def main(args: Namespace | Sequence[str] | None = None) -> int:

    if isinstance(args, Namespace):
        ns = args
    else:
        parser = ArgumentParser()
        configure_parser(parser)
        ns = parser.parse_args(args)

    library = parse_library_args(ns)

    constrs = [Path(x) for x in ns.constrs]

    gen_vivado(
        part=ns.part,
        top=ns.top,
        jobs=ns.jobs,
        library=library,
        constrs=constrs,
        source_path=ns.source,
        output_file=ns.output
    )

    return 0
