find_package(PkgConfig)
find_package(Readline)
find_package(KF5I18n)

pkg_check_modules(QALCULATE REQUIRED libqalculate>=0.9.8)
pkg_check_modules(QALCULATE_2_0 QUIET libqalculate>=2.0.0)
pkg_check_modules(QALCULATE_2_2 QUIET libqalculate>=2.2.0)
pkg_check_modules(QALCULATE_2_5 QUIET libqalculate>=2.5.0)
pkg_check_modules(QALCULATE_2_6 QUIET libqalculate>=2.6.0)

kde_enable_exceptions()

set(plasmoidplugin_SRCS conversion.cpp plasmoidplugin.cpp qalculate.cpp qwrapper.cpp)
set(CMAKE_CXX_STANDARD 17)

add_library(plasmoidplugin SHARED ${plasmoidplugin_SRCS})

include_directories(${Readline_INCLUDE_DIR})

target_link_libraries(plasmoidplugin KF5::I18n)

if(${QALCULATE_2_6_FOUND})
  add_definitions(-DHAVE_QALCULATE_2_6_0)
  target_link_libraries(
    plasmoidplugin
    Qt5::Quick
    KF5::Plasma
    qalculate
    pthread
    ${Readline_LIBRARY}
  )
elseif(${QALCULATE_2_5_FOUND})
  add_definitions(-DHAVE_QALCULATE_2_5_0)
  target_link_libraries(
    plasmoidplugin
    Qt5::Quick
    KF5::Plasma
    qalculate
    pthread
    ${Readline_LIBRARY}
  )
elseif(${QALCULATE_2_2_FOUND})
  add_definitions(-DHAVE_QALCULATE_2_2_0)
  target_link_libraries(
    plasmoidplugin
    Qt5::Quick
    KF5::Plasma
    qalculate
    pthread
    ${Readline_LIBRARY}
  )
elseif(${QALCULATE_2_0_FOUND})
  add_definitions(-DHAVE_QALCULATE_2_0_0)
  target_link_libraries(
    plasmoidplugin
    Qt5::Quick
    KF5::Plasma
    qalculate
    pthread
    ${Readline_LIBRARY}
  )
else(${QALCULATE_2_6_FOUND})
  target_link_libraries(
    plasmoidplugin
    Qt5::Quick
    KF5::Plasma
    qalculate
    pthread
    cln
    ${Readline_LIBRARY}
  )
endif(${QALCULATE_2_6_FOUND})

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Werror")

install(TARGETS plasmoidplugin
        DESTINATION ${QML_INSTALL_DIR}/org/kde/private/qalculate
)
install(FILES qmldir DESTINATION ${QML_INSTALL_DIR}/org/kde/private/qalculate)
