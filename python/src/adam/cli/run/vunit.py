import inspect
from argparse import ArgumentParser, Namespace, RawDescriptionHelpFormatter
from typing import Sequence


from adam.cli.util import (
    add_source_argument,
    add_build_argument,
)
from adam.run.vunit import run_vunit


def configure_parser(parser: ArgumentParser) -> ArgumentParser:

    doc = inspect.getdoc(__import__(__name__)) or ""
    parser.description = doc
    parser.help = doc
    parser.formatter_class = RawDescriptionHelpFormatter

    parser.add_argument(
        "--target",
        help="Project build target."
    )

    parser.add_argument(
        "--top",
        required=True,
        help="Top module."
    )

    parser.add_argument(
        "-g", "--gui",
        action="store_true",
        help="Enable graphical user interface."
    )

    add_source_argument(parser)
    add_build_argument(parser)

    return parser


def main(args: Namespace | Sequence[str] | None = None) -> int:

    if isinstance(args, Namespace):
        ns = args
    else:
        parser = ArgumentParser()
        configure_parser(parser)
        ns = parser.parse_args(args)

    if ns.source is None:
        raise ValueError("Missing required argument: -S, --source")

    try:
        run_vunit(
            target=ns.target,
            top=ns.top,
            gui=ns.gui,
            source_dir=ns.source,
            build_dir=ns.build
        )

    except KeyboardInterrupt:
        print("\nInterrupted. Exiting.")
        return 130

    return 0
