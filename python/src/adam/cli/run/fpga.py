import inspect
from argparse import ArgumentParser, Namespace, RawDescriptionHelpFormatter
from pathlib import Path
from typing import Sequence

from adam.run.fpga import run_fpga


def configure_parser(parser: ArgumentParser) -> ArgumentParser:
    doc = inspect.getdoc(__import__(__name__)) or ""
    parser.description = doc
    parser.help = doc
    parser.formatter_class = RawDescriptionHelpFormatter

    parser.add_argument(
        "-b", "--bitstream",
        required=True,
        type=Path,
        help="Path to the FPGA bitstream file (.bit)."
    )

    parser.add_argument(
        "-d", "--device",
        default="",
        help="Target JTAG device."
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
        run_fpga(
            bitstream=ns.bitstream,
            device=ns.device,
        )

    except KeyboardInterrupt:
        print("\nInterrupted. Exiting.")
        return 130

    return 0
