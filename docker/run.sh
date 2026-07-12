#!/bin/bash

DOCKER_USER=roscon
SHARED_FOLDER=$HOME/workspaces
FOLDER_NAME=$(echo $SHARED_FOLDER | rev | cut -d "/" -f 1 | rev)
INPUT_GID=0
SERIAL_DEVICE=/dev/cu.usbmodem101
SERIAL_PORT=7070
SOCAT_LOG=/tmp/roscon2026-socat-host.log
SOCAT_PID=

cleanup() {
  if [ -n "$SOCAT_PID" ]; then
    kill "$SOCAT_PID" 2>/dev/null || true
    wait "$SOCAT_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

# If the serial device is connected, forward it to the container over TCP.
if [ -e "$SERIAL_DEVICE" ]; then
  echo "Device $SERIAL_DEVICE found, forwarding to TCP port $SERIAL_PORT"
  socat -d -d \
    "TCP-LISTEN:$SERIAL_PORT,reuseaddr" \
    "FILE:$SERIAL_DEVICE,rawer,echo=0,ispeed=115200,ospeed=115200" \
    >"$SOCAT_LOG" 2>&1 &
  SOCAT_PID=$!
fi

docker run \
    -it \
    --rm \
    --mount type=bind,src="$SHARED_FOLDER",dst="/home/$DOCKER_USER/$FOLDER_NAME" \
    --env HOST_USER=$USER \
    --env DOCKER_USER=$DOCKER_USER \
    --env SHARED_FOLDER=/home/$DOCKER_USER/$FOLDER_NAME \
    --env USER_UID=$(id -u) \
    --env USER_GID=$(id -g) \
    --env USER_GN=$(id -gn) \
    --env USER_TZ=$(ls -al /etc/localtime | rev | cut -d "/" -f 1-2 | rev) \
    --env INPUT_GID=$INPUT_GID \
    --env HTTP_PROXY=$HTTP_PROXY \
    --env http_proxy=$HTTP_PROXY \
    --env HTTPS_PROXY=$HTTPS_PROXY \
    --env no_proxy=127.0.0.1,localhost \
    ghcr.io/ramonvp/roscon2026:latest
