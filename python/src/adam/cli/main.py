import inspect
from argparse import ArgumentParser, Namespace, RawDescriptionHelpFormatter
from typing import Sequence

from .build import (
    configure_parser as configure_build_parser,
    main as build_main
)
from .run.main import (
    configure_parser as configure_run_parser,
    main as run_main
)
from .gen.main import (
    configure_parser as configure_gen_parser,
    main as gen_main
)


def configure_parser(parser: ArgumentParser) -> ArgumentParser:

    doc = inspect.getdoc(__import__(__name__)) or ""
    parser.description = doc
    parser.help = doc
    parser.formatter_class = RawDescriptionHelpFormatter

    subparsers = parser.add_subparsers(
        dest="command",
        required=True,
        metavar="COMMAND"
    )

    configure_build_parser(subparsers.add_parser("build"))
    configure_run_parser(subparsers.add_parser("run"))
    configure_gen_parser(subparsers.add_parser("gen"))

    return parser


def main(args: Namespace | Sequence[str] | None = None) -> int:

    if isinstance(args, Namespace):
        ns = args
    else:
        parser = ArgumentParser()
        configure_parser(parser)
        ns = parser.parse_args(args)

    ret = 0

    if ns.command == "build":
        ret = build_main(ns)
    elif ns.command == "run":
        ret = run_main(ns)
    elif ns.command == "gen":
        ret = gen_main(ns)
    else:
        parser.print_help()

    exit(ret)
    return ret
