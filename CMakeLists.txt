project(Qalculate)

# Set minimum CMake version (required for CMake 3.0 or later)
cmake_minimum_required(VERSION 2.8.12 FATAL_ERROR)

set(QT_MIN_VERSION "5.4.0")
set(KF5_MIN_VERSION "5.0.0")

# Use Extra CMake Modules (ECM) for common functionality.
# See http://api.kde.org/ecm/manual/ecm.7.html
# and http://api.kde.org/ecm/manual/ecm-kde-modules.7.html
find_package(ECM REQUIRED NO_MODULE)
# Needed by find_package(KF5Plasma) below.
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${ECM_KDE_MODULE_DIR} ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings)

# Locate plasma_install_package macro.
find_package(Qt5 ${QT_MIN_VERSION} CONFIG REQUIRED Quick)
find_package(KF5Plasma ${KF5_MIN_VERSION} REQUIRED)

add_subdirectory(plugin)
add_subdirectory(translations)

# Add installatation target ("make install").
plasma_install_package(plasmoid org.kde.plasma.qalculate)
