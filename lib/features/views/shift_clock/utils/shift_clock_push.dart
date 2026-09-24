import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'package:packer/constants/app_constants.dart';
import 'package:packer/features/views/shift_clock/providers/shift_clock_provider.dart';

/// Hands a shift clock push (see isShiftClockPush) to the running app.
///
/// Only for the main isolate: the background handler has no providers, and
/// the system tray already shows those pushes. The clock refreshes on resume.
void dispatchShiftClockPush(Map<String, dynamic> data) {
  final context = AppConstants.navigatorKey.currentContext;
  if (context == null) return;
  try {
    Provider.of<ShiftClockProvider>(context, listen: false).handlePush(data);
  } catch (e) {
    debugPrint('Shift clock push not handled: $e');
  }
}
