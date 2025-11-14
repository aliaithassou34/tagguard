from pathlib import Path
from jinja2 import Template
from adam.cfg import Cfg
from adam.resources import open_resource


def gen_ldscript(cfg: Cfg, output_file: Path):
    with open_resource("ldscript.ld.j2", "r") as f:
        template = Template(f.read())

    regions = []

    width = cfg.addr_width // 4
    start_addr, end_addr, step_addr = cfg.mmap_mem

    for i, length in enumerate(cfg.mem_size):
        addr = start_addr + step_addr * i

        regions.append({
            "name": f"MEM{i}",
            "origin": f"0x{addr:0{width}X}",
            "length": length
        })

    rendered = template.render(regions=regions)

    output_file.write_text(rendered, encoding="utf-8")
