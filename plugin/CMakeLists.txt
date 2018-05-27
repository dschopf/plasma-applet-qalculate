find_package(PkgConfig)
find_package(Readline)

pkg_check_modules(QALCULATE REQUIRED libqalculate>=0.9.8)
pkg_check_modules(QALCULATE_2_0 QUIET libqalculate>=2.0.0)
pkg_check_modules(QALCULATE_2_5 QUIET libqalculate>=2.5.0)

kde_enable_exceptions()

set(plasmoidplugin_SRCS plasmoidplugin.cpp qwrapper.cpp)
set(CMAKE_CXX_STANDARD 11)

add_library(plasmoidplugin SHARED ${plasmoidplugin_SRCS})

include_directories(${Readline_INCLUDE_DIR})

IF (${QALCULATE_2_5_FOUND})
  add_definitions(-DHAVE_QALCULATE_2_5_0)
  target_link_libraries(plasmoidplugin Qt5::Quick KF5::Plasma qalculate pthread ${Readline_LIBRARY})
ELSEIF (${QALCULATE_2_0_FOUND})
  add_definitions(-DHAVE_QALCULATE_2_0_0)
  target_link_libraries(plasmoidplugin Qt5::Quick KF5::Plasma qalculate pthread ${Readline_LIBRARY})
ELSE (${QALCULATE_2_5_FOUND})
  target_link_libraries(plasmoidplugin Qt5::Quick KF5::Plasma qalculate pthread cln ${Readline_LIBRARY})
ENDIF (${QALCULATE_2_5_FOUND})

set(CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -Wall")

install(TARGETS plasmoidplugin DESTINATION ${QML_INSTALL_DIR}/org/kde/private/qalculate)
install(FILES qmldir DESTINATION ${QML_INSTALL_DIR}/org/kde/private/qalculate)
