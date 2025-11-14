from pathlib import Path
from typing import Iterable, Optional
import os
import psutil
import shutil
import subprocess


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


def _bool(value: bool) -> str:
    return "ON" if value else "OFF"


def _list(value: list[str]) -> str:
    return ";".join(value)


def build(
    source_dir: Path,
    build_dir: Path | None = None,
    targets: Iterable[str] | None = None,
    software_targets: Iterable[str] | None = None,
    enable_vunit: bool | None = None,
    enable_verilator: bool | None = None,
    enable_vivado: bool | None = None,
    enable_vendorize: bool | None = None,
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

    if enable_vunit is not None:
        conf_cmd.append(f"-DADAM_ENABLE_VUNIT={_bool(enable_vunit)}")

    if enable_verilator is not None:
        conf_cmd.append(f"-DADAM_ENABLE_VERILATOR={_bool(enable_verilator)}")

    if enable_vivado is not None:
        conf_cmd.append(f"-DADAM_ENABLE_VIVADO={_bool(enable_vivado)}")

    if enable_vendorize is not None:
        conf_cmd.append(f"-DADAM_ENABLE_VENDORIZE={_bool(enable_vendorize)}")

    if enable_tflm is not None:
        conf_cmd.append(f"-DADAM_ENABLE_TFLM={_bool(enable_tflm)}")

    if enable_iree is not None:
        conf_cmd.append(f"-DADAM_ENABLE_IREE={_bool(enable_iree)}")

    subprocess.run(conf_cmd, check=True)

    build_cmd = [
        cmake,
        "--build", build_dir,
        "--parallel", str(jobs)
    ]

    subprocess.run(build_cmd, check=True)
