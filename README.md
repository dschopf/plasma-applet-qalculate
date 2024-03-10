# plasma-applet-qalculate

Qalculate applet for the KDE Plasma 6 desktop, bringing the power of [libqalculate](http://qalculate.github.io/) to your desktop.

![Arch Linux](https://github.com/dschopf/plasma-applet-qalculate/actions/workflows/arch.yml/badge.svg)

## Screenshots
[![Screenshot1](https://images.pling.com/img/00/00/44/59/37/1155946/48e64ea6e7741fa132afa8f29c7951858422.png)](https://store.kde.org/p/1155946) [![Screenshot2](https://images.pling.com/img/00/00/44/59/37/1155946/cd20e40e2ec26f74592f06e5a4c739d9ed69.png)](https://store.kde.org/p/1155946)

## Packages

Packaged binaries are available Arch Linux. Installation through the default
Plasma KNewStuff3 system is also available at the [Pling Store](https://store.kde.org/p/1155946).

### Arch Linux

Install this AUR package: [plasma5-applets-qalculate](https://aur.archlinux.org/packages/plasma5-applets-qalculate/).

```bash
yay -Syu plasma5-applets-qalculate
```

## Building/Installing from source

If there is no package available for your distribution, you can try to compile the source code yourself.

```bash
git clone https://github.com/dschopf/plasma-applet-qalculate.git paqalc && cd paqalc
mkdir build && cd build
LIB=lib cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_LIBDIR="$LIB" -DKDE_INSTALL_LIBDIR="$LIB" ..
make -j$(nproc)
sudo make install
```

### Build dependencies

Please note that this might require additional packages which are not part of these instructions.

For Debian 9 "Stretch"/Ubuntu 18.04 LTS "Bionic Beaver" and above, these are specifically:

* g++
* cmake
* extra-cmake-modules
* gettext (required for translations)
* pkg-config
* qtdeclarative5-dev
* libkf5plasma-dev
* libqalculate-dev
* libreadline-dev

and can all be installed with a single command as follows:

`sudo apt install g++ cmake extra-cmake-modules gettext pkg-config qtdeclarative5-dev libkf5plasma-dev libqalculate-dev libreadline-dev`

