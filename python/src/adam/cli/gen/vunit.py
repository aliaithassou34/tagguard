import inspect
from argparse import ArgumentParser, Namespace, RawDescriptionHelpFormatter
from typing import Sequence
from adam.cli.library import add_library_args, parse_library_args
from adam.cli.util import add_source_argument, add_output_argument
from adam.gen.vunit import gen_vunit


def configure_parser(parser: ArgumentParser) -> ArgumentParser:

    doc = inspect.getdoc(__import__(__name__)) or ""
    parser.description = doc
    parser.help = doc
    parser.formatter_class = RawDescriptionHelpFormatter

    add_library_args(parser)
    add_source_argument(parser)
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

    if ns.source is None:
        raise ValueError("Missing required argument: -S, --source")

    gen_vunit(
        library=library,
        source_path=ns.source,
        output_file=ns.output
    )

    return 0
