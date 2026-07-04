from dataclasses import asdict
from pathlib import Path
from typing import Optional
from adam.cfg import Cfg
from adam.util import (
    get_formated_timestamp,
    get_git_info,
)

HEADER_TEMPLATE = """
/*
 * ============================================================================
 * ADAM Register Abstraction Layer (RAL)
 * ============================================================================
 *
 * This header was auto-generated using adam_ral_h.py.
 *
 * Date   : {date}
 *
 * It is not recommended to modify this file.
 * ============================================================================
 */
"""


class Field:
    def __init__(self, name=None, size=None):
        self.name = name
        self.size = size


class Flag(Field):
    def __init__(self, name=None, size=1):
        super().__init__(name, size)


class Dtype(Field):
    def __init__(self, dtype="ral_data_t", name=None, size=None):
        super().__init__(name, size)
        self.dtype = dtype


class Group(Field):
    def __init__(self, name=None, size=None):
        super().__init__(name, size)
        self.items = []

    def add(self, item):
        self.items += [item]


class Register(Group):
    def __init__(self, name=None, size=None, read_only=False):
        super().__init__(name, size)
        self.read_only = read_only if name else True


class Struct(Group):
    pass


class CodeWritter:
    def __init__(self):
        self.content = ""
        self.indent = 0

    def put(self, line):
        self.content += 4*self.indent*" " + line + "\n"

    def skip(self, num=1):
        self.content += num*"\n"


def build_syscfg_tgt(
    name: str,
    size: Optional[int] = None,
    en_bar: bool = False,
    en_ier: bool = False
) -> None:
    syscfg_tgt = Struct(name, size)

    sr = Register("SR", read_only=True)
    sr.add(Flag("P"))
    sr.add(Flag("S"))
    syscfg_tgt.add(sr)

    mr = Register("MR")
    mr.add(Flag("ACTION", 4))
    syscfg_tgt.add(mr)

    syscfg_tgt.add(Register("BAR" if en_bar else None))
    syscfg_tgt.add(Register("IER" if en_ier else None))

    return syscfg_tgt


def add_dift_lspx_flags(register: Register, cfg: Cfg, lspx: str, suffix: str) -> None:
    prefix = lspx.upper()
    for periph in ["gpio", "spi", "timer", "uart"]:
        periph_prefix = periph.upper()
        for idx in range(cfg[f"no_{lspx}_{periph}s"]):
            register.add(Flag(f"{prefix}_{periph_prefix}{idx}_{suffix}"))


def build_syscfg_t(cfg: Cfg) -> None:
    syscfg = Struct("ral_syscfg_t")

    syscfg.add(build_syscfg_tgt("LSDOM"))
    syscfg.add(build_syscfg_tgt("HSDOM"))
    syscfg.add(build_syscfg_tgt("FAB_LSDOM"))
    syscfg.add(build_syscfg_tgt("FAB_HSDOM"))
    if cfg.en_lspa:
        syscfg.add(build_syscfg_tgt("FAB_LSPA"))
    if cfg.en_lspb:
        syscfg.add(build_syscfg_tgt("FAB_LSPB"))
    if cfg.en_lpcpu:
        syscfg.add(build_syscfg_tgt("LPCPU", en_bar=1, en_ier=1))
    if cfg.en_lpmem:
        syscfg.add(build_syscfg_tgt("LPMEM"))
    syscfg.add(build_syscfg_tgt("CPU", cfg.no_cpus, en_bar=1, en_ier=1))
    syscfg.add(build_syscfg_tgt("DMA", cfg.no_dmas, en_ier=1))
    syscfg.add(build_syscfg_tgt("MEM", cfg.no_mems))

    for lspx in ["lspa", "lspb"]:
        LSPX = lspx.upper()
        s = Struct(LSPX)
        s.add(build_syscfg_tgt("GPIO", cfg[f"no_{lspx}_gpios"]))
        s.add(build_syscfg_tgt("SPI", cfg[f"no_{lspx}_spis"]))
        s.add(build_syscfg_tgt("TIMER", cfg[f"no_{lspx}_timers"]))
        s.add(build_syscfg_tgt("UART", cfg[f"no_{lspx}_uarts"]))
        syscfg.add(s)

    # DIFT Security-Wrapper Registers — appended as last target
    dift = Struct("TAINT_SRC")
    dtsr = Register("DTSR")
    add_dift_lspx_flags(dtsr, cfg, "lspa", "TAINT_EN")
    add_dift_lspx_flags(dtsr, cfg, "lspb", "TAINT_EN")
    dift.add(dtsr)
    mpm = Register("MPM")
    add_dift_lspx_flags(mpm, cfg, "lspa", "GUARD_EN")
    add_dift_lspx_flags(mpm, cfg, "lspb", "GUARD_EN")
    dift.add(mpm)
    mps = Register("MPS")
    add_dift_lspx_flags(mps, cfg, "lspa", "GUARD_FIRED")
    add_dift_lspx_flags(mps, cfg, "lspb", "GUARD_FIRED")
    dift.add(mps)
    dift.add(Register(None))  # padding to 4 registers per slot
    syscfg.add(dift)

    return syscfg


