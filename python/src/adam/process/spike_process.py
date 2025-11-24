from pathlib import Path
from typing import IO

from adam.util import (
    PopenError,
    PopenWithCleanup,
    find_free_port,
    resolve_executable,
    wait_for_port
)


class SpikeProcess(PopenWithCleanup):
    def __init__(
        self,
        spike_path: Path | None = None,
        elf_path: Path | None = None,
        rbb_port: int | None = None,
        isa: str = "rv32imfc_zicsr",
        stdin: IO | None = None,
        stdout: IO | None = None,
        stderr: IO | None = None
    ):
        spike_path = spike_path or resolve_executable("spike")

        if not spike_path.is_file():
            raise FileNotFoundError(f"File not found: {spike_path}")

        if not elf_path.is_file():
            raise FileNotFoundError(f"FileNotFoundError: {elf_path}")

        if rbb_port in (None, 0):
            rbb_port = find_free_port(9824)

        self.spike_path = spike_path
        self.elf_path = elf_path
        self.rbb_port = rbb_port
        self.isa = isa

        super().__init__(
            self.build_args(),
            stdin=stdin,
            stdout=stdout,
            stderr=stderr
        )

        try:
            wait_for_port("localhost", rbb_port)
        except TimeoutError:
            raise PopenError(self)

    def build_args(self) -> list[str]:
        return [
            str(self.spike_path),
            "-m0x00000000:0x01000000,0x40000000:0x40000000",
            f"--rbb-port={self.rbb_port}",
            f"--isa={self.isa}",
            "--halted",
            str(self.elf_path)
        ]
