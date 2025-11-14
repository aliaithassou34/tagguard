from jinja2 import Template
from pathlib import Path
from adam.library import Library
from adam.resources import open_resource


def gen_vunit(
    library: Library,
    source_path: Path,
    output_file: Path
):
    with open_resource("vunit.py.j2", "r") as f:
        template = Template(f.read())

    print(library.includes)

    rendered = template.render(
        defines=library.defines,
        includes=[
            p.relative_to(source_path)
            for p in library.includes
        ],
        sources=[
            p.relative_to(source_path)
            for p in library.sources
        ],
        adam=source_path.as_posix()
    )

    output_file.write_text(rendered, encoding="utf-8")
