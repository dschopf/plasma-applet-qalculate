# plasma-applet-qalculate

Qalculate applet for the KDE Plasma 5 desktop, bringing the power of [libqalculate](http://qalculate.github.io/) to your desktop.

![Tests Status](https://api.travis-ci.org/dschopf/plasma-applet-qalculate.svg?branch=master)

## Screenshots 
[![Screenshot1](https://cdn.pling.com/img/8/6/4/f/48e64ea6e7741fa132afa8f29c7951858422.png)](https://store.kde.org/p/1155946) [![Screenshot2](https://cdn.pling.com/img/6/8/a/a/cd20e40e2ec26f74592f06e5a4c739d9ed69.png)](https://store.kde.org/p/1155946)

## Packages

Packaged binaries are available for Ubuntu and Arch Linux. Installation through the default Plasma KNewStuff3 system is also available at the [Pling Store](https://store.kde.org/p/1155946).

### Ubuntu and derivatives

Ubuntu 18.04 LTS "Bionic", 19.04 "Disco" and 19.10 "Eoan" users can install the packages from [this PPA](https://launchpad.net/~dschopf/+archive/ubuntu/plasma-applet-qalculate) with the following two commands:

```bash
sudo add-apt-repository -yus ppa:dschopf/plasma-applet-qalculate
sudo apt install plasma-applet-qalculate
```

### Arch Linux

Install this AUR package: [plasma5-applets-qalculate](https://aur.archlinux.org/packages/plasma5-applets-qalculate/).

```bash
yay -Syu plasma5-applets-qalculate
```

## Building/Installing from source

If there is no package available for your distribution, you can try to compile the source code yourself.

> Care should be taken to first identify where your distribution keeps its libraries as there is no "one size fits all" option. For distributions which adhere closely to the [FHS 3.0 conventions](https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html) like Fedora and OpenSUSE this is usually `/usr/lib64` or `/usr/lib32` for multiarch installations (depending on the hardware), and `/usr/lib` for non-multiarch systems. Debian, Ubuntu and their derivatives (Linux Mint and many others) have instead opted for [multiarch tuples](https://wiki.debian.org/Multiarch/TheCaseForMultiarch) as their library directory names, specifically `/usr/lib/x86_64-linux-gnu` for 64-bit hardware and `/usr/lib/i386-linux-gnu/` for 32-bit hardware.
> One of the most reliable ways to determine what your library directory is called is the command `pkg-config --variable=libdir libqalculate`. If you find yours is not `/usr/lib`, change the LIB= part of the third line below to match, stripping /usr/ from the front. (e.g. LIB=lib64 or LIB=lib/x86_64/linux-gnu)

```bash
git clone https://github.com/dschopf/plasma-applet-qalculate.git paqalc && cd paqalc
mkdir build && cd build
LIB=lib cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_LIBDIR="$LIB" -DKDE_INSTALL_LIBDIR="$LIB" "-GUnix Makefiles" ..
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

