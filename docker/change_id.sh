#!/bin/bash

USER_ID=$1
GID=$2
GROUP_NAME=$3
USER_TZ=$4
WS_FOLDER=$5
HOST_USER=$6
INPUT_GID=$7
SERIAL_MODE=${SERIAL_MODE:-none}
SERIAL_GID=${SERIAL_GID:-0}

if [[ -z "${WS_FOLDER}" ]]; then
  WS_FOLDER=/home/roscon/workspaces
fi

# Use this for debugging errors
#DO_ECHO="echo"
DO_ECHO=""

# Group ID might already exist, depending on OS
$DO_ECHO groupadd -g $GID $GROUP_NAME >& /dev/null
$DO_ECHO sed -i -e "s/^\(roscon:[^:]\):[0-9]*:[0-9]*/\1:$USER_ID:$GID/" /etc/passwd
# Modify all file and folders permissions to match the new user id and group id
# We also want to skip changing the ownership of the mounted folder under /home/motus
# for development purposes
$DO_ECHO find /home/roscon -path ${WS_FOLDER} -prune -o -exec chown $USER_ID:$GID {} \;

# Configure same timezone as host
$DO_ECHO ln -sf /usr/share/zoneinfo/$USER_TZ /etc/localtime

# Make a symbolic link between user names, so that symbolic links
# inside the shared folder are found in the docker container
$DO_ECHO cd /home
$DO_ECHO ln -s roscon $HOST_USER
$DO_ECHO chown -h $USER_ID:$GID $HOST_USER

# Setup APT for proxy configuration (allows working and building both at home & office)
if [ -n "$HTTP_PROXY" ]; then
    echo "Acquire::http::Proxy \"$HTTP_PROXY\";" > /etc/apt/apt.conf
fi
if [ -n "$HTTPS_PROXY" ]; then
    echo "Acquire::https::Proxy \"$HTTPS_PROXY\";" >> /etc/apt/apt.conf
fi

# Create group input, used for connecting joysticks to container
# Check if we have INPUT_GID
if [ "$INPUT_GID" != "0" ]; then
    $DO_ECHO groupadd -g "$INPUT_GID" input 2>/dev/null || true
    $DO_ECHO usermod -aG input roscon
fi

case "$SERIAL_MODE" in
    tcp)
        # macOS Docker Desktop runs containers inside a VM. Recreate the host
        # serial device as a PTY inside the container via the host socat bridge.
        socat -d -d \
          PTY,link=/dev/ttyACM0,rawer,echo=0,mode=660 \
          TCP:host.docker.internal:7070 \
          >/tmp/roscon2026-socat-container.log 2>&1 &
        SOCAT_PID=$!

        for _ in {1..50}; do
            [ -L /dev/ttyACM0 ] && break
            kill -0 "$SOCAT_PID" 2>/dev/null || break
            sleep 0.1
        done

        if [ -L /dev/ttyACM0 ]; then
            chown "$USER_ID:$GID" /dev/ttyACM0
            chown -h "$USER_ID:$GID" /dev/ttyACM0
        else
            echo "[ERROR] Failed to create /dev/ttyACM0" >&2
            exit 1
        fi
        ;;
    device)
        # Native Linux can pass the real device into the container. Add the
        # runtime user to the device group so su keeps access after login.
        if [ "$SERIAL_GID" != "0" ]; then
            SERIAL_GROUP=$(getent group "$SERIAL_GID" | cut -d: -f1)
            if [ -z "$SERIAL_GROUP" ]; then
                SERIAL_GROUP=hostserial
                groupadd -g "$SERIAL_GID" "$SERIAL_GROUP" 2>/dev/null || true
            fi
            usermod -aG "$SERIAL_GROUP" roscon
        fi
        ;;
    none)
        ;;
    *)
        echo "[WARN] Unknown SERIAL_MODE=$SERIAL_MODE, starting without serial setup" >&2
        ;;
esac
