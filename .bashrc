# NOTE:
# This is the built-in .bashrc used inside the Docker image.
# It is shared by everyone and committed to the repository.
#
# Do NOT modify this file for personal or local setup tweaks.
# Instead, create a local file at:
#     work/.bashrc
# That file (if present) will be automatically loaded and
# is intentionally excluded from version control.

mkdir -p /adam/work

export HOME="/adam/work"

export ADAM_SOURCE_DIR="/adam"
export ADAM_BUILD_DIR="$HOME/build"

if [ -n "$ADAM_XILINX_PATH" ]; then
    # Old layout: $ADAM_XILINX_PATH/Vivado/<version>/
    if [ -d "$ADAM_XILINX_PATH/Vivado" ]; then
        VER=$(ls "$ADAM_XILINX_PATH/Vivado" | sort -V | tail -n 1)
        export PATH="$PATH:$ADAM_XILINX_PATH/Vivado/$VER/bin"
    # New layout: $ADAM_XILINX_PATH/<version>/Vivado/
    else
        VER=$(ls "$ADAM_XILINX_PATH" | grep -E '^[0-9]+' | sort -V | tail -n 1)
        export PATH="$PATH:$ADAM_XILINX_PATH/$VER/Vivado/bin"
    fi
fi

if [ ! -z "$ADAM_QUESTA_PATH" ]; then
    export PATH="$ADAM_QUESTA_PATH/bin:$PATH"
fi

if [ ! -d "$HOME/.venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv "$HOME/.venv"
    "$HOME/.venv/bin/pip" install -e /adam/python
fi

export PATH="$HOME/.venv/bin:$PATH"

export HISTCONTROL=ignoredups
export HISTFILE="$HOME/.bash_history"
export HISTFILESIZE=100000
export HISTSIZE=1000

PS1="(adam) \$(pwd) \\$ "

git config --global --add safe.directory '*'

if [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc"
fi
