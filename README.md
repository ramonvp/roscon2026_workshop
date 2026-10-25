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
<img src="images/platformio_ide.png" alt="PlatformIO IDE" width="300">

You might need to install this extra package:

```
sudo apt install python3-venv
```

Afterwards, you will have a new icon on the left vertical bar:
<img src="images/platformio_icon.png" alt="PlatformIO icon" height="250">

Open PlatformIO and Create New Project.

In the Wizard, select:
Name: arduino_ros2serial
Board: Arduino UNO
Framework: Arduino
