find_package(PkgConfig)
pkg_check_modules (QALCULATE REQUIRED libqalculate>=0.9.8)

kde_enable_exceptions()

set(plasmoidplugin_SRCS plasmoidplugin.cpp qwrapper.cpp)
set (CMAKE_CXX_STANDARD 11)

add_library(plasmoidplugin SHARED ${plasmoidplugin_SRCS})

target_link_libraries(plasmoidplugin Qt5::Quick KF5::Plasma cln qalculate pthread)

install(TARGETS plasmoidplugin DESTINATION ${QML_INSTALL_DIR}/org/kde/private/qalculate)

install(FILES qmldir DESTINATION ${QML_INSTALL_DIR}/org/kde/private/qalculate)
