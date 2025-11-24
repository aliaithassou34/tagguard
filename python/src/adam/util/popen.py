import atexit
import os
import signal
import subprocess
import sys
import termios
from subprocess import Popen, DEVNULL


class PopenError(RuntimeError):
    def __init__(
        self,
        message: str,
        proc: Popen | None = None,
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
        args,
        *,
        stdin=None,
        **kwargs
    ):
        if os.name == "nt":
            value = subprocess.CREATE_NEW_PROCESS_GROUP
            kwargs.setdefault("creationflags", value)
        else:
            kwargs.setdefault("start_new_session", True)

        stdin = stdin or sys.stdin
        if hasattr(stdin, "isatty") and stdin.isatty():
            self.tty_file = stdin
            self.tty_args = termios.tcgetattr(stdin)
        else:
            self.tty_file = None
            self.tty_args = None

        super().__init__(args, stdin=stdin, **kwargs)

        atexit.register(self.cleanup)

    def __exit__(self):
        self.wait()

    def cleanup(self):
        self.terminate()
        self.wait(5)
        kill_process_tree(self)
        if self.tty_file:
            try:
                termios.tcsetattr(
                    self.tty_file, termios.TCSADRAIN, self.tty_args
                )
            except Exception:
                pass


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
