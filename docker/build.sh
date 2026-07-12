#!/bin/bash

REGISTRY=ghcr.io/ramonvp
IMAGE_NAME=roscon2026
version=1.0.0

usage() {
   echo "Builds the Docker image for ROS2 used in ros2serial workshop at ROSCon 2026"
   echo
   echo "Usage: $0 [OPTIONS]"
   echo
   echo "Options:"
   echo "  -v <version>  Specify the version to build, if not provided,"
   echo "                by default it is set to 1.0.0"
   echo "  -r <registry> Specify docker registry. Use 'local' to build without a registry"
   echo "  -l            Also tag the image as latest"
   echo "  -p            Push the newly built image to the registry"
   echo "  -c            Build image without cache"
   echo "  -d            Enable debug logging"
}

# Define if the image will be built for multiple architectures (amd64 and arm64)
# and pushed to the registry, or built only for the local architecture and loaded 
# into the local Docker images. By default, the image will be built only for the 
# local architecture and loaded into the local Docker images.
MULTI_ARCH=false
PUSH=false
extra_args=()

# Get arguments from command line
while getopts "v:r:lpcdm" options; do
   case "${options}" in
      v)
         version=$OPTARG
         ;;
      r)
         if [ "$OPTARG" = "local" ]; then
            REGISTRY=""
         else
            REGISTRY=$OPTARG
         fi
         ;;
      l)
         latest=1
         ;;
      p)
         PUSH=true
         ;;
      c)
         extra_args+=(--no-cache)
         ;;
      d)
         extra_args+=(--debug)
         ;;
      m)
         MULTI_ARCH=true
         ;;         
      *)
         echo "Invalid option: -$OPTARG" >&2
         usage 1>&2
         exit 1
         ;;
   esac
done

if [ -z "$version" ]; then
   echo 'Missing version -v or image_version.txt does not exist' >&2
   usage 1>&2
   exit 1
fi

# Check Docker
if ! command -v docker >/dev/null 2>&1; then
    echo "[ERROR] Docker is not installed."
    exit 1
fi

# Check Buildx
if ! docker buildx version >/dev/null 2>&1; then
    echo "[ERROR] Docker Buildx is not available."
    echo
    echo "Install instructions:"
    echo "  Linux (Debian/Ubuntu): sudo apt-get install docker-buildx"
    echo "  macOS (Docker Desktop): already included"
    echo "  macOS (Homebrew Docker CLI): brew install docker-buildx"
    exit 1
fi

# Ensure a builder exists
if ! docker buildx inspect >/dev/null 2>&1; then
    echo "[INFO] Creating Docker Buildx builder..."
    docker buildx create --name multiarch_builder --use >/dev/null
fi

# Ensure builder is initialized
docker buildx inspect --bootstrap >/dev/null

# Ensure binfmt is registered for multi-arch builds
docker run --privileged --rm tonistiigi/binfmt --install all >/dev/null 2>&1 || true

echo
echo "**********************************"
echo "Building version: $version"
echo "**********************************"


if [ -z "$REGISTRY" ]; then
    FULL_IMAGE_NAME="$IMAGE_NAME"
else
    FULL_IMAGE_NAME="$REGISTRY/$IMAGE_NAME"
fi

if [ "$PUSH" = true ]; then
    if [ -z "$REGISTRY" ]; then
        echo "[ERROR] Cannot push when using a local image name (-r local)." >&2
        exit 1
    fi
    if [ -z "$CR_PAT" ]; then
        echo "[ERROR] CR_PAT is not set." >&2
        exit 1
    fi

    if ! printf '%s' "$CR_PAT" | docker login ghcr.io --username ramonvp --password-stdin; then
        echo "[ERROR] Registry login failed." >&2
        exit 1
    fi
fi

if [ "$MULTI_ARCH" = true ]; then
    builder=(docker buildx build --platform linux/amd64,linux/arm64)
    if [ "$PUSH" = true ]; then
        builder+=(--push)
    fi
else
    builder=(docker build)
fi

tags=(--tag "$FULL_IMAGE_NAME:$version")
if [ "$latest" ]; then
    tags+=(--tag "$FULL_IMAGE_NAME:latest")
fi

# BuildKit's plain renderer only prints occasional status lines while exporting
# multi-platform layers. Its TTY renderer shows live push timers and activity.
PROGRESS_MODE=plain
if [ "$MULTI_ARCH" = true ] && [ "$PUSH" = true ] && [ -t 1 ]; then
    PROGRESS_MODE=tty
fi

# -e: Exit immediately if a command exits with a non-zero status.
# -x: Print commands and their arguments as they are executed. Authentication is
# deliberately completed first so CR_PAT can never be included in traced output.
set -e -x

"${builder[@]}" \
   --progress="$PROGRESS_MODE" \
   --build-arg "HTTP_PROXY=$HTTP_PROXY" \
   --build-arg "HTTPS_PROXY=$HTTPS_PROXY" \
   --build-arg "VERSION=$version" \
   "${tags[@]}" \
   --file Dockerfile \
   "${extra_args[@]}" \
   .

if [ "$PUSH" = true ] && [ "$MULTI_ARCH" = false ]; then
   docker push "$FULL_IMAGE_NAME:$version"
   if [ "$latest" ]; then
      docker push "$FULL_IMAGE_NAME:latest"
   fi
fi

# Restore previous options
{ set +x +e; } 2> /dev/null
