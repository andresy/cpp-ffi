CMAKE_MINIMUM_REQUIRED(VERSION 2.6)
PROJECT(CPPFFI C)

if ("${CMAKE_C_COMPILER_ID}" STREQUAL "Clang")
  # using Clang
  MESSAGE("CLANG")
elseif ("${CMAKE_C_COMPILER_ID}" STREQUAL "GNU")
  MESSAGE("GCC")
  # using GCC
elseif ("${CMAKE_C_COMPILER_ID}" STREQUAL "Intel")
  MESSAGE("INTEL")
  # using Intel C++
elseif ("${CMAKE_C_COMPILER_ID}" STREQUAL "MSVC")
  MESSAGE("MSVC")
  # using Visual Studio C++
else ()
  message( FATAL_ERROR "Unsupported compiler" )
endif()
