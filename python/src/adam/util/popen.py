import atexit
import os
import signal
import subprocess
from pathlib import Path
from subprocess import DEVNULL, STDOUT, Popen
from typing import Optional


class PopenError(RuntimeError):
    def __init__(
        self,
        message: str,
        proc: Optional[Popen] = None,
        limit: int = 4096
    ):
        self.proc = proc
        self.output = self._collect_output(limit)
        super().__init__(self._format_message(message))
        kill_process_tree(proc)

    def _collect_output(self, limit: int) -> str:
        """Best-effort read of process output."""
        if self.proc is None or self.proc.stdout is None:
            return ""
        try:
            return self.proc.stdout.read(limit) or ""
        except Exception:
            return ""

    def _format_message(self, message: str) -> str:
        if self.output:
            return f"{message}\n\n--- process output ---\n{self.output}"
        return message


class PopenWithCleanup(Popen):
    def __init__(
        self,
        *args,
        log_path: Optional[Path],
        **kwargs
    ):
        if os.name == "nt":
            value = subprocess.CREATE_NEW_PROCESS_GROUP
            kwargs.setdefault("creationflags", value)

        else:
            kwargs.setdefault("start_new_session", True)

        kwargs.setdefault("stdin", DEVNULL)
        kwargs.setdefault("stderr", STDOUT)

        if (
            log_path is not None and
            "stdout" not in kwargs
        ):
            self.log_file = log_path.open("w", buffering=1)
        else:
            self.log_file = None

        if self.log_file is not None:
            kwargs["stdout"] = self.log_file
            kwargs["text"] = True

        super().__init__(*args, **kwargs)

        atexit.register(lambda p=self: p.cleanup())

    def __exit__(self):
        self.wait()

    def cleanup(self):
        self.terminate()
        self.wait(5)
        kill_process_tree(self)
        if self.log_file is not None:
            self.log_file.flush()
            self.log_file.close()


def kill_process_tree(proc: Popen) -> None:
    if os.name == "nt":  # Windows
        try:
            subprocess.run(
                ["taskkill", "/PID", str(proc.pid), "/T", "/F"],
                check=False,
                stdout=DEVNULL,
                stderr=DEVNULL,
            )
        except Exception:
            pass

    else:  # POSIX
        try:
            os.killpg(os.getpgid(proc.pid), signal.SIGTERM)
        except ProcessLookupError:
            pass

        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            # Force kill
            try:
                os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
            except ProcessLookupError:
                pass
