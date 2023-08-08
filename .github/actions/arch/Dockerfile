FROM archlinux:base-devel

RUN pacman -Syu --noconfirm --noprogressbar && \
        pacman -Syq --noconfirm --noprogressbar \
	cmake \
	extra-cmake-modules \
	libqalculate \
	plasma-framework \
	qt5-declarative

COPY build_plugin.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
