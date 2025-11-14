from argparse import ArgumentParser, Namespace
from pathlib import Path
from typing import Iterable
from adam.library import Library
from .util import CompilerStyleCollect


def parse_defines(kvs: Iterable[str]) -> dict[str, str]:
    """Parse ``-D`` items into a dictionary.

    Examples
    --------
    ['DEBUG', 'WIDTH=32', 'EMPTY='] ->
    {'DEBUG': '', 'WIDTH': '32', 'EMPTY': ''}

    Parameters
    ----------
    kvs:
        Iterable of raw define items (e.g., 'NAME' or 'NAME=VAL').

    Returns
    -------
    dict
        Mapping of define names to string values (empty string if no value).
    """
    out = {}
    for kv in kvs:
        if "=" in kv:
            key, value = kv.split("=", 1)
        else:
            key, value = kv, ""
        out[key] = value
    return out


def add_library_args(
    parser: ArgumentParser,
    *,
    output_metavar: str = "FILE",
    sources_metavar: str = "SRC",
) -> ArgumentParser:
    """Add library flags to an ``argparse`` parser.

    Adds:
      - ``-I DIR`` / ``-IDIR`` (repeatable)
      - ``-D NAME`` / ``-DNAME[=VAL]`` (repeatable)
      - positional ``sources`` (repeatable)

    Parameters
    ----------
    parser:
        The parser to configure.
    output_metavar:
        Metavar for the output path.
    sources_metavar:
        Metavar for positional sources.

    Returns
    -------
    argparse.ArgumentParser
        The same parser (for chaining).
    """

    parser.add_argument(
        "-I",
        dest="includes",
        action=CompilerStyleCollect,
        nargs=1,
        default=[],
        metavar="DIR",
        help="Add include directory (repeatable).",
    )

    parser.add_argument(
        "-D",
        dest="defines",
        action=CompilerStyleCollect,
        nargs=1,
        default=[],
        metavar="NAME[=VAL]",
        help="Define macro (repeatable).",
    )

    parser.add_argument(
        "sources",
        nargs="*",
        metavar=sources_metavar,
        help="Source files.",
    )

    return parser


def parse_library_args(ns: Namespace) -> Library:
    """Extract parsed library args from a namespace.

    Parameters
    ----------
    ns:
        Parsed ``argparse.Namespace`` containing the fields added by
        ``add_library_args``.

    Returns
    -------
    Library
        Dataclass with defines/includes/sources
    """

    defs_attr = getattr(ns, "defines", []) or []
    incs_attr = getattr(ns, "includes", []) or []
    srcs_attr = getattr(ns, "sources", []) or []

    defs = parse_defines(defs_attr)
    incs = [Path(x) for x in incs_attr]
    srcs = [Path(x) for x in srcs_attr]

    return Library(defs, incs, srcs)
