import 'package:flutter/foundation.dart';

extension DebugPrintCallbackExtension on Object? {
  void log({String? type}) =>
      debugPrint('\x1B[33m [${type ?? 'Log'}] ${this?.toString()}\x1B[0m');
  void logError({String? type}) =>
      debugPrint('\x1B[31m [${type ?? 'Log'}] ${this?.toString()}\x1B[0m');

  void logDio() => kDebugMode
      ? print('\x1B[32m [ Dio ] ${this?.toString()}\x1B[0m')
      : debugPrint('\x1B[32m [ Dio ] ${this?.toString()}\x1B[0m');
}
