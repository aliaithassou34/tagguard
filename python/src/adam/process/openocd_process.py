from pathlib import Path
from typing import IO

from adam.util import (
    PopenWithCleanup,
    PopenError,
    find_free_port,
    resolve_executable,
    wait_for_port
)


class OpenocdProcess(PopenWithCleanup):
    def __init__(
        self,
        openocd_path: Path | None = None,
        cfg_path: Path | None = None,
        rbb_port: int | None = None,
        gdb_port: int | None = None,
        stdin: IO | None = None,
        stdout: IO | None = None,
        stderr: IO | None = None
    ):
        openocd_path = openocd_path or resolve_executable("openocd")

        if not openocd_path.is_file():
            raise FileNotFoundError(f"File not found: {openocd_path}")

        if not cfg_path.is_file():
            raise FileNotFoundError(f"File not found: {cfg_path}")

        if gdb_port in (None, 0):
            gdb_port = find_free_port(3333)

        self.openocd_path = openocd_path
        self.cfg_path = cfg_path
        self.rbb_port = rbb_port
        self.gdb_port = gdb_port

        super().__init__(
            self.build_args(),
            stdin=stdin,
            stdout=stdout,
            stderr=stderr,
            text=True
        )

        try:
            wait_for_port("localhost", gdb_port)
        except TimeoutError:
            raise PopenError(self)

    def build_args(self):
        return [
            str(self.openocd_path),
            "-c", f"set gdb_port {self.gdb_port}",
            "-c", f"set rbb_port {self.rbb_port}",
            "-f", str(self.cfg_path)
        ]
