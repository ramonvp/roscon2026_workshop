FROM ros:jazzy-ros-base

ARG DEBIAN_FRONTEND=noninteractive
ARG USER_NAME=roscon
ARG HTTP_PROXY
ARG HTTPS_PROXY

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
        sudo \
        bash-completion \
        less \
        python3-colcon-common-extensions \
        python3-rosdep \
        git \
        socat \
        build-essential \
        libboost-system-dev \
        libboost-thread-dev \
        rapidjson-dev \
        ros-jazzy-rmw-zenoh-cpp \
        ros-jazzy-ament-cmake-vendor-package \
    && rm -rf /var/lib/apt/lists/*

RUN \
    test -n "$USER_NAME" && \
    useradd "$USER_NAME" --create-home --no-log-init -d "/home/$USER_NAME" -s /bin/bash && \
    echo "$USER_NAME:$USER_NAME" | chpasswd && \
    echo root:root | chpasswd && \
    adduser "$USER_NAME" sudo && \
    echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    touch "/home/$USER_NAME/.hushlogin"

# Set a prefix of the prompt inside the docker
RUN echo "workshop" > /etc/debian_chroot

COPY change_id.sh /
COPY bashrc /home/$USER_NAME/.bashrc
COPY bash_profile /home/$USER_NAME/.bash_profile
RUN chown "$USER_NAME:$USER_NAME" "/home/$USER_NAME/.bashrc" "/home/$USER_NAME/.bash_profile"
WORKDIR /home/$USER_NAME
# The following env is required, so that CMD finds the variable correctly
ENV USER_NAME=$USER_NAME
ENV SERIAL_MODE=none
ENV SERIAL_GID=0
ENV TERM=xterm-256color


# COPY src/ src/

# RUN source /opt/ros/jazzy/setup.bash \
#     && rosdep update \
#     && rosdep install \
#          --from-paths src \
#          --ignore-src \
#          --rosdistro jazzy \
#          -y \
#     && colcon build --symlink-install

# COPY docker/entrypoint.sh /entrypoint.sh
# RUN chmod +x /entrypoint.sh

# ENTRYPOINT ["/entrypoint.sh"]
# CMD ["bash"]

# Create a symbolic link between /Users and /home, so that the host can mount
# the /Users folder in macOS. Native Linux runs pass /dev/ttyACM0 directly.
RUN ln -s /home /Users

CMD ["/bin/bash", "-c", "/change_id.sh $USER_UID $USER_GID $USER_GN $USER_TZ $SHARED_FOLDER $HOST_USER $INPUT_GID && su - ${USER_NAME}"]

LABEL org.opencontainers.image.source=https://github.com/ramonvp/roscon2026_workshop
LABEL org.opencontainers.image.description="ROSCon 2026 workshop container image"
LABEL org.opencontainers.image.licenses=Apache-2.0
