cmake_minimum_required(VERSION 3.10)

project(kuma_security C)

add_library(kuma_security SHARED kuma_security.c)

target_compile_options(kuma_security PRIVATE
    -fvisibility=hidden
    -ffunction-sections
    -fdata-sections
    -O2)

# Strip all symbols on release builds so internals aren't exposed in a binary dump
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -s")
set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} -Wl,--gc-sections -Wl,--strip-all")

if(CMAKE_BUILD_TYPE STREQUAL "Release")
    target_link_options(kuma_security PRIVATE -Wl,--strip-all)
endif()
