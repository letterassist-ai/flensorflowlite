# flensorflowlite

A new Flutter FFI plugin project.

## Getting Started

This project is a starting point for a Flutter
[FFI plugin](https://docs.flutter.dev/development/platform-integration/c-interop),
a specialized package that includes native code directly invoked with Dart FFI.

## Project structure

This template uses the following structure:

* `src`: Contains the native source code, and a CmakeFile.txt file for building
  that source code into a dynamic library.

* `lib`: Contains the Dart code that defines the API of the plugin, and which
  calls into the native code using `dart:ffi`.

* platform folders (`android`, `ios`, `windows`, etc.): Contains the build files
  for building and bundling the native code library with the platform application.

## Building and bundling native code

### Apple Platforms

The `tensorflowlite_c` library needs to be built and exist alongside the `macos` or `ios` podspec.
Use the commands below to build the library which will be vendored when the Pod for the respective
platform is installed. The build commands must be run from the repository root.

* Build for MacOS

```
SRCROOT=$(pwd) \
PODS_TARGET_SRCROOT=$(pwd)/macos \
PLATFORM_NAME=macosx \
  src/cmake/build-apple.sh
```

* Build for iPhone simulator

```
SRCROOT=$(pwd) \
PODS_TARGET_SRCROOT=$(pwd)/ios \
PLATFORM_NAME=iphonesimulator \
  src/cmake/build-apple.sh
```

* Build for iPhone device

```
SRCROOT=$(pwd) \
PODS_TARGET_SRCROOT=$(pwd)/ios \
PLATFORM_NAME=iphoneos \
  src/cmake/build-apple.sh
```
