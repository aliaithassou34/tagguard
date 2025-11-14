import os
import subprocess
from datetime import datetime
from pathlib import Path


def clog2(x):
    if x <= 0:
        raise ValueError("domain error")
    return (x-1).bit_length()


def get_class_attribute(cls: type, attr_name: str, default=None):
    """
    Retrieve the value of an attribute from a class or any of its base classes.

    Args:
        cls: The class to search for the attribute.
        attr_name: The name of the attribute to search for.
        default: The value to return if the attribute is not found.

    Returns:
        The value of the attribute if found, otherwise the default value.
    """

    for base in cls.__mro__:
        if attr_name in base.__dict__:
            return base.__dict__[attr_name]

    return default


def get_git_info(cwd: str | Path) -> tuple[str, str]:
    cwd = os.path.dirname(os.path.abspath(__file__))
    branch = subprocess.check_output(
        ["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd=cwd
    ).decode().strip()
    commit = subprocess.check_output(
        ["git", "rev-parse", "HEAD"], cwd=cwd
    ).decode().strip()
    dirty = subprocess.check_output(
        ["git", "status", "--porcelain", "--ignore-submodules"], cwd=cwd
    )
    if dirty:
        commit += " (dirty)"
    return branch, commit


def get_formated_timestamp() -> str:
    return datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")
