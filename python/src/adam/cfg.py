from dataclasses import asdict, dataclass
import json

BOOL_KEYS: set[str] = {
    "en_lpcpu",
    "en_lpmem",
    "en_debug",
    "en_bootstrap_cpu0",
    "en_bootstrap_mem0",
    "en_bootstrap_lpcpu",
    "en_bootstrap_lpmem",
}

HEX_KEYS: set[str] = {
    "rst_boot_addr",
    "debug_idcode",
    "debug_addr_halt",
    "debug_addr_exception",
    "mmap_boundry",
}

MMAP_KEYS: set[str] = {
    "mmap_lpmem",
    "mmap_syscfg",
    "mmap_lspa",
    "mmap_lspb",
    "mmap_debug",
    "mmap_hsp",
    "mmap_mem",
}

MEM_SIZE_KEY: str = "mem_size"


@dataclass
class Cfg:
    addr_width: int = 32
    data_width: int = 32
    gpio_width: int = 8

    rst_boot_addr: int = 0x4000_0000

    no_cpus: int = 1
    no_dmas: int = 1
    no_hsps: int = 0
    no_mems: int = 2

    en_lpcpu: bool = True
    en_lpmem: bool = True
    en_debug: bool = True

    lpmem_size: int = 0x1000

    # Use ROM for the first memory block by setting its size to 0
    mem_size: tuple[int, ...] = (0x80000, 0x80000)

    no_lspa_gpios: int = 1
    no_lspa_spis: int = 1
    no_lspa_timers: int = 2
    no_lspa_uarts: int = 1

    no_lspb_gpios: int = 0
    no_lspb_spis: int = 0
    no_lspb_timers: int = 0
    no_lspb_uarts: int = 0

    en_bootstrap_cpu0: bool = True
    en_bootstrap_mem0: bool = True
    en_bootstrap_lpcpu: bool = False
    en_bootstrap_lpmem: bool = False

    debug_idcode: int = 0x2495_11C3
    debug_addr_halt: int = 0x2000_0800
    debug_addr_exception: int = 0x2000_0808

    fab_max_trans: int = 7

    mmap_lpmem: tuple[int, ...] = (0x0000_0000, 0x0100_0000)
    mmap_syscfg: tuple[int, ...] = (0x0100_0000, 0x0100_0400)
    mmap_lspa: tuple[int, ...] = (0x1000_0000, 0x1800_0000, 0x0000_0400)
    mmap_lspb: tuple[int, ...] = (0x1800_8000, 0x2000_0000, 0x0000_0400)

    mmap_boundry: int = 0x2000_0000

    mmap_debug: tuple[int, ...] = (0x2000_0000, 0x2000_8000)
    mmap_hsp: tuple[int, ...] = (0x3000_0000, 0x4000_0000, 0x0000_0400)
    mmap_mem: tuple[int, ...] = (0x4000_0000, 0xFFFF_FFFF, 0x0100_0000)

    clk_freq: int = 50_000_000
    rst_cycles: int = 5

    ta: int = 2
    tt: int = 18

    @property
    def no_lspa(self) -> int:
        return (
            self.no_lspa_gpios +
            self.no_lspa_spis +
            self.no_lspa_timers +
            self.no_lspa_uarts
        )

    @property
    def en_lspa(self) -> bool:
        return self.no_lspa > 0

    @property
    def no_lspb(self) -> int:
        return (
            self.no_lspb_gpios +
            self.no_lspb_spis +
            self.no_lspb_timers +
            self.no_lspb_uarts
        )

    @property
    def en_lspb(self) -> bool:
        return self.no_lspb > 0

    def __getitem__(self, key):
        return getattr(self, key)

    def to_json(self) -> str:
        return json.dumps(asdict(self))

    @staticmethod
    def from_json(s: str):
        dikt = json.loads(s)
        return Cfg(**dikt)
