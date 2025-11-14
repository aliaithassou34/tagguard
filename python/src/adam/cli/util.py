import os
from argparse import Action, ArgumentParser, ArgumentTypeError, Namespace
from pathlib import Path
from typing import Optional

from adam.cfg import Cfg


class CompilerStyleCollect(Action):
    """
    An argparse action that collects compiler-style option values.

    This action appends each provided value into a list of strings
    on the target namespace attribute. It supports both attached and
    separate argument forms, such as:

        - ``-O2`` vs. ``-O 2``
        - ``-DNAME`` vs. ``-D NAME``
        - ``-DNAME=VAL`` vs. ``-D NAME=VAL``

    The collected values are stored as a list of raw strings.
    """

    def __call__(
        self,
        parser: ArgumentParser,
        namespace: Namespace,
        values: str | list[str] | None,
        option_string: Optional[str] = None,
    ) -> None:

        if self.nargs == "*":
            raise ValueError(f"nargs = {self.nargs}")

        if self.nargs in (1, "?"):
            default = []
        else:
            default = None

        res = getattr(namespace, self.dest, default)

        if self.nargs in (1, "?"):
            res.extend(values)
        else:
            res = values

        setattr(namespace, self.dest, res)


def parse_cfg(s: str) -> Cfg:
    try:
        path = Path(s)
        text = path.read_text()
        return Cfg.from_json(text)
    except Exception as e:
        raise ArgumentTypeError(f"Failed to load {path}: {e}")


def parse_bool(value: str) -> bool:
    value = value.lower()
    if value in ("1", "true", "yes", "on"):
        return True
    if value in ("0", "false", "no", "off"):
        return False
    raise ValueError(f"Invalid boolean value: {value!r}")


def add_build_argument(parser: ArgumentParser):
    env = os.getenv("ADAM_BUILD_DIR")
    parser.add_argument(
        "-B", "--build",
        action=CompilerStyleCollect,
        default=(Path(env) if env else None),
        type=Path,
        help="Build directory."
    )


def add_source_argument(parser: ArgumentParser):
    env = os.getenv("ADAM_SOURCE_DIR")
    parser.add_argument(
        "-S", "--source",
        action=CompilerStyleCollect,
        default=(Path(env) if env else None),
        type=Path,
        help="Source directory."
    )


def add_cfg_argument(parser: ArgumentParser):
    parser.add_argument(
        "-c", "--cfg",
        type=parse_cfg,
        required=True,
        help="JSON configuration file path."
    )


def add_dirty_argument(parser: ArgumentParser):
    parser.add_argument(
        "-d", "--dirty",
        action="store_true",
        help="Enable incremental build."
    )


def add_jobs_argument(parser: ArgumentParser):
    parser.add_argument(
        "-j", "--jobs",
        type=int,
        default=1,
        help="Number of jobs to run in parallel (default: 1).",
    )


def add_output_argument(parser: ArgumentParser):
    parser.add_argument(
        "-o", "--output",
        type=Path,
        required=True,
        help="Output file path.",
    )


def add_bool_argument(parser: ArgumentParser, *args, **kwargs):
    parser.add_argument(
        *args,
        type=parse_bool,
        metavar="true|false",
        **kwargs
    )
