import inspect
from argparse import ArgumentParser, Namespace, RawDescriptionHelpFormatter
from typing import Sequence
from adam.gen.pkg import gen_pkg
from adam.cli.util import (
    add_cfg_argument,
    add_output_argument
)


def configure_parser(parser: ArgumentParser) -> ArgumentParser:

    doc = inspect.getdoc(__import__(__name__)) or ""
    parser.description = doc
    parser.help = doc
    parser.formatter_class = RawDescriptionHelpFormatter

    parser.add_argument(
        "-n", "--name",
        type=str,
        default="adam_cfg_pkg",
        help="SystemVerilog package name.",
    )

    add_cfg_argument(parser)
    add_output_argument(parser)

    return parser


def main(args: Namespace | Sequence[str] | None = None) -> int:

    if isinstance(args, Namespace):
        ns = args
    else:
        parser = ArgumentParser()
        configure_parser(parser)
        ns = parser.parse_args(args)

    gen_pkg(ns.cfg, ns.name, ns.output)

    return 0
