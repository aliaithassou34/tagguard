
.. _tutorial_fpga_bitstream:

=======================
FPGA Bitstream Tutorial
=======================

This tutorial shows how to generate and deploy a bitstream for an ADAM target.
The bitstream is the file you load into the FPGA to configure it with your
hardware design.

All commands are meant to be run inside the ADAM Docker container.

.. note::

   In this tutorial we use ``nexys_video`` as the example target.
   Replace it with your desired target when running commands.

Generating the Bitstream
========================

To generate a bitstream for your target FPGA, run:

.. code-block:: bash

   (adam) /adam $ adam build --dirty --target nexys_video

After the build completes, the resulting file will be available at:

.. code-block::

   work/build/targets/nexys_video/vivado/bitstream.bit

Flashing the FPGA
=================

In the commands below, ``bitstream.bit`` is used as a placeholder.
Be sure to replace it with the actual file path for your target.

Ensure that the device is plugged in before starting the container;
otherwise it may not be detected.

Once the bitstream is built, you can flash it onto the FPGA with:

.. code-block:: bash

   (adam) /adam $ adam run fpga -b bitstream.bit -d C4B

The ``-d`` option specifies which device to use.
You only need to provide a short, unique suffix of the device name
(for example, `C4B`).

If you are unsure which device to use, run the same command without the ``-d``
flag to list all connected devices. Example output:

.. code-block::

   ...
   Available hardware targets:
      localhost:3121/xilinx_tcf/Digilent/210249AE8C40
      localhost:3121/xilinx_tcf/Digilent/210276B063C4B

   ...

In this case, you can select the second device using:

.. code-block:: bash

   (adam) /adam $ adam run fpga -b bitstream.bit -d C4B

.. tip::

   You can also use the Vivado Hardware Manager GUI to see the list of
   available devices and select the correct one.

Physical Reset
==============

After the bitstream has been loaded, it is crucial to press the **CPU_RESET**
button on your **Nexys Video** board.
Failure to do so may result in the design not behaving as expected.

Troubleshooting
===============

If something goes wrong, you can open the Vivado project that was generated
during the build:

.. code-block:: bash

   (adam) /adam $ vivado work/build/targets/nexys_video/vivado/adam.xpr

.. warning::

   This Vivado project is automatically generated.
   Any changes you make directly inside Vivado may not persist the next time
   you rebuild the project.
