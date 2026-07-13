#!/bin/bash

DOCKER_USER=roscon
DOCKER_IMAGE=${DOCKER_IMAGE:-ghcr.io/ramonvp/roscon2026_workshop:latest}
SHARED_FOLDER=$HOME/workspaces
FOLDER_NAME=$(echo $SHARED_FOLDER | rev | cut -d "/" -f 1 | rev)
INPUT_GID=0
HOST_OS=$(uname -s)
SERIAL_DEVICE=${SERIAL_DEVICE:-}
SERIAL_PORT=7070
SOCAT_LOG=/tmp/roscon2026-socat-host.log
SOCAT_PID=
SERIAL_MODE=none
SERIAL_GID=0
DOCKER_DEVICE_ARGS=()

cleanup() {
  if [ -n "$SOCAT_PID" ]; then
    kill "$SOCAT_PID" 2>/dev/null || true
    wait "$SOCAT_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

if [ -z "$SERIAL_DEVICE" ]; then
  case "$HOST_OS" in
    Darwin)
      SERIAL_DEVICE=/dev/cu.usbmodem101
      ;;
    Linux)
      SERIAL_DEVICE=/dev/ttyACM0
      ;;
  esac
fi

case "$HOST_OS" in
  Darwin)
    # Docker Desktop runs containers inside a VM, so expose the host serial
    # device through TCP and recreate /dev/ttyACM0 inside the container.
    if [ -e "$SERIAL_DEVICE" ]; then
      echo "Device $SERIAL_DEVICE found, forwarding to TCP port $SERIAL_PORT"
      socat -d -d \
        "TCP-LISTEN:$SERIAL_PORT,reuseaddr" \
        "FILE:$SERIAL_DEVICE,rawer,echo=0,ispeed=115200,ospeed=115200" \
        >"$SOCAT_LOG" 2>&1 &
      SOCAT_PID=$!
      SERIAL_MODE=tcp
    else
      echo "Device $SERIAL_DEVICE not found, starting without serial forwarding"
    fi
    ;;
  Linux)
    if [ -e "$SERIAL_DEVICE" ]; then
      echo "Device $SERIAL_DEVICE found, sharing it with the container"
      SERIAL_MODE=device
      SERIAL_GID=$(stat -c "%g" "$SERIAL_DEVICE")
      DOCKER_DEVICE_ARGS=(--device "$SERIAL_DEVICE:/dev/ttyACM0")
    else
      echo "Device $SERIAL_DEVICE not found, starting without serial device"
    fi
    ;;
  *)
    echo "Unsupported host OS $HOST_OS, starting without serial device"
    ;;
esac

docker run \
    -it \
    --rm \
    "${DOCKER_DEVICE_ARGS[@]}" \
    --mount type=bind,src="$SHARED_FOLDER",dst="/home/$DOCKER_USER/$FOLDER_NAME" \
    --env HOST_USER=$USER \
    --env DOCKER_USER=$DOCKER_USER \
    --env SHARED_FOLDER=/home/$DOCKER_USER/$FOLDER_NAME \
    --env USER_UID=$(id -u) \
    --env USER_GID=$(id -g) \
    --env USER_GN=$(id -gn) \
    --env USER_TZ=$(ls -al /etc/localtime | rev | cut -d "/" -f 1-2 | rev) \
    --env INPUT_GID=$INPUT_GID \
    --env SERIAL_MODE=$SERIAL_MODE \
    --env SERIAL_GID=$SERIAL_GID \
    --env TERM=${TERM:-xterm-256color} \
    --env HTTP_PROXY=$HTTP_PROXY \
    --env http_proxy=$HTTP_PROXY \
    --env HTTPS_PROXY=$HTTPS_PROXY \
    --env no_proxy=127.0.0.1,localhost \
    "$DOCKER_IMAGE"
