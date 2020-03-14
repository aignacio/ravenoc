cmake_minimum_required(VERSION 3.3)

project(raveNoC VERSION "1.0.0")

add_executable(raveNoC src/hello.cpp)

configure_file("${PROJECT_SOURCE_DIR}/inc/ravenNoCConfig.h.in" ravenNoCConfig.h)

target_include_directories(${PROJECT_NAME} PUBLIC
                           "${PROJECT_SOURCE_DIR}/inc"
                           "${PROJECT_SOURCE_DIR}/src"
                           "${PROJECT_BINARY_DIR}")

set(CMAKE_CXX_FLAGS "-pthread")

set(CMAKE_CXX_STANDARD 11)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_CXX_EXTENSIONS OFF)

set(SYSTEMC_VERSION systemc-2.3.3)

set(SYSTEMC_LIB /opt/${SYSTEMC_VERSION}/build/src/libsystemc.so)

target_link_libraries(${PROJECT_NAME}
                      ${SYSTEMC_LIB})

message("Supported features = ${CMAKE_CXX_COMPILE_FEATURES}")
