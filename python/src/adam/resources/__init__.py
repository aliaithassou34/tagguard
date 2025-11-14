from importlib.resources import files
from pathlib import Path, PurePosixPath


def get_resource_path(resource: str | Path) -> Path:
    """
    Construct absolute path to a resource in 'adam.resources', enforcing
    POSIX path format even on non-POSIX systems like Windows. This ensures
    consistent path handling across different environments.

    Parameters:
    - resource (str | Path): Relative path or filename of the resource,
                             interpreted in POSIX format.

    Returns:
    - Path: Absolute path to the specified resource within the package.

    Raises:
    - FileNotFoundError: If the resource path doesn't exist in the package.

    Example:
    >>> get_resource_path('data/config.json')
    PosixPath('/path/to/adam/resources/data/config.json')
    """

    rel_path = PurePosixPath(resource)
    return Path(files('adam.resources').joinpath(rel_path))


def open_resource(resource: str | Path, *args, **kwargs):
    return open(get_resource_path(resource), *args, **kwargs)


__all__ = [
    get_resource_path,
    open_resource,
]
