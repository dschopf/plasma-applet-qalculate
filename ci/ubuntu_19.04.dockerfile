FROM ubuntu:19.04

RUN apt-get update \
    && apt-get install -y -qq --no-install-recommends \
	cmake \
	extra-cmake-modules \
	g++ \
	gettext \
	libkf5plasma-dev \
	libqalculate-dev \
	libreadline-dev \
	pkg-config \
	qt5-default \
	qt5-qmake \
	qtdeclarative5-dev \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/bin/bash"]

WORKDIR /qalculate
