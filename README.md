# plasma-applet-qalculate
Qalculate applet for the KDE5 plasma desktop. Brings the power of [libqalculate](http://qalculate.github.io/) to your desktop.

![Tests Status](https://api.travis-ci.org/dschopf/plasma-applet-qalculate.svg?branch=master)

# Install instructions

Packages are available for Ubuntu and Arch Linux.

## Ubuntu

Ubuntu 18.04, 19.04 and 19.10 users can get the packages from this PPA: https://launchpad.net/~dschopf/+archive/ubuntu/plasma-applet-qalculate

```
sudo add-apt-repository ppa:dschopf/plasma-applet-qalculate
sudo apt-get update
sudo apt-get install plasma-applet-qalculate
```

## Arch Linux

Install this AUR package: [plasma5-applets-qalculate](https://aur.archlinux.org/packages/plasma5-applets-qalculate/).

## Source installation

If there is no package available for your distribution, you can try to compile the source code yourself.

```
Shell
mkdir build
cd  build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release \
  -DKDE_INSTALL_LIBDIR=lib -DKDE_INSTALL_USE_QT_SYS_PATHS=ON
make
sudo make install
```

Please note that this might require additional packages which are not part of these instructions.

For Ubuntu 19.10 these are in detail:
* cmake
* g++
* extra-cmake-modules
* qt5-qmake
* qt5-default
* qtdeclarative5-dev
* libkf5plasma-dev
* pkg-config
* libreadline-dev
* gettext (required for translations)
* libqalculate-dev

`sudo apt install cmake g++ extra-cmake-modules qt5-qmake qt5-default qtdeclarative5-dev libkf5plasma-devlibkf5plasma-dev pkg-config libreadline-dev gettext libqalculate-dev`
