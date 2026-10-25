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


## Setup PlatformIO
Create a directory for the embedded code and open Visual Studio Code inside:

```
mkdir -p arduino_ros2serial
code -n arduino_ros2serial
```

In VS Code, install the plugin named "PlatformIO IDE".
[[https://github.com/ramonvp/roscon2026_workshop/blob/main/images/platformio_ide.png|alt=platformio_ide]]

You might need to install this extra package:

```
sudo apt install python3-venv
```

Afterwards, you will have a new icon on the left vertical bar:
[[https://github.com/ramonvp/roscon2026_workshop/blob/main/images/platformio_icon.png|alt=platformio_icon]]

Open PlatformIO and Create New Project.

In the Wizard, select:
Name: arduino_ros2serial
Board: Arduino UNO
Framework: Arduino
