FROM archlinux:base-devel

RUN pacman -Syu --noconfirm --noprogressbar && \
        pacman -Syq --noconfirm --noprogressbar \
	cmake \
	extra-cmake-modules \
	libqalculate \
	plasma-sdk \
	qt6-declarative

COPY build_plugin.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
