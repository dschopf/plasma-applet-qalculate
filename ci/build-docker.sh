#!/bin/sh

docker build -t paq_arch -f arch_linux.dockerfile .
docker tag paq_arch:latest schopfdan/paq_arch:latest
docker push schopfdan/paq_arch:latest

docker build -t paq_ubuntu:18.04 -f ubuntu_18.04.dockerfile .
docker tag paq_ubuntu:18.04 schopfdan/paq_ubuntu:18.04
docker push schopfdan/paq_ubuntu:18.04

docker build -t paq_ubuntu:19.04 -f ubuntu_19.04.dockerfile .
docker tag paq_ubuntu:19.04 schopfdan/paq_ubuntu:19.04
docker push schopfdan/paq_ubuntu:19.04

docker build -t paq_ubuntu:19.10 -f ubuntu_19.10.dockerfile .
docker tag paq_ubuntu:19.10 schopfdan/paq_ubuntu:19.10
docker push schopfdan/paq_ubuntu:19.10
