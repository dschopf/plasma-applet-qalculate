#!/bin/sh
set -ev
rm -rf build
mkdir build
cd build
cmake .. \
	-DCMAKE_INSTALL_PREFIX=/usr \
	-DCMAKE_BUILD_TYPE=Debug \
	-DCMAKE_CXX_FLAGS=-Werror \
	-DKDE_INSTALL_LIBDIR=lib \
	-DKDE_INSTALL_USE_QT_SYS_PATHS=ON \
	-DENABLE_TESTS=ON
make
bin/QalculateTests
