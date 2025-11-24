.. _tutorial_simulation:

===================
Simulation Tutorial
===================

Simulation is a crucial step in the development of hardware for ADAM.
It allows you to test your designs and code before deploying them to the
actual hardware.

In ADAM, simulation is fully integrated into the build system through **CMake**.
You normally don’t invoke `cmake` directly—instead, you use the ``adam``
command line interface, which provides higher-level commands for building
and running testbenches.

One essential tool for simulation and verification in ADAM is
`VUnit <http://vunit.github.io/>`_ —
an open-source framework widely used for verification of VHDL and
SystemVerilog designs. It simplifies the process of creating, managing, and
running testbenches, making it an essential tool for verifying hardware
designs.

.. note::

   This tutorial assumes you have already completed the
   :ref:`Setup Tutorial <tutorial_setup>` and can run commands inside the
   interactive Docker container (``(adam) /adam $`` prompt).

How to Run All Testbenches
==========================

To run all VUnit testbenches for a given target, use the ``adam build``
command with the ``--target`` flag.
For example, to test the ``nexys_video`` target:

.. code-block:: bash

   (adam) /adam $ adam build --dirty --target nexys_video --enable-vunit

The ``--dirty`` flag enables incremental builds without cleaning the
previous build, which makes development much faster.

How to Run a Single Testbench
=============================

To focus on a single testbench (e.g. when debugging), use the
``adam run vunit`` utility.

For example, to run the ``minimal`` test case of the ``adam_tb`` SystemVerilog
testbench on the ``nexys_video`` target:

.. code-block:: bash

   (adam) /adam $ adam run vunit --target nexys_video --top adam_tb.minimal

If you see a message like ``No tests were run``, it usually means the name
you passed to ``--top`` doesn’t exist.
If you’re working on a new testbench, you may have forgotten to add it to
the **CMake project**.

Visualizing Traces
==================

If you want to open the testbench in the Questa graphical interface to
inspect waveforms and debug, add the ``-g`` flag:

.. code-block:: bash

   (adam) /adam $ adam run vunit --target nexys_video --top adam_tb.minimal -g

Writing Your Own Testbenches
============================

To create a SystemVerilog testbench:

1. Create a new file in the ``bhv/`` directory.

   - The filename must end with ``_tb.sv`` so that VUnit recognizes it as a
     testbench.

   - As a starting point, you can copy an existing simple testbench:

     - Minimal example: ``bhv/adam_clk_div_tb.sv``
     - AXI4-Lite example: ``bhv/axil/adam_axil_skid_tb.sv``

2. Register the testbench in the CMake project
   by editing ``bhv/CMakeLists.txt``.

   - SystemVerilog files must be listed in dependency order.
   - In most cases, you can safely add your testbench at the end of the list.

3. Run the testbench.

   For example, if your testbench is ``bhv/my_own_tb.sv``, you can run it and
   view the waveforms with:

   .. code-block:: bash

      (adam) /adam $ adam run vunit --target nexys_video --top my_own_tb -g

For more details on writing VUnit testbenches, see the
`VUnit User Guide — SystemVerilog Test Benches
<https://vunit.github.io/user_guide.html#systemverilog-test-benches>`_.

------

At this point, you know how to:

- Run all testbenches for a target.
- Run an individual testbench for a target.
- Visualize traces in Questa.
- Create your own testbenches.
