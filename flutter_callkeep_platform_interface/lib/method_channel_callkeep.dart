import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkeep_platform_interface/flutter_callkeep_platform_interface.dart';
import 'package:flutter_callkeep_platform_interface/src/models/callkeep_event_mapper.dart';

/// Method channel implementation for [CallKeepPlatform]
final class MethodChannelCallKeep extends CallKeepPlatform {
  @visibleForTesting
  MethodChannel methodChannel = const MethodChannel('flutter_callkeep');
  @visibleForTesting
  EventChannel eventChannel = const EventChannel('flutter_callkeep_events');

  StreamSubscription? _eventChannelSubscription;

  @override
  void configure(CallKeepConfig config) {
    this.config = config;
  }

  @override
  set handler(CallEventHandler handler) {
    // Cancel the previous subscription if it exists
    _eventChannelSubscription?.cancel();

    _eventChannelSubscription =
        eventChannel.receiveBroadcastStream().listen((data) {
      final event = CallKeepEventMapper.eventFromData(data);
      handler.handle(event.event, event.type);
    });
  }

  @override
  Future<void> displayIncomingCall(CallEvent data) async {
    await methodChannel.invokeMethod("displayIncomingCall", _callData(data));
  }

  @override
  Future<void> showMissCallNotification(CallEvent data) async {
    await methodChannel.invokeMethod(
      "showMissCallNotification",
      _callData(data),
    );
  }

  @override
  Future<void> startCall(CallEvent data) async {
    await methodChannel.invokeMethod("startCall", _callData(data));
  }

  @override
  Future<void> endCall(String uuid) async {
    await methodChannel.invokeMethod("endCall", {'id': uuid});
  }

  @override
  Future<void> endAllCalls() async {
    await methodChannel.invokeMethod("endAllCalls");
  }

  @override
  Future<List<CallEvent>> activeCalls() async {
    final activeCallsRaw =
        await methodChannel.invokeMethod<List>("activeCalls");
    if (activeCallsRaw == null) return [];
    return activeCallsRaw
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .map((e) => CallEvent.fromMap(e))
        .toList();
  }

  @override
  Future<String> getDevicePushTokenVoIP() async {
    return (await methodChannel
            .invokeMethod<String>("getDevicePushTokenVoIP")) ??
        '';
  }

  Map<String, dynamic> _callData(CallEvent data) {
    return {
      ...data.toMap(),
      ...config?.toMap() ?? {},
    };
  }

  @override
  Future<void> acceptCall(String uuid) async {
    return methodChannel.invokeMethod("acceptCall", {'id': uuid});
  }

  @override
  bool get isCallDisplayedNatively => true;

  @override
  void dispose() {
    _eventChannelSubscription?.cancel();
  }
}
