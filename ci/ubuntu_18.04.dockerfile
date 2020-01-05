FROM ubuntu:18.04

RUN apt-get update \
    && apt-get install -y -qq --no-install-recommends \
	cmake \
	extra-cmake-modules \
	g++ \
	gettext \
	libqalculate-dev \
	libreadline-dev \
	pkg-config \
	plasma-framework-dev \
	qt5-default \
	qt5-qmake \
	qtdeclarative5-dev \
    && rm -rf /var/lib/apt/lists/*


ENTRYPOINT ["/bin/bash"]

WORKDIR /qalculate