def build_gpio_t(cfg: Cfg) -> None:
    gpio = Struct("ral_gpio_t")

    idr = Register("IDR")
    for x in range(cfg.gpio_width):
        idr.add(Flag(f"ID{x}"))
    gpio.add(idr)

    odr = Register("ODR")
    for x in range(cfg.gpio_width):
        odr.add(Flag(f"OD{x}"))
    gpio.add(odr)

    moder = Register("MODER")
    for x in range(cfg.gpio_width):
        moder.add(Flag(f"MODE{x}"))
    gpio.add(moder)

    otyper = Register("OTYPER")
    for x in range(cfg.gpio_width):
        otyper.add(Flag(f"OTYPE{x}"))
    gpio.add(otyper)

    fsr = Register("FSR", 2)
    for x in range(cfg.gpio_width):
        fsr.add(Flag(f"FS{x}", 2))
    gpio.add(fsr)

    ier = Register("IER")
    for x in range(cfg.gpio_width):
        ier.add(Flag(f"IE{x}"))
    gpio.add(ier)

    return gpio


def build_spi_t(cfg: Cfg) -> None:
    spi = Struct("ral_spi_t")

    spi.add(Register("DR"))

    cr = Register("CR")
    cr.add(Flag("PE"))
    cr.add(Flag("TE"))
    cr.add(Flag("RE"))
    cr.add(Flag("MS"))
    cr.add(Flag("CPHA"))
    cr.add(Flag("CPOL"))
    cr.add(Flag("DO"))
    cr.add(Flag(None))
    cr.add(Flag("DL", 4))
    spi.add(cr)

    sr = Register("SR")
    sr.add(Flag("TBE"))
    sr.add(Flag("RBF"))
    spi.add(sr)

    spi.add(Register("BRR"))

    ier = Register("IER")
    ier.add(Flag("RBFIE"))
    ier.add(Flag("TBEIE"))
    spi.add(ier)

    return spi


def build_timer_t(cfg: Cfg) -> None:
    timer = Struct("ral_timer_t")

    cr = Register("CR")
    cr.add(Flag("PE"))
    timer.add(cr)

    timer.add(Register("PR"))
    timer.add(Register("VR"))
    timer.add(Register("ARR"))

    er = Register("ER")
    er.add(Flag("ARE"))
    timer.add(er)

    ier = Register("IER")
    ier.add(Flag("AREIE"))
    timer.add(ier)

    return timer


def build_uart_t(cfg: Cfg) -> None:
    uart = Struct("ral_uart_t")

    uart.add(Register("DR"))

    cr = Register("CR")
    cr.add(Flag("PE"))
    cr.add(Flag("TE"))
    cr.add(Flag("RE"))
    cr.add(Flag("PC"))
    cr.add(Flag("PS"))
    cr.add(Flag("SB"))
    cr.add(Flag(None, 2))
    cr.add(Flag("DL", 4))
    uart.add(cr)

    sr = Register("SR")
    sr.add(Flag("TBE"))
    sr.add(Flag("RBF"))
    uart.add(sr)

    uart.add(Register("BRR"))

    ier = Register("IER")
    ier.add(Flag("TBEIE"))
    ier.add(Flag("RBFIE"))
    uart.add(ier)

    return uart


def build_ral_t(cfg: Cfg) -> None:
    ral = Struct("ral_t")

    if cfg.en_lpmem:
        ral.add(Dtype("ral_data_t *", "LPMEM"))

    ral.add(Dtype("ral_syscfg_t *", "SYSCFG"))

    for lspx in ["lspa", "lspb"]:
        LSPX = lspx.upper()
        s = Struct(LSPX)
        s.add(Dtype("ral_gpio_t *", "GPIO", cfg[f"no_{lspx}_gpios"]))
        s.add(Dtype("ral_spi_t *", "SPI", cfg[f"no_{lspx}_spis"]))
        s.add(Dtype("ral_timer_t *", "TIMER", cfg[f"no_{lspx}_timers"]))
        s.add(Dtype("ral_uart_t *", "UART", cfg[f"no_{lspx}_uarts"]))
        ral.add(s)

    ral.add(Dtype("ral_data_t *", "MEM", cfg.no_mems))

    return ral


def write_dtype(item: Dtype, cw: CodeWritter) -> None:
    dtype = item.dtype

    if dtype[-1] != "*":
        dtype += " "

    if item.size is None:
        cw.put(f"{dtype}{item.name};")
    else:
        cw.put(f"{dtype}{item.name}[{item.size}];")


