#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint tflite_flutter.podspec` to validate before publishing.
#

# Rebuid Tensorflow Lite C library if does not exist. This requires
# the pod install to be run twice in order for the build library
# to be included in the final application build.
build_tensorflow_lite_c = <<-EOS
set -e
PLATFORM_LIBRARY="$(cd -P ${PODS_TARGET_SRCROOT} && pwd)/libtensorflowlite_c-${PLATFORM_NAME}.dylib"
if [[ ! -e ${PLATFORM_LIBRARY} ]]; then
  echo "\n\n**** The Tensorflow Lite C library has not been built. It needs to"
  echo "**** be built manually and should exist in the following location."
  echo "****     => ${PLATFORM_LIBRARY}"
  exit 1
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
  s.author           = { 'LetterAssist, LLC' => 'mevan.samaratunga@letterassist.ai' }

  s.source              = { :path => '.' }
  s.source_files        = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'

  s.script_phase = {
    :name => 'Check for Tensorflow Lite library',
    :script => build_tensorflow_lite_c,
    :execution_position => :before_compile
  }

  s.vendored_libraries = "libtensorflowlite_c-#{ENV["PLATFORM_NAME"]}.dylib"

  s.dependency 'FlutterMacOS'
  s.platform = :osx, '14.4'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
