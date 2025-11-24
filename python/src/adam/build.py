from pathlib import Path
from typing import Iterable
import os
import psutil
import shutil
import subprocess

ENABLES = [
    "docs",
    "vunit",
    "verilator",
    "vivado",
    "vendorize",
    "gmsv",
    "tflm",
    "iree"
]


class BuildError(RuntimeError):
    pass


def _clean_dir(dir: Path):
    for entry in dir.iterdir():
        if entry.is_dir():
            shutil.rmtree(entry)
        else:
            entry.unlink()


def _get_jobs_heuristic() -> int:
    cpu_total = os.cpu_count() or 1
    cpu_per_job = 1
    cpu_margin = 2
    cpu_heuristic = max(int(cpu_total - cpu_margin) // cpu_per_job, 1)

    mem_total = psutil.virtual_memory().total / (1024**3)
    mem_per_job = 1
    mem_margin = 1
    mem_heuristic = max(int(mem_total - mem_margin) // mem_per_job, 1)

    return min(cpu_heuristic, mem_heuristic)


def _list(value: list[str]) -> str:
    return ";".join(value)


def build(
    source_dir: Path,
    build_dir: Path | None = None,
    targets: Iterable[str] | None = None,
    software_targets: Iterable[str] | None = None,
    enable_docs: bool | None = None,
    enable_vunit: bool | None = None,
    enable_verilator: bool | None = None,
    enable_vivado: bool | None = None,
    enable_vendorize: bool | None = None,
    enable_gmsv: bool | None = None,
    enable_tflm: bool | None = None,
    enable_iree: bool | None = None,
    dirty: bool = False,
    jobs: int | None = None,
):
    cmake = "cmake"

    if shutil.which(cmake) is None:
        raise BuildError(f"CMake not found on PATH as {cmake!r}")

    if build_dir is None:
        build_dir = source_dir / "build"

    source_dir = source_dir.resolve()
    build_dir = build_dir.resolve()

    if build_dir == source_dir:
        raise BuildError(
            f"Refusing to use build_dir (same as source_dir): {build_dir}"
        )

    if build_dir.exists() and not dirty:
        msg = f"'{build_dir}' exists. Overwrite? (y/n): "
        answer = input(msg).lower()

        if answer == "y":
            print(f"Overwriting {build_dir}")
            _clean_dir(build_dir)
        else:
            raise BuildError(f"Build dir exists: '{build_dir}'")

    else:
        build_dir.mkdir(parents=True, exist_ok=True)

    if jobs is None:
        jobs = _get_jobs_heuristic()

    conf_cmd = [
        cmake,
        "-G", "Ninja",
        f"-S{source_dir}",
        f"-B{build_dir}",
        f"-DADAM_JOBS={jobs}"
    ]

    if targets is not None:
        conf_cmd.append(f"-DADAM_TARGETS={_list(targets)}")

    if software_targets is not None:
        conf_cmd.append(f"-DADAM_SOFTWARE_TARGETS={_list(software_targets)}")

    locals_dict = locals()
    enable_dict = {
        name: locals_dict[f"enable_{name}"]
        for name in ENABLES
    }

    if any(v is not None for v in enable_dict.values()):
        for k, v in enable_dict.items():
            v_str = "ON" if v else "OFF"
            conf_cmd.append(f"-DADAM_ENABLE_{k.upper()}={v_str}")

    subprocess.run(conf_cmd, check=True)

    build_cmd = [
        cmake,
        "--build", build_dir,
        "--parallel", str(jobs),
    ]

    subprocess.run(build_cmd, check=True)
