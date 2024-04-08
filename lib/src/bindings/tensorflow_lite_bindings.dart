import 'dart:ffi';
import 'dart:io';

import 'tensorflow_lite_bindings_generated.dart';

/// The name of the dynamic library.

const String _libName = 'tensorflowlite_c';

/// The dynamic library in which the symbols for [UserBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('lib$_libName.dylib');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

final DynamicLibrary _dylibGpu = () {
  if (Platform.isAndroid) {
    return DynamicLibrary.open('libtensorflowlite_gpu_jni.so');
  }

  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// TensorFlowLite Bindings
final tfliteBinding = TensorFlowLiteBindings(_dylib);

/// TensorFlowLite Gpu Bindings
final tfliteBindingGpu = TensorFlowLiteBindings(_dylibGpu);
