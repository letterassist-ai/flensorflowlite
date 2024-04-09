# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH};${CMAKE_CURRENT_SOURCE_DIR}/cmake")

include(FetchContent)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED True)

set(LIB flensorflowlite)

project(${LIB}_library LANGUAGES C CXX)

get_filename_component(ROOT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/.. ABSOLUTE)

# Set policies
cmake_policy(SET CMP0135 NEW) # Allow downloading files without DOWNLOAD_EXTRACT_TIMESTAMP option
cmake_policy(SET CMP0079 NEW) # Allow setting of target link libraries for builds in subdirectories

# A future Abseil release will default ABSL_PROPAGATE_CXX_STD to ON,
# but for now we need to set it explicitly.
set(ABSL_PROPAGATE_CXX_STD ON)

# Fetch the TensorFlow source code
FetchContent_Declare(
  tensorflow
  GIT_REPOSITORY https://github.com/tensorflow/tensorflow.git
  GIT_TAG        v2.16.1
)
if(NOT tensorflow_POPULATED)
  FetchContent_Populate(tensorflow)
endif()
FetchContent_GetProperties(tensorflow)

# Apply patches to the TensorFlow CMake build tree where necessary
if (APPLE AND DEFINED ENV{PLATFORM_NAME})
  # Updated tensorflowlite_c CMakeLists.txt to
  # build a named shared library for apple only
  configure_file(
    ${CMAKE_SOURCE_DIR}/cmake/patch.apple.tensorflow.CMakeLists_txt
    ${tensorflow_SOURCE_DIR}/tensorflow/lite/c/CMakeLists.txt
    COPYONLY
  )
  # Fixes error "install TARGETS given no BUNDLE
  # DESTINATION for MACOSX_BUNDLE executable"
  configure_file(
    ${CMAKE_SOURCE_DIR}/cmake/patch.apple.tensorflow.flatbuffers_cmake
    ${tensorflow_SOURCE_DIR}/tensorflow/lite/tools/cmake/modules/flatbuffers.cmake
    COPYONLY
  )
  set(TENSORFLOW_LITE_C_LIB "tensorflowlite_c-$ENV{PLATFORM_NAME}")
endif()

# Create the TensorFlow Lite C library build target
add_subdirectory(
  ${tensorflow_SOURCE_DIR}/tensorflow/lite/c
  "${CMAKE_BINARY_DIR}/tensorflow"
)

if (APPLE AND DEFINED ENV{PLATFORM_NAME})
  set(OSX_PLATFORM $ENV{PLATFORM_NAME})
  message(STATUS "Building for a Apple (Darwin) OS platform $ENV{PLATFORM_NAME}.")

  set(CMAKE_LINK_LIBRARY_USING_FRAMEWORK TRUE)

  # For iOS ensure core frameworks are linked
  target_link_libraries(${TENSORFLOW_LITE_C_LIB} "-framework Foundation")
  target_link_libraries(${TENSORFLOW_LITE_C_LIB} "-framework CoreFoundation")
  target_compile_definitions(${TENSORFLOW_LITE_C_LIB} PUBLIC DART_SHARED_LIB)
else()
  target_compile_definitions(tensorflowlite_c PUBLIC DART_SHARED_LIB)
endif()

