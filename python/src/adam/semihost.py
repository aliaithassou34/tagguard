import gdb
import logging


class FunctionBreakpoint(gdb.Breakpoint):
    def __init__(self, symbol, nargs, handler):
        super().__init__(symbol, gdb.BP_BREAKPOINT, internal=True)
        self.nargs = nargs
        self.handler = handler
        self.silent = True

    def stop(self):
        try:
            args = [
                int(gdb.parse_and_eval(f"$a{i}"))
                for i in range(self.nargs)
            ]
        except gdb.error:
            return True

        ret = self.handler(*args)

        gdb.execute(f"set $a0 = {ret}", to_string=True)
        gdb.execute("set $pc = $ra", to_string=True)
        return False


class SemihostCommand(gdb.Command):
    def __init__(self):
        super().__init__("semihost", gdb.COMMAND_USER)
        self.invoked = False
        self.file_dict = dict()
        self.breakpoints = []
        self.next_fd = -1

    def invoke(self, arg, from_tty):
        if self.invoked:
            raise RuntimeError("semihost was already invoked")

        self.invoked = True

        if "--debug" in arg.split(" "):
            level = logging.DEBUG
        else:
            level = logging.INFO

        logging.basicConfig(
            level=level,
            format="%(levelname)s: %(message)s"
        )

        self.setup()

    def setup(self):
        self.file_dict[0] = open("/dev/stdin", "rb")
        self.file_dict[1] = open("/dev/stdout", "wb")
        self.file_dict[2] = open("/dev/stderr", "wb")
        self.next_fd = 3

        for sym, nargs, func in [
            ("_read",  3, self.read),
            ("_write", 3, self.write),
            ("_open",  2, self.open),
            ("_close", 1, self.close),
            ("_lseek", 3, self.lseek),
            ("__call_exitprocs", 2, self.call_exitprocs)
        ]:
            if not self._has_symbol(sym):
                logging.debug(
                    f"Cannot add {sym!r} breakpoint: symbol not found"
                )
                continue

            logging.debug(f"Adding {sym} breakpoint")

            self.breakpoints.append(FunctionBreakpoint(sym, nargs, func))

        logging.info("Semihosting initialized")

    def read(self, fd: int, buf: int, n: int) -> int:
        logging.debug(f"read({fd}, 0x{buf:08x}, {n})")
        try:
            file = self.file_dict[fd]
            data = file.read(n)
            if data:
                inf = gdb.selected_inferior()
                inf.write_memory(buf, data)
                return len(data)
            else:
                return 0
        except Exception:
            return -1

    def write(self, fd: int, buf: int, n: int) -> int:
        logging.debug(f"write({fd}, 0x{buf:08x}, {n})")
        try:
            file = self.file_dict[fd]
            inf = gdb.selected_inferior()
            data = inf.read_memory(buf, n).tobytes()
            logging.debug(data.decode())
            file.write(data)
            file.flush()
            return len(data)
        except Exception:
            logging.exception("")
            return -1

    def open(self, ptr: int, flags: int) -> int:
        logging.debug(f"open(0x{ptr:08x}, {flags})")
        try:
            path = self._read_string(ptr)
            mode = self._map_flags(flags)
            file = open(path, mode)
            fd = self.next_fd
            self.file_dict[fd] = file
            self.next_fd += 1
            return fd
        except Exception:
            logging.exception("")
            return -1

    def close(self, fd: int) -> int:
        logging.debug(f"close({fd})")
        try:
            file = self.file_dict[fd]
            file.close()
            del self.file_dict[fd]
            return 0
        except Exception:
            logging.exception("")
            return -1

    def lseek(self, fd: int, offset: int, whence: int) -> int:
        logging.debug(f"lseek({fd}, {offset}, {whence})")
        try:
            file = self.file_dict[fd]
            file.seek(offset, whence)
            return file.tell()
        except Exception:
            logging.exception("")
            return -1

    def call_exitprocs(self, code: int, d: int) -> int:
        logging.debug(f"call_exitprocs({code}, {d})")
        try:
            try:
                gdb.execute("monitor shutdown", to_string=True)
            except Exception:
                pass
            gdb.execute(f"quit {code}", to_string=True)
            return 0
        except Exception:
            logging.exception("")
            return -1

    def _read_string(self, ptr: int) -> str:
        chars = []

        while True:
            inf = gdb.selected_inferior()
            char = inf.read_memory(ptr, 1).tobytes()
            if char == b"\x00":
                break
            chars.append(char)
            ptr += 1

        return b"".join(chars).decode(errors="ignore")

    def _map_flags(self, flags: int) -> str:
        if flags & 2:          # O_RDWR
            ret = "r+b"
        elif flags & 1:        # O_WRONLY
            ret = "wb"
        else:
            ret = "rb"

        if flags & 0x200:      # O_CREAT
            if "r" in ret:
                ret = "w+b"
            else:
                ret = "wb"

        return ret

    def _has_symbol(self, name: str) -> bool:
        sym, _ = gdb.lookup_symbol(name)
        return sym is not None


SemihostCommand()
