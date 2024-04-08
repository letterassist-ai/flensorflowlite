#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint tflite_flutter.podspec` to validate before publishing.
#

# Rebuid Tensorflow Lite C library if does not exist. This requires
# the pod install to be run twice in order for the build library
# to be included in the final application build.
build_tensorflow_lite_c = <<-EOS
set -e
if [[ ! -e ${PODS_TARGET_SRCROOT}/libtensorflowlite_c.dylib ]]; then
  plugin_src_root="$(cd -P $(dirname ${PODS_TARGET_SRCROOT}) && pwd)"
  source ${plugin_src_root}/src/scripts/build-apple.sh

  set +x
  echo "\n\n**** The Tensorflow Lite C has been built and saved to:"
  echo "****     => $(cd -P ${PODS_TARGET_SRCROOT} && pwd)."
  echo "****\n**** Please re-run a clean build to add library to application.\n\n"
fi
EOS

Pod::Spec.new do |s|
  s.name             = 'flensorflowlite'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin for Tensorflow Lite library.'
  s.description      = <<-DESC
Flutter Tensorflow Lite FFI plugin library.
                       DESC
  s.homepage         = 'https://github.com/tensorflow/flutter-tflite'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  s.source              = { :path => '.' }
  s.source_files        = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'

  s.script_phase = {
    :name => 'Build Tensorflow Lite Source',
    :script => build_tensorflow_lite_c,
    :execution_position => :before_compile
  }

  s.vendored_libraries = 'libtensorflowlite_c.dylib'

  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.11'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
