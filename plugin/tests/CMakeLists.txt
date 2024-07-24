find_package(GTest REQUIRED)

enable_testing()

add_executable(
  QalculateTests
  helpers.cpp
  main.cpp
  preprocessor_assign.cpp
  ../preprocessor.cpp
  ../qalculate.cpp
)

target_compile_definitions(QalculateTests PRIVATE ENABLE_TESTS)
target_compile_options(QalculateTests PRIVATE -fsanitize=address)
target_link_options(QalculateTests PRIVATE -fsanitize=address)

target_link_libraries(
  QalculateTests
  PRIVATE
  GTest::gtest
  GTest::gmock
  KF6::I18n
  Qt6::Network
  qalculate
  mpfr
  ${Readline_LIBRARY}
)

include(GoogleTest)
gtest_discover_tests(QalculateTests)
