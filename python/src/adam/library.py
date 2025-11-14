from dataclasses import dataclass
from pathlib import Path


@dataclass
class Library:
    defines: dict[str, str]
    includes: list[Path]
    sources: list[Path]
