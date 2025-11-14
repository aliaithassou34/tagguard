import numpy as np
import struct
import tensorflow as tf
from zlib import crc32


def align(f, n):
    pos = f.tell()
    pad_len = (-pos) % n
    if pad_len:
        f.write(b"\x00" * pad_len)


def dump_tflite(
    model_content: bytes,
    input_values: list[np.ndarray]
):
    resolver_type = tf.lite.experimental.OpResolverType.BUILTIN_REF

    itp = tf.lite.Interpreter(
        model_content=model_content,
        experimental_preserve_all_tensors=True,
        experimental_delegates=[],
        experimental_op_resolver_type=resolver_type
    )
    itp.allocate_tensors()

    input_details = itp.get_input_details()

    if input_values:
        for d, v in zip(input_details, input_values):
            itp.set_tensor(d["index"], v)

        itp.invoke()

    tensor_details = itp.get_tensor_details()

    with open("tensors.bin", "wb") as f:
        for d in tensor_details:
            index = d["index"]

            print(d)

            data = itp.get_tensor(index).tobytes()

            if index == 19:
                print(itp.get_tensor(index))

            # checksum = crc32(data) & 0xFFFFFFFF
            # print(f"[{index}] checksum=0x{checksum:08x}")

            # if "const" not in d["name"]:
            #    continue

            shape = tuple(int(i) for i in d["shape"])
            # print(f"[{index}] shape={shape}")
            print(
                f"    /* {index:03} */ {len(shape)}, " +
                ", ".join(str(i) for i in shape) +
                ","
            )

            align(f, 4)
            offset = f.tell()
            print(f"[{index}] offset={offset}")
            f.write(data)


def main():
    from .lenet import LeNet

    ln = LeNet()

    ln.load_data()

    with open("lenet.tflite", "rb") as f:
        model = f.read()

    input = ln.test_data[0][0]

    input = (input / 0.003921568859368563) - 128
    input = input.astype(np.int8)[np.newaxis, ...]

    dump_tflite(model, [input])


if __name__ == "__main__":
    main()
