cmake_minimum_required(VERSION 3.16)
project(config_manager_tests LANGUAGES CXX)


# Find Qt (change to Qt5 if your project uses Qt5)
find_package(Qt6 REQUIRED COMPONENTS Core Test Sql)


set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)


# Where the test sources are located (this CMakeLists.txt sits in tests/)
set(TEST_SOURCES
ConfigurationTest.cpp
TemplateManagerTest.cpp
ConfigurationModelTest.cpp
)


# If your main project builds a library target named 'configmanager', it will be linked automatically.
# Otherwise tests will include headers from ../src and you can link libraries manually.


foreach(src ${TEST_SOURCES})
get_filename_component(test_name ${src} NAME_WE)
add_executable(${test_name} ${src})
target_include_directories(${test_name} PRIVATE ${CMAKE_SOURCE_DIR}/../src)
target_link_libraries(${test_name} PRIVATE Qt6::Test Qt6::Core Qt6::Sql)


if(TARGET configmanager)
target_link_libraries(${test_name} PRIVATE configmanager)
endif()


add_test(NAME ${test_name} COMMAND ${test_name})
endforeach()


# Convenience target to run all tests with ctest --output-on-failure
add_custom_target(run-all-tests
COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure
DEPENDS ${TEST_SOURCES}
)