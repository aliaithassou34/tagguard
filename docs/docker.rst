.. _docker:

======
Docker
======

The ``docker.sh`` script simplifies the setup and usage of Docker containers
for the project.
It automates the process of building a Docker image, launching a container
with the appropriate configurations, and mounting project directories to enable
seamless development and testing within the containerized environment.
This script provides a convenient way to ensure consistency and
reproducibility in project development, making it easier to collaborate and
work across different systems.

Running with Default Configurations
===================================

For the impatient developer who just wants to dive in and start working.
Run the following command within the project's root directory:

.. code-block:: bash

   $ ./docker.sh

Building the Image
==================

The script checks if the Docker image already exists.
If the image does not exist or if the ``--build`` flag is used, the script
builds the image using the project's Dockerfile.
Importantly, it's worth noting that the script does not solely rely on
Docker's cache system to automatically build when changes occur because any
changes to the project will trigger a rebuild.
Instead, it gives the developer control over when to trigger a rebuild through
this flag.

Volume Mounts
=============

Executing the ``docker.sh`` script overlays your current project folder
onto the one in ``/adam``, enabling seamless project work within the
container.

Keep in mind that the container's ``/adam/work`` and ADAM's ``./work``
directories are distinct. ``/adam/work`` is your working directory inside the
container, while ``./work`` in ADAM holds auto-generated files, like
bitstreams.

.. warning::

    Any changes made to directories that are not mounted when
    running the container will be discarded upon container exit.

Vendor Tools
============

To facilitate the use of vendor-specific tools,
the ``docker.sh`` script provides a mechanism to define the paths of these
tools on your host system via environment variables.

Should you need to use Questa or Xilinx Vivado within the container,
it's possible to assign the relevant environment variable to the installation
path of the tool on your host system. The script will then link this path to
the corresponding location inside the container,
also setting the environment variable within the container to reflect this
path.

The vendor tools currently supported are:

- ``ADAM_QUESTA_PATH`` for Questa
- ``ADAM_XILINX_PATH`` for Vivado

This setup ensures a smooth operation of vendor tools within the Docker
container.
To incorporate more vendor tools into the container,
the script can be adjusted by appending similar code sections to link the
necessary paths and establish the appropriate environment variables.

To simplify the process of setting up paths for vendor tools, you can modify
your host user's ``.bashrc`` file to automatically define these paths whenever
you open a terminal session.
This approach ensures seamless integration of vendor tools without the need to
specify paths each time.

Here's an example of what to add to your ``.bashrc`` file:

.. code-block:: bash

    export ADAM_QUESTA_PATH="/opt/altera/24.1std/questa_fse"
    export ADAM_XILINX_PATH="/tools/Xilinx"

Running as Root
===============

You can run the container as the root user by using the ``--root`` flag.
This is useful when you need elevated privileges, such as installing packages
with ``apt``, or if there are issues with permissions.

X11 Display Support
===================

The script enables X11 display forwarding when the ``$DISPLAY``
environment variable is specified.
On Linux systems with graphical interfaces, the ``$DISPLAY`` environment
variable is typically set automatically.
