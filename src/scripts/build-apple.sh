#!/bin/sh
set -eox pipefail

MIN_IPHONEOS_VERSION=11.0
MIN_MACOSX_VERSION=14.0

#
# XCode build sets PLATFORM_NAME to the
# target platform to build for
#
if [[ -z $PLATFORM_NAME ]]; then
  echo "Apple XCode build PLATFORM_NAME is not set"
  exit 1
fi

#
# Note: SRCROOT == <Flutter App>/macos/Pods
#
if [[ -z $SRCROOT ]]; then
  echo "Apple XCode build SRCROOT is not set"
  exit 1
fi

#
# This is the path to where the Flutter
# plugin's podspec is located
#
if [[ -z $PODS_TARGET_SRCROOT ]]; then
  echo "Apple XCode build PODS_TARGET_SRCROOT is not set"
  exit 1
fi

set -u

plugin_build_dir=${SRCROOT}/build/flensorflowlite
mkdir -p ${plugin_build_dir}
env > ${plugin_build_dir}/env.log

plugin_src_root="$(cd -P $(dirname ${PODS_TARGET_SRCROOT}) && pwd)/src"
if [[ ! -d ${plugin_src_root} ]]; then
  echo "Flutter plugin source root not found: ${plugin_src_root}"
  exit 1
fi

build_library() {
  local platform=$1
  local arch=$2

  local platform_build_arch

  local platform_build_dir=${plugin_build_dir}/${platform}/build
  if [[ -d ${platform_build_dir} ]]; then
    rm -rf ${platform_build_dir}/CMakeFiles
    rm -f ${platform_build_dir}/CMakeCache.txt
    rm -f ${platform_build_dir}/Makefile
    rm -f ${platform_build_dir}/cmake_install.cmake
  else
    mkdir -p ${platform_build_dir}
  fi

  local platform_dist_dir=${plugin_build_dir}/${platform}/dist/${arch}
  mkdir -p ${platform_dist_dir}

  # Create an Apple toolchain file

  local sdk_path=`xcrun --sdk $platform --show-sdk-path`
  local sdk_version=$(echo "$(basename ${sdk_path})" | awk -F'[a-zA-Z.]+' '{print $2 "." $3}')
  local clang=`xcrun --sdk $platform --find clang`
  local clang_plusplus=`xcrun --sdk $platform --find clang++`
  local target=""

  case $platform in
    macosx)
      target="-target ${arch}-apple-macos${MIN_MACOSX_VERSION}"
      ;;
    iphonesimulator)
      target="-target ${arch}-apple-ios${MIN_IPHONEOS_VERSION}-simulator"
      ;;
    iphoneos)
      target="-target ${arch}-apple-ios${MIN_IPHONEOS_VERSION}"
      ;;
    *)
      echo "Unsupported platform: $platform"
      exit 1
      ;;
  esac
  if [[ (! ' arm64 x86_64 ' =~ $arch) ]]; then
    echo "Unsupported architecture: $arch"
    exit 1
  fi

  local cmake_toolchain_file=${platform_build_dir}/toolchain-${platform}-${arch}.cmake
  cat <<EOF >${cmake_toolchain_file}
if(DARWIN_TOOLCHAIN_INCLUDED)
  return()
endif(DARWIN_TOOLCHAIN_INCLUDED)
set(DARWIN_TOOLCHAIN_INCLUDED true)

