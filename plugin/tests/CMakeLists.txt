find_package(GTest REQUIRED)

enable_testing()

add_executable(QalculateTests helpers.cpp main.cpp preprocessor_assign.cpp
                              ../Qalculate_PreProcessor.cpp ../Qalculate.cpp ../HistoryManager.cpp)

target_compile_definitions(QalculateTests PRIVATE ENABLE_TESTS)

# disable ASAN tests until upstream changes are released
#target_compile_options(QalculateTests PRIVATE -fsanitize=address)
#target_link_options(QalculateTests PRIVATE -fsanitize=address)

target_link_libraries(
  QalculateTests
  PRIVATE GTest::gtest
          GTest::gmock
          KF6::I18n
          Qt6::Network
          ${QALCULATE_LIBRARIES}
          ${MPFR_LIBRARIES})

include(GoogleTest)
gtest_discover_tests(QalculateTests)
