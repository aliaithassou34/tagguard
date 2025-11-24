#!/bin/bash

set -e

BUILD=0
ROOT=0
IMAGE="adam"

while [[ $# -gt 0 ]]; do
    case $1 in
        --build)
            BUILD=1
            shift
            ;;
        --root)
            ROOT=1
            shift
            ;;
        *)
            echo "Unknown parameter: $1"
            exit 1
            ;;
    esac
done

cd "$(dirname "$0")"

image_exists() {
    docker images --format "{{.Repository}}" |
        awk -v image="$IMAGE" '$0 == image {found=1} END {print found+0}'
}

if [[ $(image_exists) -eq 0 ]] || [[ $BUILD -eq 1 ]]; then
    docker build --build-arg JOBS=$(nproc) -t $IMAGE .
fi

RUN_CMD=(docker run -it --rm --network host --privileged)

if [ $ROOT -eq 0 ]; then
    RUN_CMD+=(-u $(id -u):$(id -g))
fi

RUN_CMD+=(-v "$PWD:/adam" -w /adam)

if [ ! -z "$DISPLAY" ]; then
    xhost +local:docker > /dev/null
    RUN_CMD+=(-v /tmp/.X11-unix:/tmp/.X11-unix \
        -e "DISPLAY=$DISPLAY")
fi

if [ ! -z "$ADAM_XILINX_PATH" ]; then
    RUN_CMD+=(-v "$ADAM_XILINX_PATH:/opt/xilinx:ro" \
        -e "ADAM_XILINX_PATH=/opt/xilinx")
fi

if [ ! -z "$ADAM_QUESTA_PATH" ]; then
    RUN_CMD+=(-v "$ADAM_QUESTA_PATH:/opt/questa:ro" \
        -e "ADAM_QUESTA_PATH=/opt/questa")
fi

if [ ! -z "$LM_LICENSE_PATH" ]; then
    RUN_CMD+=(-e "LM_LICENSE_PATH=$LM_LICENSE_PATH")
fi

RUN_CMD+=("$@" "$IMAGE")

# Execute docker run
"${RUN_CMD[@]}"
