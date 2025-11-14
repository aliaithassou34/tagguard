
.. _tutorial_setup:

==============
Setup Tutorial
==============

Welcome to the first step in your journey with ADAM!
This tutorial will guide you through setting up your development environment.
By the end of this guide, you'll have all the necessary tools installed and be
ready to dive into software or hardware development with ADAM.

Prerequisites
=============

This section describes the prerequisites for ADAM.
For the software developers, you will only need Docker.
For the hardware developers, you will also need Vivado and ModelSim.

Docker
------

1. Go to the `Docker <https://www.docker.com/>`_ website and follow the
   instructions to install Docker on your system.

2. Don't forget to follow the post installation steps. This will allow you to
   run Docker without `sudo`.
   See the `guide <https://docs.docker.com/install/linux/linux-postinstall/>`_.

Vivado
------

1. Go to the `Xilinx <https://www.xilinx.com/>`_ website and follow the
   instructions to install Vivado on your system.

2. Export the ``ADAM_XILINX_PATH`` environment variable to the Xilinx folder
   containing the Vivado installation. For example:

.. code-block:: bash

   export ADAM_XILINX_PATH=/tools/Xilinx

This is usually added to the ``.bashrc`` file, like the following:

.. code-block:: bash

   echo "export ADAM_XILINX_PATH=/tools/Xilinx" >> ~/.bashrc

Questa
------

.. note::

   You may use **ModelSim** or **Questa** as your simulator.
   The Student Edition by Intel of either is also suitable.
   Regardless of which one you choose, the environment variable must be named
   ``ADAM_QUESTA_PATH``.
   For example, if you're using ModelSim:

   .. code-block:: bash

      export ADAM_QUESTA_PATH=/opt/modelsim

1. Install Questa on your system.

2. Export the ``ADAM_QUESTA_PATH`` environment variable to the Questa folder
   containing the ModelSim installation. For example:

.. code-block:: bash

   export ADAM_QUESTA_PATH=/opt/questa

This is usually added to the ``.bashrc`` file, like the following:

.. code-block:: bash

   echo "export ADAM_QUESTA_PATH=/opt/questa" >> ~/.bashrc

3. Set up your license.

The variable ``LM_LICENSE_FILE`` must be set inside the container.

- Network license server:
  Point ``LM_LICENSE_FILE`` to the server address.

- Local license file:
  Your license file must be accessible inside the container.
  One solution is to place the license file in the folder you passed
  as ``ADAM_QUESTA_PATH``.
  This folder will be mounted inside the container at ``/opt/questa``.

The variable ``LM_LICENSE_FILE`` must be set inside the container.

.. code-block:: bash

   export LM_LICENSE_FILE=/opt/questa/LR-XXXXXX_License.dat

This is usually added to the ``.bashrc`` file, like the following:

.. code-block:: bash

   echo "export LM_LICENSE_FILE=/opt/questa/LR-XXXXXX_License.dat" >> ~/.bashrc

.. note::

   If ``LM_LICENSE_FILE`` is defined when launching
   ``./docker.sh``, it will be exposed to the container with the same value.

   This should work fine for network licenses.
   For file-based licenses, you must ensure the license file is placed
   somewhere accessible inside the container and redefine the variable
   accordingly.

   You may automate this by adding the export to the container ``.bashrc``
   located in ``<adam>/work/.bashrc`` (you may need to create this file).

Cloning the ADAM Repository
===========================

With the prerequisites in place, proceed to clone ADAM's Git Repository:

.. code-block:: bash

   git clone git@gite.lirmm.fr:adac/adam/adam.git
   cd adam

Building the Docker Image
=========================

Build the ADAM Docker image using the provided script for a consistent
development environment:

.. code-block:: bash

   ./docker.sh --build

This script not only builds the Docker image but also automatically launches
an interactive container session, denoted by the prompt ``(adam) /adam $``.
Note that using the ``--build`` flag forces a rebuild of the Docker image,
which can be time-consuming.
For future sessions, simply entering the environment is as easy as running
the script without the ``--build`` flag.
:ref:`Read more <docker_bash>`.

To exit the interactive Docker container session, type ``exit`` at the
command prompt.

Verifying the Installation
==========================

.. warning::

   Ensure you are operating within the interactive Docker container session
   for the following verification steps.

To confirm your setup is correct, perform the following checks:

1. **adam**: Ensure you can run the :ref:`adam` command:

   .. code-block:: bash

      adam --help

   You should see the script's help message.

2. **Vivado**: For hardware developers, verify Vivado installation by checking
   its version.

   .. code-block:: bash

      vivado -version

   This command should display the Vivado version, confirming its availability.

3. **ModelSim**: For hardware developers, verify ModelSim installation by
   checking its version.

   .. code-block:: bash

      vsim -version

   This command should display the ModelSim version,
   confirming its availability.

Building the World (Optional)
=============================

With your environment working, you might want to build everything at once.
**We advise against doing this**, because it compiles all tests, bitstreams,
and software — which can take a very long time.

If you still want to do it:

.. code-block:: bash

   (adam) /adam $ adam build

During normal development, it’s better to build only what you need.
For example, to run all VUnit testbenches for a specific target:

.. code-block:: bash

   (adam) /adam $ adam build --dirty --target nexys_video_vunit

The ``--dirty`` flag enables incremental builds without cleaning the
previous build, which speeds up iteration.

What's Next?
============

With your environment now ready, you can move on to the next tutorial that
aligns with your interests.

Happy developing!
