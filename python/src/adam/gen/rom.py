from elftools.elf.elffile import ELFFile
from elftools.elf.constants import SH_FLAGS
from jinja2 import Template
from pathlib import Path

coe_template = Template("""
memory_initialization_radix = 16;
memory_initialization_vector =
{%- for word in words %}
{{ "{:08X}".format(word) }}
{%- endfor %}
""")

btxt_template = Template("""
{%- for word in words %}
{{ "{:032b}".format(word) }}
{%- endfor %}
""")

htxt_template = Template("""
{%- for word in words %}
{{ "{:08X}".format(word) }}
{%- endfor %}
""")

sverilog_template = Template("""
`include "adam/macros.svh"

module {{ module_name }} #(
    `ADAM_CFG_PARAMS
) (
    ADAM_SEQ.Slave seq,

    input  logic  req,
    input  ADDR_T addr,
    input  logic  we,
    input  STRB_T be,
    input  DATA_T wdata,
    output DATA_T rdata
);

    localparam SIZE = {{ size }};

    localparam UNALIGNED_WIDTH = $clog2(STRB_WIDTH);
    localparam ALIGNED_WIDTH   = ADDR_WIDTH - UNALIGNED_WIDTH;
    localparam ALIGNED_SIZE    = SIZE / STRB_WIDTH;

    // (* RAM_STYLE="BLOCK" *)
    DATA_T mem [ALIGNED_SIZE-1:0];

    logic [ALIGNED_WIDTH-1:0] aligned;

    initial begin
        for (int i = 0; i < ALIGNED_SIZE; i++) begin
{%- for word in words %}
            mem[{{ loop.index - 1 }}] = 32'h{{ "{:08X}".format(word) }};
{%- endfor %}
        end
    end

    assign aligned = addr[ADDR_WIDTH-1:UNALIGNED_WIDTH];

    always_ff @(posedge seq.clk) begin
        for (int i = 0; i < STRB_WIDTH; i++) begin
            if (!req || aligned > ALIGNED_SIZE) begin
                rdata[i*8 +: 8] <= '0;
            end
            else if (we && be[i]) begin
                //mem[aligned][i*8 +: 8] <= wdata[i*8 +: 8];
                rdata[i*8 +: 8]        <= wdata[i*8 +: 8];
            end
            else begin
                rdata[i*8 +: 8] <= mem[aligned][i*8 +: 8];
            end
        end
    end

endmodule
""")


def gen_rom(
    input_file: Path,
    output_file: Path,
    output_format: str,
    module_name: str
):
    with open(input_file, "rb") as f:
        elf = ELFFile(f)

        addr_width = 32
        data_width = elf.elfclass  # Get the ELF address width (32 or 64)
        wl = data_width // 8  # word length

        data = []
        for section in elf.iter_sections():
            if section["sh_type"] != "SHT_PROGBITS":
                continue
            if ~section["sh_flags"] & SH_FLAGS.SHF_ALLOC:
                continue

            print(section.name, len(section.data()))

            data += section.data()

    data += b"\x00" * (wl - (len(data) % wl))

    words = []
    while data:
        word = int.from_bytes(
            data[:wl], byteorder="little", signed=False
        )
        words += [word]
        data = data[wl:]

    args = {
        "module_name": module_name,
        "addr_width": addr_width,
        "data_width": data_width,
        "size": len(words)*wl,
        "words": words
    }

    if output_format == "coe":
        output_raw = coe_template.render(**args)
    elif output_format == "btxt":
        output_raw = btxt_template.render(**args)
    elif output_format == "htxt":
        output_raw = htxt_template.render(**args)
    elif output_format == "sverilog":
        output_raw = sverilog_template.render(**args)
    else:
        raise RuntimeError(f"Format not supported: {output_format}")

    output_file.write_text(output_raw, encoding="utf-8")
