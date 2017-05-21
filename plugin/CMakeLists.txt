find_package(PkgConfig)
find_package(Readline)

pkg_check_modules(QALCULATE REQUIRED libqalculate>=0.9.8)
kde_enable_exceptions()

set(plasmoidplugin_SRCS plasmoidplugin.cpp qwrapper.cpp)
set(CMAKE_CXX_STANDARD 11)

add_library(plasmoidplugin SHARED ${plasmoidplugin_SRCS})

include_directories(${Readline_INCLUDE_DIR})

target_link_libraries(plasmoidplugin Qt5::Quick KF5::Plasma cln qalculate pthread ${Readline_LIBRARY})

install(TARGETS plasmoidplugin DESTINATION ${QML_INSTALL_DIR}/org/kde/private/qalculate)
install(FILES qmldir DESTINATION ${QML_INSTALL_DIR}/org/kde/private/qalculate)
