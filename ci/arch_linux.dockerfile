FROM archlinux/base

RUN pacman -Syq --noconfirm --noprogressbar \
	cmake \
	extra-cmake-modules \
	gcc \
	gettext \
	libqalculate \
	make \
	pkg-config \
	plasma-framework \
	qt5-base

ENTRYPOINT ["/bin/bash"]

WORKDIR /qalculate
