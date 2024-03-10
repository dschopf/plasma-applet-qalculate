cmake_minimum_required(VERSION 3.16 FATAL_ERROR)

project(Qalculate)

set(QT_MIN_VERSION "6.6.0")
set(KF6_MIN_VERSION 5.240.0)
set(KDE_COMPILERSETTINGS_LEVEL "5.82")

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(ECM ${KF6_MIN_VERSION} REQUIRED NO_MODULE)
find_package(PkgConfig)

set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/.cmake)
find_package(Readline)

pkg_check_modules(QALCULATE REQUIRED libqalculate>=0.9.8)
pkg_check_modules(QALCULATE_2_0 QUIET libqalculate>=2.0.0)
pkg_check_modules(QALCULATE_2_2 QUIET libqalculate>=2.2.0)
pkg_check_modules(QALCULATE_2_5 QUIET libqalculate>=2.5.0)
pkg_check_modules(QALCULATE_2_6 QUIET libqalculate>=2.6.0)

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(ECMQtDeclareLoggingCategory)
include(ECMGenerateExportHeader)
include(ECMInstallIcons)
include(KDEPackageAppTemplates)
include(GenerateExportHeader)
include(CMakePackageConfigHelpers)
include(KDEClangFormat)
include(KDEGitCommitHooks)
include(ECMDeprecationSettings)
include(ECMQmlModule)

find_package(Qt6 ${QT_MIN_VERSION} CONFIG REQUIRED Qml Quick)
find_package(KF6 ${KF6_MIN_VERSION} REQUIRED I18n)

find_package(Plasma5Support ${PROJECT_DEP_VERSION} REQUIRED)
find_package(Plasma ${PROJECT_DEP_VERSION} REQUIRED)
find_package(PlasmaQuick ${PROJECT_DEP_VERSION} REQUIRED)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Werror")

add_subdirectory(translations)

plasma_install_package(package org.kde.plasma.private.qalculate)

ecm_add_qml_module(qalculateplugin URI org.kde.plasma.private.qalculate)

kde_enable_exceptions()

target_sources(qalculateplugin
PRIVATE
    plugin/conversion.cpp
    plugin/plasmoidplugin.cpp
    plugin/qalculate.cpp
    plugin/qwrapper.cpp
)

target_include_directories(qalculateplugin
PRIVATE
  ${Readline_INCLUDE_DIR}
)

target_link_libraries(qalculateplugin
PRIVATE
  KF6::I18n
  qalculate
  Qt::Qml
  ${Readline_LIBRARY}
)

ecm_finalize_qml_module(qalculateplugin)

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)

# get_cmake_property(_variableNames VARIABLES)
# list (SORT _variableNames)
# foreach (_variableName ${_variableNames})
#     message(STATUS "${_variableName}=${${_variableName}}")
# endforeach()
