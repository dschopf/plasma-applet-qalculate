kde_enable_exceptions()

set(plasmoidplugin_SRCS plasmoidplugin.cpp qwrapper.cpp)

add_library(plasmoidplugin SHARED ${plasmoidplugin_SRCS})

target_link_libraries(plasmoidplugin Qt5::Quick KF5::Plasma cln qalculate)

install(TARGETS plasmoidplugin DESTINATION ${QML_INSTALL_DIR}/org/kde/private/qalculate)

install(FILES qmldir DESTINATION ${QML_INSTALL_DIR}/org/kde/private/qalculate)
