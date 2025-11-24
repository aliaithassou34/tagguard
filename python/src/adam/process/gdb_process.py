import os
from pathlib import Path
from typing import IO, Iterable

from adam.util import ADAM_MODULE_DIR, PopenWithCleanup, resolve_executable


class GdbProcess(PopenWithCleanup):
    def __init__(
        self,
        gdb_path: Path | None = None,
        gdb_port: int = 3333,
        elf_path: Path | None = None,
        exe_args: Iterable[str] | None = None,
        stdin: IO | None = None,
        stdout: IO | None = None,
        stderr: IO | None = None,
        text: bool = False,
        batch: bool = False,
        semihost: bool = False
    ) -> None:
        gdb_path = gdb_path or resolve_executable("riscv32-unknown-elf-gdb")

        if elf_path is None and exe_args is not None:
            elf_path = Path(exe_args[0])

        if not gdb_path.is_file():
            raise FileNotFoundError(f"File not found: {gdb_path}")

        if not elf_path.is_file():
            raise FileNotFoundError(f"File not found: {elf_path}")

        env = os.environ.copy()
        env["PYTHONPATH"] = (
            str(ADAM_MODULE_DIR) + ":" + env.get("PYTHONPATH", "")
        )

        self.gdb_path = gdb_path
        self.gdb_port = gdb_port
        self.elf_path = elf_path
        self.exe_args = exe_args
        self.batch = batch
        self.semihost = semihost

        super().__init__(
            self.build_args(),
            stdin=stdin,
            stdout=stdout,
            stderr=stderr,
            env=env,
            text=text
        )

    def build_args(self) -> list[str]:
        args = [
            str(self.gdb_path),
            str(self.elf_path),
            "-ex", "python import semihost",
            "-ex", f"target extended-remote localhost:{self.gdb_port}",
            "-ex", "load"
        ]

        if self.semihost:
            args += ["-ex", "semihost"]

        if self.batch:
            args += ["-ex", "c", "-q", "-batch-silent"]

        if self.exe_args is not None:
            args += ["--args", *self.exe_args]

        return args
