# roscon2026_workshop
Material for ROSCon Valencia 2026

## Install on macOS

```
brew install socat
```

## Building the image

To support multi-arch images, you need to make sure you have docker-container drive enabled:

```
docker buildx ls
```

If you get a default - docker output, then create it:

```
docker buildx create --name multiarch --driver docker-container --use
docker buildx inspect --bootstrap
```
