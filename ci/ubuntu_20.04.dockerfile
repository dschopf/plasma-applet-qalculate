FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y -qq --no-install-recommends \
	cmake \
	extra-cmake-modules \
	g++ \
	gettext \
	libkf5plasma-dev \
	libqalculate-dev \
	libreadline-dev \
	make \
	pkg-config \
	qt5-default \
	qt5-qmake \
	qtdeclarative5-dev \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/bin/bash"]

WORKDIR /qalculate
