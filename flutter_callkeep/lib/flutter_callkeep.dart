import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_callkeep_platform_interface/flutter_callkeep_platform_interface.dart';

export 'package:flutter_callkeep_platform_interface/flutter_callkeep_platform_interface.dart';

/// Instance to use library functions.
/// * displayIncomingCall(CallKeepIncomingConfig)
/// * startCall(CallKeepOutgoingConfig)
/// * showMissCallNotification(CallKeepIncomingConfig)
/// * endCall(String Uuid)
/// * endAllCalls()
///
class CallKeep {
  CallKeep._internal();
  static final CallKeep _instance = CallKeep._internal();

  /// The [CallKeep] singleton instance.
  ///
  /// [CallKeep] is designed to work as a singleton.
  // When a second instance is created, the first instance will not be able to listen to the
  // EventChannel because it is overridden. Forcing the class to be a singleton class can prevent
  // misuse of creating a second instance from a programmer.
  static CallKeep get instance => _instance;

  static CallKeepPlatform get _platform {
    return CallKeepPlatform.instance;
  }

  /// Configures the plugin.
  ///
  /// - This function should be called at the beginning of
  /// your application, but can be called multiple times to update configuration
  void configure(CallKeepConfig config) {
    return _platform.configure(config);
  }

  /// Set the handler to handle CallKeep events.
  set handler(CallEventHandler handler) {
    _platform.handler = handler;
  }

  /// Show Incoming call UI.
  ///
  /// [context] is optional and only used for displaying
  /// Flutter incoming call builder on non-native platforms.
  Future<void> displayIncomingCall(
    CallEvent data, {
    BuildContext? context,
  }) async {
    return _platform.displayIncomingCall(data);
  }

  /// Show Miss Call Notification.
  Future<void> showMissCallNotification(CallEvent data) async {
    return _platform.showMissCallNotification(data);
  }

  /// Start an Outgoing call.
  Future<void> startCall(CallEvent data) {
    return _platform.startCall(data);
  }

  /// End an Incoming/Outgoing call with the specified uuid.
  Future<void> endCall(String uuid) async {
    return _platform.endCall(uuid);
  }

  /// Accept an incoming call with the specified uuid.
  Future<void> acceptCall(String uuid) async {
    return _platform.acceptCall(uuid);
  }

  /// End all calls.
  Future<void> endAllCalls() async {
    return _platform.endAllCalls();
  }

  /// Get active calls.
  ///
  /// Helpful when starting the app from terminated state to retrieve information about latest calls
  Future<List<CallEvent>> activeCalls() {
    return _platform.activeCalls();
  }

  /// Get device push token VoIP.
  Future<String> getDevicePushTokenVoIP() async {
    return _platform.getDevicePushTokenVoIP();
  }

  /// Check if the incoming call is displayed natively by the plugin
  /// or has been handled by the app.
  bool get isIncomingCallDisplayed => _platform.isCallDisplayedNatively;

  /// Disposes of the resources used by the plugin.
  void dispose() {
    return _platform.dispose();
  }
}