set(CMAKE_SYSTEM_NAME Darwin)
set(CMAKE_OSX_SYSROOT $sdk_path)
set(CMAKE_OSX_ARCHITECTURES $arch CACHE INTERNAL "" FORCE)
set(CMAKE_SYSTEM_PROCESSOR $arch CACHE INTERNAL "" FORCE)
set(CMAKE_C_COMPILER $clang)
set(CMAKE_CXX_COMPILER $clang_plusplus)
set(CMAKE_C_FLAGS "\${CMAKE_C_FLAGS} $target -isysroot $sdk_path")
set(CMAKE_CXX_FLAGS "\${CMAKE_CXX_FLAGS} $target -isysroot $sdk_path")
EOF

  # Configure and build the library

  cmake -S ${plugin_src_root} -B ${platform_build_dir} \
    -DCMAKE_TOOLCHAIN_FILE=${cmake_toolchain_file} \
    -DCMAKE_LIBRARY_OUTPUT_DIRECTORY=${platform_dist_dir} \
    -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=${platform_dist_dir}

  cmake --build ${platform_build_dir} -j
  cp -f ${platform_build_dir}/tensorflow/tensorflow-lite/libtensorflow-lite.a ${platform_dist_dir}
}

create_platform_library() {
  local platform_dist_dir=$1
  local input_file_name=$2
  local ouput_file=${3:-$(dirname ${platform_dist_dir})/${input_file_name}}

  mkdir -p $(dirname ${ouput_file})

  archs=( $(ls "${platform_dist_dir}") )
  if [[ ${#archs[@]} -eq 1 ]]; then
    cp -f \
      ${platform_dist_dir}/${archs[0]}/${input_file_name} \
      ${ouput_file}

  elif [[ ${#archs[@]} -gt 1 ]]; then
    rm -f ${ouput_file}
    local lipo_args=(-create)
    for arch in ${archs[@]}; do
      lipo_args+=("${platform_dist_dir}/${arch}/${input_file_name}")
    done
    lipo_args+=(-output ${ouput_file})
    lipo ${lipo_args[@]}

  else
    echo "No built library architectures found for ${platform}"
    exit 1
  fi
}

zip_artifact() {
  local path=$1
  local dest=${2:-$(dirname ${path})}

  local dir=$(dirname ${path})
  local zip_name=$(basename ${path})

  pushd ${dir}
  rm -f ${dest}/${zip_name}.zip
  zip -r ${zip_name}.zip ${zip_name}
  popd
}

create_framework() {
  local platform=$1

  # Create framework
  local framework_name="flensorflowlite"

  framework_dir=${PODS_TARGET_SRCROOT}/${framework_name}.framework
  rm -rf ${framework_dir}
  mkdir -p ${framework_dir}

  # Create the framework directory structure
  framework_structure=(
    "Versions/A/Headers"
    "Versions/A/Modules"
    "Versions/A/Resources"
  )

  for dir in ${framework_structure[@]}; do
    mkdir -p ${framework_dir}/${dir}
    ln -s ${framework_dir}/Versions/Current/Headers ${framework_dir}/$(basename ${dir})
  done

  # Copy headers
  cp ${plugin_src_root}/tensorflow_lite/*.h ${framework_dir}/Versions/A/Headers

  # Create symlinks
  ln -s ${framework_dir}/Versions/A ${framework_dir}/Versions/Current
  ln -s ${framework_dir}/Versions/Current/${framework_name} ${framework_dir}/${framework_name}

  # Create framework library
  local platform_dist_dir=${plugin_build_dir}/${platform}/dist
  local ouput_file=${framework_dir}/Versions/A/${framework_name}

  create_platform_library "${platform_dist_dir}" "libtensorflowlite_c.dylib" "${ouput_file}"

  echo "Built framework: ${framework_name}"
}


case $PLATFORM_NAME in
  macosx|iphonesimulator|iphoneos)
    build_library $PLATFORM_NAME arm64
    if [[ $PLATFORM_NAME != "iphoneos" ]]; then
      # Build for x86_64 on for non iPhoneOS platforms
      build_library $PLATFORM_NAME x86_64
    fi
    ;;
  *)
    echo "Unsupported platform: $PLATFORM_NAME"
    exit 1
    ;;
esac

create_platform_library \
  "${plugin_build_dir}/${PLATFORM_NAME}/dist" \
  "libtensorflowlite_c.dylib" \
  "${PODS_TARGET_SRCROOT}/libtensorflowlite_c.dylib"
