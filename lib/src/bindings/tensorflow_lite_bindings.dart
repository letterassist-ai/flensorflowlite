import 'dart:ffi';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

import 'tensorflow_lite_bindings_generated.dart';

/// The name of the dynamic library.
const String _libName = 'tensorflowlite_c';

/// TensorFlowLite Bindings
late final TensorFlowLiteBindings tfliteBinding;

/// TensorFlowLite Gpu Bindings
late final TensorFlowLiteBindings tfliteBindingGpu;

/// The dynamic library in which the symbols for [UserBindings] can be found.
Future<void> initTensorFlowLightBindings() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  if (Platform.isIOS) {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    if (iosInfo.isPhysicalDevice) {
      tfliteBinding = TensorFlowLiteBindings(
        DynamicLibrary.open(
          'lib$_libName-iphoneos.dylib',
        ),
      );
    } else {
      tfliteBinding = TensorFlowLiteBindings(
        DynamicLibrary.open(
          'lib$_libName-iphonesimulator.dylib',
        ),
      );
    }
  } else if (Platform.isAndroid || Platform.isLinux) {
    tfliteBinding = TensorFlowLiteBindings(
      DynamicLibrary.open(
        'lib$_libName.so',
      ),
    );
    tfliteBindingGpu = TensorFlowLiteBindings(
      DynamicLibrary.open(
        'libtensorflowlite_gpu_jni.so',
      ),
    );
  } else if (Platform.isMacOS) {
    tfliteBinding = TensorFlowLiteBindings(
      DynamicLibrary.open(
        'lib$_libName-macosx.dylib',
      ),
    );
  } else if (Platform.isWindows) {
    tfliteBinding = TensorFlowLiteBindings(
      DynamicLibrary.open(
        '$_libName.dll',
      ),
    );
  } else {
    throw UnsupportedError(
      'Unknown platform: ${Platform.operatingSystem}',
    );
  }
}
