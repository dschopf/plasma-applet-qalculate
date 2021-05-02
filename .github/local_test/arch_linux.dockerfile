FROM archlinux:base-devel

RUN echo $'\
Server = https://mirror.23media.com/archlinux/$repo/os/$arch \n\
Server = https://arch.jensgutermuth.de/$repo/os/$arch \n\
Server = https://ftp.halifax.rwth-aachen.de/archlinux/$repo/os/$arch \n\
Server = https://mirror.chaoticum.net/arch/$repo/os/$arch \n\
Server = https://mirror.orbit-os.com/archlinux/$repo/os/$arch \n\
Server = https://arch.unixpeople.org/$repo/os/$arch \n\
Server = https://mirror.checkdomain.de/archlinux/$repo/os/$arch \n\
Server = https://mirror.metalgamer.eu/archlinux/$repo/os/$arch \n\
Server = https://appuals.com/archlinux/$repo/os/$arch \n\
Server = https://mirror.ubrco.de/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist

RUN pacman -Syq --noconfirm --noprogressbar \
	cmake \
	extra-cmake-modules \
	libqalculate \
	plasma-framework \
	qt5-declarative

ENTRYPOINT ["/bin/bash"]

WORKDIR /qalculate
