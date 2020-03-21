cmake_minimum_required(VERSION 3.3)

project(raveNoC VERSION "1.0.0")

file(GLOB noc_src "src/*.cpp"
		  "inc/*.h")

set(SYSTEMC_INSTALL_FOLDER /opt)

set(SYSTEMC_VERSION systemc-2.3.3)

add_compile_options (-fdiagnostics-color=always)

add_executable(raveNoC ${noc_src})

configure_file("${PROJECT_SOURCE_DIR}/inc/ravenNoCConfig.h.in" ravenNoCConfig.h)

target_include_directories(${PROJECT_NAME} PUBLIC
                           "${PROJECT_SOURCE_DIR}/inc"
                           "${PROJECT_SOURCE_DIR}/src"
                           "${PROJECT_BINARY_DIR}"
			   "${SYSTEMC_INSTALL_FOLDER}/${SYSTEMC_VERSION}/src")

set(CMAKE_CXX_FLAGS "-pthread -g -Og")

set(CMAKE_CXX_STANDARD 11)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_CXX_EXTENSIONS OFF)

set(SYSTEMC_LIB /opt/${SYSTEMC_VERSION}/build/src/libsystemc.so)


target_link_libraries(${PROJECT_NAME}
                      ${SYSTEMC_LIB})

message("Supported C++ features = ${CMAKE_CXX_COMPILE_FEATURES}")

#message("After generating the build system, pls run $cmake --build ., inside the output files")
