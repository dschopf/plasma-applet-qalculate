#!/bin/sh

docker pull archlinux/base
docker build -t paq_arch -f arch_linux.dockerfile .
docker tag paq_arch:latest schopfdan/paq_arch:latest
docker push schopfdan/paq_arch:latest

docker pull ubuntu:18.04
docker build -t paq_ubuntu:18.04 -f ubuntu_18.04.dockerfile .
docker tag paq_ubuntu:18.04 schopfdan/paq_ubuntu:18.04
docker push schopfdan/paq_ubuntu:18.04

docker pull ubuntu:19.10
docker build -t paq_ubuntu:19.10 -f ubuntu_19.10.dockerfile .
docker tag paq_ubuntu:19.10 schopfdan/paq_ubuntu:19.10
docker push schopfdan/paq_ubuntu:19.10

docker pull ubuntu:20.04
docker build -t paq_ubuntu:20.04 -f ubuntu_20.04.dockerfile .
docker tag paq_ubuntu:20.04 schopfdan/paq_ubuntu:20.04
docker push schopfdan/paq_ubuntu:20.04
