import inspect
from argparse import ArgumentParser, Namespace, RawDescriptionHelpFormatter
from subprocess import CalledProcessError
from typing import Sequence

from adam.build import build

from .util import (
    add_source_argument,
    add_build_argument,
    add_dirty_argument,
    add_bool_argument
)


def configure_parser(parser: ArgumentParser) -> ArgumentParser:

    doc = inspect.getdoc(__import__(__name__)) or ""
    parser.description = doc
    parser.help = doc
    parser.formatter_class = RawDescriptionHelpFormatter

    add_source_argument(parser)
    add_build_argument(parser)
    add_dirty_argument(parser)

    parser.add_argument(
        "--targets",
        nargs="*",
        help="Primary project build targets."
    )

    parser.add_argument(
        "--software-targets",
        nargs="*",
        default=[],
        help="Software project build targets."
    )

    for name in [
        "vunit", "verilator", "vivado", "vendorize", "tflm", "iree"
    ]:
        add_bool_argument(parser, f"--enable-{name}")

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
        build(
            source_dir=ns.source,
            build_dir=ns.build,
            targets=ns.targets,
            software_targets=ns.software_targets,
            enable_vunit=ns.enable_vunit,
            enable_verilator=ns.enable_verilator,
            enable_vivado=ns.enable_vivado,
            enable_vendorize=ns.enable_vendorize,
            enable_tflm=ns.enable_tflm,
            enable_iree=ns.enable_iree,
            dirty=ns.dirty
        )

    except KeyboardInterrupt:
        print("\nInterrupted. Exiting.")
        return 130

    except CalledProcessError:
        return 1

    return 0
