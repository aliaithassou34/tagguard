import random
from typing import Iterable

import numpy as np
import tensorflow as tf
import tensorflow_model_optimization as tfmot
from tensorflow import keras
from tensorflow.keras import layers

Data = tuple[np.ndarray, np.ndarray]

INPUT_SHAPE = (28, 28, 1)


class LeNet:
    def __init__(self):
        self.model: keras.Model | None = None
        self.quantized: bytes | None = None
        self.train_data: Data | None = None
        self.validation_data: Data | None = None
        self.test_data: Data | None = None

    def load_data(self):
        if (
            self.train_data is not None and
            self.validation_data is not None and
            self.test_data is not None
        ):
            return

        (x0, y0), (x1, y1) = keras.datasets.mnist.load_data()

        x0 = x0.reshape((-1, *INPUT_SHAPE))
        x1 = x1.reshape((-1, *INPUT_SHAPE))

        x0 = x0.astype(np.float32) / 255.0
        x1 = x1.astype(np.float32) / 255.0

        split = 0.1
        n = int(len(x0) * split)

        self.train_data = x0[:-n], y0[:-n]
        self.validation_data = x0[-n:], y0[-n:]
        self.test_data = x1, y1

    def representative_dataset(self) -> Iterable[list[np.ndarray]]:
        self.load_data()
        x_train = self.train_data[0]
        for i in range(300):
            yield [x_train[i:i+1].astype(np.float32)]

    def build_model(self):
        if self.model is not None:
            return

        inputs = keras.Input(shape=INPUT_SHAPE)
        x = layers.Conv2D(6, kernel_size=5, activation="relu")(inputs)
        x = layers.AveragePooling2D(pool_size=2)(x)
        x = layers.Conv2D(16, kernel_size=5, activation="relu")(x)
        x = layers.AveragePooling2D(pool_size=2)(x)
        x = layers.Flatten()(x)
        x = layers.Dense(120, activation="relu")(x)
        x = layers.Dense(84, activation="relu")(x)
        logits = layers.Dense(10)(x)

        self.model = keras.Model(inputs=inputs, outputs=logits)

        self.model = tfmot.quantization.keras.quantize_model(self.model)

        self.model.compile(
            optimizer="adam",
            loss=keras.losses.SparseCategoricalCrossentropy(from_logits=True),
            metrics=["accuracy"],
        )
        self.quantized = None

    def fit(self):
        self.build_model()
        self.load_data()
        self.model.fit(
            *self.train_data,
            epochs=10,
            batch_size=128,
            validation_data=self.validation_data,
            verbose=2,
        )
        self.quantized = None

    def evaluate(self) -> float:
        self.build_model()
        _, acc = self.model.evaluate(*self.test_data, verbose=2)
        return float(acc)

    def quantize(self):
        if self.quantized:
            return

        self.build_model()

        converter = tf.lite.TFLiteConverter.from_keras_model(self.model)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.representative_dataset = self.representative_dataset
        converter.target_spec.supported_ops = [
            tf.lite.OpsSet.TFLITE_BUILTINS_INT8
        ]
        converter.inference_input_type = tf.int8
        converter.inference_output_type = tf.int8

        self.quantized = converter.convert()

    def evaluate_quantized(self):
        self.quantize()
        self.load_data()

        x_test, y_test = self.test_data

        interpreter = tf.lite.Interpreter(model_content=self.quantized)
        interpreter.allocate_tensors()

        in_details = interpreter.get_input_details()[0]
        out_details = interpreter.get_output_details()[0]

        in_index = in_details["index"]
        out_index = out_details["index"]

        in_dtype = in_details["dtype"]
        out_dtype = out_details["dtype"]

        in_scale, in_zp = in_details["quantization"]
        out_scale, out_zp = out_details["quantization"]

        need_channel = (
            len(in_details.get("shape", [])) == 4 and
            in_details["shape"][-1] == 1
        )

        correct = 0
        total = len(x_test)

        for i, img in enumerate(x_test):
            x = img.astype(np.float32)
            if need_channel and x.ndim == 2:
                x = x[..., None]
            x = np.expand_dims(x, 0)

            if in_dtype in (np.int8, np.uint8):
                xq = np.round(x / in_scale + in_zp).astype(in_dtype)
                interpreter.set_tensor(in_index, xq)
            else:
                interpreter.set_tensor(in_index, x)

            interpreter.invoke()
            y = interpreter.get_tensor(out_index)

            if out_dtype in (np.int8, np.uint8):
                y = (y.astype(np.float32) - out_zp) * out_scale

            pred = int(np.argmax(y, axis=-1)[0])
            if pred == int(y_test[i]):
                correct += 1

        return correct / total


def main():
    seed = 42
    random.seed(seed)
    np.random.seed(seed)
    tf.random.set_seed(seed)

    ln = LeNet()

    ln.fit()
    ln.quantize()

    with open("lenet.tflite", "wb") as f:
        f.write(ln.quantized)


if __name__ == "__main__":
    main()
