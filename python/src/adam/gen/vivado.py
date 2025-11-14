from jinja2 import Template
from pathlib import Path
from adam.library import Library
from adam.resources import open_resource


def gen_vivado(
    part: str,
    top: str,
    jobs: int,
    library: Library,
    constrs: list[Path],
    source_path: Path,
    output_file: Path,
):
    with open_resource("vivado/bitstream.tcl.j2", "r") as f:
        template = Template(f.read())

    rendered = template.render(
        part=part,
        top=top,
        jobs=jobs,
        defines=[
            f"{k}={v}"
            for k, v in library.defines.items()
        ],
        includes=[
            p.relative_to(source_path)
            for p in library.includes
        ],
        sources=[
            p.relative_to(source_path)
            for p in library.sources
        ],
        constrs=[
            x.relative_to(source_path).as_posix()
            for x in constrs
        ],
        adam=source_path.as_posix(),
    )

    output_file.write_text(rendered, encoding="utf-8")
