import inspect
from argparse import (
    ArgumentParser,
    ArgumentTypeError,
    Namespace,
    RawDescriptionHelpFormatter
)
from dataclasses import MISSING, fields
from typing import Sequence, get_origin

from adam.cfg import Cfg
from adam.cli.util import add_output_argument


def _cli_flag(name: str) -> str:
    return f"--{name.replace('_', '-')}"


def _parse_bool(s: str | bool) -> bool:
    """Parse common boolean values."""

    if isinstance(s, bool):
        return s

    s = str(s).strip().lower()

    if s in {"1", "true", "yes", "on"}:
        return True

    if s in {"0", "false", "no", "off"}:
        return False

    raise ArgumentTypeError(
        f"Invalid boolean value: {s!r} (expected one of: "
        "1/0, true/false, yes/no, on/off)"
    )


def _parse_int(s: str) -> int:
    """Parse an integer with base auto-detect (e.g., 42, 0x2a)."""
    return int(s, 0)


def _parse_int_list(s: str) -> list[int]:
    """Parse comma-separated integers, base auto-detected per token."""
    return [int(tok, 0) for tok in s.split(",") if tok.strip()]


def configure_parser(parser: ArgumentParser) -> None:

    doc = inspect.getdoc(__import__(__name__)) or ""
    parser.description = doc
    parser.help = doc
    parser.formatter_class = RawDescriptionHelpFormatter

    for f in fields(Cfg):
        flag = _cli_flag(f.name)
        default = f.default if f.default is not MISSING else None
        ftype = f.type

        if get_origin(ftype) is tuple:
            parser.add_argument(
                flag,
                type=_parse_int_list,
                default=default
            )

        elif ftype is bool:
            parser.add_argument(
                flag,
                type=_parse_bool,
                default=default
            )

        elif ftype is int:
            parser.add_argument(
                flag,
                type=_parse_int,
                default=default
            )

        else:
            parser.add_argument(flag, default=default)

    add_output_argument(parser)

    return parser


def main(args: Namespace | Sequence[str] | None = None) -> int:

    if isinstance(args, Namespace):
        ns = args
    else:
        parser = ArgumentParser()
        configure_parser(parser)
        ns = parser.parse_args(args)

    keys = [f.name for f in fields(Cfg)]
    vals = [getattr(ns, k) for k in keys]

    cfg = Cfg(**{
        k: v
        for k, v in zip(keys, vals)
        if v is not None
    })

    ns.output.write_text(cfg.to_json(), encoding="utf-8")

    return 0
