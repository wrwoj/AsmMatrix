cmake_minimum_required(VERSION 3.10)
project(untitled1)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3")
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -O3")

enable_language(ASM_NASM)

# Find NASM
find_program(NASM_EXECUTABLE NAMES nasm)
if (NOT NASM_EXECUTABLE)
    message(FATAL_ERROR "NASM assembler not found!")
endif()

# Detect platform and set NASM flags accordingly
if (WIN32)
    set(CMAKE_ASM_NASM_FLAGS "-f win64")
elseif (UNIX)
    set(CMAKE_ASM_NASM_FLAGS "-f elf64")
endif()

# Enable debugging symbols
set(CMAKE_BUILD_TYPE Debug)  # Ensure Debug mode
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -g")  # Enable debugging for C++
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -g")      # Enable debugging for C

# Ensure NASM debugging flags are correct
if (WIN32)
    set(CMAKE_ASM_NASM_FLAGS "-f win64 -gcv8")  # CodeView debugging for Windows
elseif (UNIX)
    set(CMAKE_ASM_NASM_FLAGS "-f elf64 -g -Fdwarf")  # DWARF debugging for UNIX
endif()


set(SOURCE_FILES main.cpp matrix.asm)
add_executable(untitled1 ${SOURCE_FILES})
