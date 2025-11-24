import subprocess
import sys
from pathlib import Path
from typing import Optional

from adam.build import build


def run_vunit(
    target: str,
    top: str,
    gui: bool,
    source_dir: Path,
    build_dir: Optional[Path] = None,
):
    if not top:
        raise ValueError("'top' must not be empty")

    if build_dir is None:
        build_dir = source_dir / "build"

    build_dir = build_dir.absolute()

    build(
        source_dir,
        build_dir,
        targets=[f"{target}_vunit_gen"],
        enable_vunit=True,
        dirty=True
    )

    vunit_path = build_dir / "targets" / target / "vunit"
    run_py = vunit_path / "run.py"

    cmd = [sys.executable, run_py, '-o', vunit_path]
    cmd += ['-g'] if gui else []
    cmd += [f'lib.{top}' if '.' in top else f'lib.{top}.*']

    subprocess.run(cmd, cwd=vunit_path)
