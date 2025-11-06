import 'dart:async';

import 'package:flutter_callkeep_platform_interface/method_channel_callkeep.dart';
import 'package:flutter_callkeep_platform_interface/src/models/models.dart';

export 'package:flutter_callkeep_platform_interface/src/models/models.dart';

/// The interface that implementations of CallKeep must implement.
base class CallKeepPlatform {
  /// Constructs a CallKeepPlatform.
  CallKeepPlatform();

  /// The default instance of [CallKeepPlatform] to use.
  ///
  /// Defaults to [MethodChannelCallKeep].
  static CallKeepPlatform instance = MethodChannelCallKeep();

  /// Configures the plugin.
  ///
  /// - This function should be called at the beginning of
  /// your application, but can be called multiple times to update configuration
  void configure(CallKeepConfig config) {
    throw UnimplementedError('init has not been implemented.');
  }

  /// Set the handler to handle CallKeep events.
  set handler(CallEventHandler handler) {
    throw UnimplementedError('handler setter has not been implemented.');
  }

  CallKeepConfig? config;

  /// Show Incoming call UI.
  Future<void> displayIncomingCall(CallEvent data) async {
    throw UnimplementedError('displayIncomingCall has not been implemented.');
  }

  /// Show Miss Call Notification.
  Future<void> showMissCallNotification(CallEvent data) async {
    throw UnimplementedError(
        'showMissCallNotification has not been implemented.');
  }

  /// Start an Outgoing call.
  Future<void> startCall(CallEvent data) {
    throw UnimplementedError('startCall has not been implemented.');
  }

  /// End an Incoming/Outgoing call with the specified uuid.
  Future<void> endCall(String uuid) async {
    throw UnimplementedError('endCall has not been implemented.');
  }

  /// End all calls.
  Future<void> endAllCalls() async {
    throw UnimplementedError('endAllCalls has not been implemented.');
  }

  /// Get active calls.
  ///
  /// Helpful when starting the app from terminated state to retrieve information about latest calls
  Future<List<CallEvent>> activeCalls() {
    throw UnimplementedError('activeCalls has not been implemented.');
  }

  /// Get device push token VoIP.
  Future<String> getDevicePushTokenVoIP() async {
    throw UnimplementedError(
        'getDevicePushTokenVoIP has not been implemented.');
  }

  /// Accept an incoming call with the specified uuid.
  ///
  /// This is only used when the incoming call is not displayed natively.
  Future<void> acceptCall(String uuid) async {
    throw UnimplementedError('updateCall has not been implemented.');
  }

  /// Disposes of the resources used by the plugin.
  void dispose() {
    throw UnimplementedError('close has not been implemented.');
  }

  /// Check if the incoming call is displayed natively.
  ///
  /// Otherwise, we show the flutter builder
  bool get isCallDisplayedNatively => throw UnimplementedError(
      'isCallDisplayedNatively has not been implemented.');
}