def write_register(register: Register, cw: CodeWritter) -> None:
    rw_dtype = "ral_data_t"
    ro_dtype = "const ral_data_t"
    dtype = ro_dtype if register.read_only else rw_dtype

    reserved = 0

    if register.items:
        cw.put("union {")
        cw.indent += 1

        if register.size is None:
            cw.put(f"{dtype} {register.name};")
        else:
            cw.put(f"{dtype} {register.name}[{register.size}];")

        cw.put("struct {")
        cw.indent += 1

        for flag in register.items:
            if flag.name:
                cw.put(f"{dtype} {flag.name} : {flag.size};")
            else:
                cw.put(f"{dtype} reserved{reserved} : {flag.size};")
                reserved += 1

        cw.indent -= 1
        cw.put("};")

        cw.indent -= 1
        cw.put("};")

    else:
        if register.size is None:
            cw.put(f"{dtype} {register.name};")
        else:
            cw.put(f"{dtype} {register.name}[{register.size}];")


def write_struct(
    struct: Struct,
    cw: CodeWritter,
    typedef: bool = False
) -> None:
    if struct.size == 0:
        return

    reserved = 0
    cw.put("typedef struct {" if typedef else "struct {")
    cw.indent += 1

    for item in struct.items:
        if isinstance(item, Struct):
            write_struct(item, cw)

        elif isinstance(item, Register):
            # deep copy it?
            if not item.name:
                item.name = f"reserved{reserved}"
                reserved += 1

            write_register(item, cw)

        elif isinstance(item, Dtype):
            write_dtype(item, cw)

        else:
            print(type(item))
            raise ValueError()

    cw.indent -= 1
    if struct.name:
        if struct.size is None:
            cw.put(f"}} {struct.name};")
        else:
            cw.put(f"}} {struct.name}[{struct.size}];")

    else:
        cw.put("};")


def write_ral_def(cfg: Cfg, cw: CodeWritter) -> None:
    aw = cfg.addr_width

    cw.put("static const ral_t RAL = {")
    cw.indent += 1

    if cfg.en_lpmem:
        addr, end = cfg.mmap_lpmem
        cw.put(f".LPMEM = (ral_data_t *) {ahex(addr, aw)},")

    addr, end = cfg.mmap_syscfg
    cw.put(f".SYSCFG = (ral_syscfg_t *) {ahex(addr, aw)},")

    for lspx in ["lspa", "lspb"]:
        LSPX = lspx.upper()

        if not cfg[f"en_{lspx}"]:
            continue

        cw.put(f".{LSPX}" + " = {")
        cw.indent += 1

        addr, end, inc = cfg[f"mmap_{lspx}"]

        for periph in ["gpio", "spi", "timer", "uart"]:
            PERIPH = periph.upper()

            size = cfg[f"no_{lspx}_{periph}s"]

            if size <= 0:
                continue

            cw.put(f".{PERIPH}" + " = {")
            cw.indent += 1

            for i in range(size):
                cw.put(f"(ral_{periph}_t *) {ahex(addr, aw)},")
                addr += inc

            cw.indent -= 1
            cw.put("},")

        cw.indent -= 1
        cw.put("},")

    size = cfg.no_mems

    if size > 0:
        cw.put(".MEM = {")
        cw.indent += 1

        addr, end, inc = cfg.mmap_mem
        for i in range(size):
            cw.put(f"(ral_data_t *) {ahex(addr, aw)},")
            addr += inc

        cw.indent -= 1
        cw.put("},")

    cw.indent -= 1
    cw.put("};")


def ahex(x: int, w: int) -> str:
    return f"0x{x:0{(w+3)//4}X}"


def gen_ral(
    cfg: Cfg,
    output_file: Path
) -> None:
    cw = CodeWritter()

    date = get_formated_timestamp
    # branch, commit = get_git_info()

    cw.put(HEADER_TEMPLATE.strip().format(date=date))
    cw.skip()

    cw.put("#pragma once")
    cw.put(f"#define SYSTEM_CLOCK {cfg.clk_freq}")
    cw.skip()

    cw.put("typedef volatile unsigned int ral_data_t;")
    cw.skip()

    typedefs = [
        build_syscfg_t(cfg),
        build_gpio_t(cfg),
        build_spi_t(cfg),
        build_timer_t(cfg),
        build_uart_t(cfg),
        build_ral_t(cfg)
    ]

    for typedef in typedefs:
        write_struct(typedef, cw, typedef=True)
        cw.skip(1)

    write_ral_def(cfg, cw)

    with open(output_file, "w", encoding="utf-8") as f:
        f.write(cw.content)
