cmake_minimum_required(VERSION 3.16 FATAL_ERROR)

project(Qalculate)

set(QT_MIN_VERSION "6.6.0")
set(KF6_MIN_VERSION "6.0.0")

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

cmake_policy(SET CMP0160 OLD)
set(CMAKE_POLICY_DEFAULT_CMP0160 OLD)

find_package(ECM ${KF6_MIN_VERSION} REQUIRED NO_MODULE)

set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/.cmake)
find_package(PkgConfig)
find_package(Readline)

pkg_check_modules(QALCULATE REQUIRED libqalculate>=3.3.0)
pkg_check_modules(MPFR REQUIRED mpfr)

include(CMakePackageConfigHelpers)
include(ECMQmlModule)
include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)

find_package(Qt6 ${QT_MIN_VERSION} CONFIG REQUIRED Qml)
find_package(KF6 ${KF6_MIN_VERSION} REQUIRED I18n)
find_package(Plasma ${PROJECT_DEP_VERSION} REQUIRED)

set(CMAKE_CXX_FLAGS
    "${CMAKE_CXX_FLAGS} -Wall -Werror -Wno-error=maybe-uninitialized")
set(APPLET_NAME "com.dschopf.plasma.qalculate")

option(ENABLE_TESTS "Enable unit tests" OFF)
add_feature_info(ENABLE_TESTS ENABLE_TESTS
                 "Enables the building of unit tests.")

plasma_install_package(package ${APPLET_NAME})

ecm_add_qml_module(qalculateplugin URI ${APPLET_NAME})

kde_enable_exceptions()

target_sources(
  qalculateplugin PRIVATE plugin/preprocessor.cpp plugin/qalculate.cpp
                          plugin/qalculateplugin.cpp plugin/qwrapper.cpp)

target_include_directories(qalculateplugin PRIVATE ${Readline_INCLUDE_DIR})

target_link_libraries(
  qalculateplugin PRIVATE KF6::I18n ${QALCULATE_LIBRARIES} Qt::Qml
                          ${MPFR_LIBRARIES} ${Readline_LIBRARY})

if(NOT GETTEXT_FOUND)
  message(WARNING "msgfmt not found. Translations will *not* be installed")
else()

  file(GLOB PO_FILES translate/*.po)

  set(catalogname plasma_applet_${APPLET_NAME})
  set(GMO_FILES)

  foreach(po_file ${PO_FILES})
    get_filename_component(lang_code ${po_file} NAME_WE)
    set(gmo_file ${CMAKE_CURRENT_BINARY_DIR}/${catalogname}_${lang_code}.gmo)
    add_custom_command(
      OUTPUT ${gmo_file}
      COMMAND ${GETTEXT_MSGFMT_EXECUTABLE} --check -o ${gmo_file} ${po_file}
      DEPENDS ${po_file}
      WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
      VERBATIM)
    install(
      FILES ${gmo_file}
      DESTINATION ${KDE_INSTALL_FULL_LOCALEDIR}/${lang_code}/LC_MESSAGES/
      RENAME ${catalogname}.mo)
    list(APPEND GMO_FILES ${gmo_file})
  endforeach()

  add_custom_target(translations DEPENDS ${GMO_FILES})

endif()

add_dependencies(qalculateplugin translations)
ecm_finalize_qml_module(qalculateplugin)

if(ENABLE_TESTS)
  add_subdirectory(plugin/tests)
endif()

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
