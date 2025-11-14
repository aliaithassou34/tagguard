from dataclasses import asdict
from pathlib import Path
from jinja2 import Template
from adam.cfg import (
    BOOL_KEYS,
    HEX_KEYS,
    MMAP_KEYS,
    MEM_SIZE_KEY,
    Cfg,
)
from adam.resources import open_resource
from adam.util import get_formated_timestamp


def _format_hex(value: int, width: int) -> str:
    hex_digits = (width + 3) // 4
    return f"{width}'h{value:0{hex_digits}x}"


def _format_mem_size(data: tuple[int, ...], width: int) -> str:
    arr = data + [0]
    return "'{" + ", ".join(_format_hex(v, width) for v in arr) + "}"


def _format_mmap(data: tuple[int, ...], width: int) -> str:
    items = [_format_hex(v, width) for v in data]
    while len(items) < 3:
        items.append("'0")
    return "'{" + ", ".join(items) + "}"


def gen_pkg(
    cfg: Cfg,
    name: str,
    output_file: Path
):

    with open_resource("adam_cfg_pkg.sv.j2", "r") as f:
        template = Template(f.read())

    params = asdict(cfg)

    params["name"] = name
    params["date"] = get_formated_timestamp()

    width = int(params["addr_width"])

    for key in BOOL_KEYS:
        if key in params:
            params[key] = int(bool(params[key]))

    # Format hex fields
    for key in HEX_KEYS:
        if key in params:
            params[key] = _format_hex(int(params[key]), width)

    for key in MMAP_KEYS:
        arr = [int(x) for x in params[key]]
        params[key] = _format_mmap(arr, width)

    params[MEM_SIZE_KEY] = _format_mem_size(
        [int(x) for x in params[MEM_SIZE_KEY]], width)

    rendered = template.render(**params)

    output_file.write_text(rendered, encoding="utf-8")
