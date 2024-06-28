#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flensorflowlite.podspec` to validate before publishing.
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

  #
  # Comment/Uncomment one of the following lines to include the
  # Tensorflow Lite C library for the correct runtime platform.
  #
  s.ios.vendored_libraries = "libtensorflowlite_c-iphonesimulator.dylib"
  # s.ios.vendored_libraries = "libtensorflowlite_c-iphoneos.dylib"

  s.dependency 'Flutter'
  s.platform = :ios, '17.4'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  s.swift_version = '5.0'
end
