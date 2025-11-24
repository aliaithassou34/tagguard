import os
import subprocess
from pathlib import Path
from subprocess import Popen
from typing import Optional, Sequence

from jinja2 import Template

from adam.resources import open_resource
from adam.util import (
    PopenError,
    PopenWithCleanup,
    find_free_port,
    wait_for_port,
)


def start_hw_server(
    hw_server: Path = "hw_server",
    args: Sequence[str] = [],
    port: Optional[int] = None,
    log_path: Optional[Path] = None
) -> tuple[Popen, int]:

    port = port or find_free_port(3121)

    cmd = [hw_server, "-s", f"tcp::{port}", *args]

    proc = PopenWithCleanup(cmd)

    try:
        wait_for_port("localhost", port)
    except TimeoutError:
        raise PopenError(proc)

    return proc, port


def run_fpga(
    bitstream: Path,
    device: str = "",
    port: Optional[int] = None,
    vivado: Path = "vivado",
    hw_server: Path = "hw_server",
    hw_server_args: Sequence[str] = [],
) -> None:

    if not bitstream.is_file():
        raise FileNotFoundError(f"Bitstream file '{bitstream}' not found.")

    with open_resource("vivado/program_device.tcl.j2", "r") as f:
        template = Template(f.read())

    proc, port = start_hw_server(
        hw_server=hw_server,
        port=port,
        args=hw_server_args,
    )

    url = f"localhost:{port}"

    cmd = [
        vivado,
        "-mode", "tcl",
        "-log", os.devnull,
        "-jou", os.devnull
    ]

    subprocess.run(
        cmd,
        input=template.render(
            device=device,
            bitstream=bitstream,
            url=url
        ),
        text=True,
        check=True
    )
