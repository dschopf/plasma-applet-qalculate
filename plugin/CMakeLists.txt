find_package(PkgConfig)
pkg_check_modules (QALCULATE REQUIRED libqalculate)
pkg_check_modules (QALCULATE_NEW QUIET libqalculate>=0.9.8)

IF (${QALCULATE_NEW_FOUND})
    add_definitions(-DHAVE_QALCULATE_0_9_8)
ENDIF (${QALCULATE_NEW_FOUND})

kde_enable_exceptions()

set(plasmoidplugin_SRCS plasmoidplugin.cpp qwrapper.cpp)

add_library(plasmoidplugin SHARED ${plasmoidplugin_SRCS})

target_link_libraries(plasmoidplugin Qt5::Quick KF5::Plasma cln qalculate)

install(TARGETS plasmoidplugin DESTINATION ${QML_INSTALL_DIR}/org/kde/private/qalculate)

install(FILES qmldir DESTINATION ${QML_INSTALL_DIR}/org/kde/private/qalculate)
