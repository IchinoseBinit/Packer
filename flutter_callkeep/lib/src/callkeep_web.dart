import 'dart:async';

import 'package:flutter_callkeep_platform_interface/flutter_callkeep_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

typedef CallKeepEventRecord = ({CallEvent event, CallKeepEventType type});

/// The web implementation of [CallKeepPlatform].
final class CallKeepWebPlugin extends CallKeepPlatform {
  /// The event stream controller.
  final _eventsStreamController =
      StreamController<CallKeepEventRecord>.broadcast();
  StreamSubscription? _eventsStreamSubscription;

  final List<CallEvent> _calls = [];

  /// Constructs a CallKeepWebPlugin.
  CallKeepWebPlugin();

  /// Factory method that initializes the CallKeep plugin platform with an instance
  /// of the plugin for the web.
  static void registerWith(Registrar registrar) {
    CallKeepPlatform.instance = CallKeepWebPlugin();
  }

  @override
  void configure(CallKeepConfig config) {
    this.config = config;
  }

  @override
  set handler(CallEventHandler handler) {
    // Cancel the previous subscription if it exists
    _eventsStreamSubscription?.cancel();

    _eventsStreamSubscription = _eventsStreamController.stream.listen((event) {
      handler.handle(event.event, event.type);
    });
  }

  @override
  Future<void> displayIncomingCall(CallEvent data) async {
    _calls.add(data);
    final event = (event: data, type: CallKeepEventType.callIncoming);
    _eventsStreamController.add(event);
  }

  @override
  Future<void> showMissCallNotification(CallEvent data) async {
    return;
  }

  @override
  Future<void> acceptCall(String uuid) async {
    final callIndex = _calls.indexWhere((element) => element.uuid == uuid);
    // If the call is not found, return.
    if (callIndex < 0) return;
    final call = _calls[callIndex];
    final updatedCall = call.copyWith(isAccepted: true);
    _calls[callIndex] = updatedCall;
    final event = (event: updatedCall, type: CallKeepEventType.callAccepted);
    _eventsStreamController.add(event);
  }

  @override
  Future<void> startCall(CallEvent data) async {
    _calls.add(data);
    final event = (event: data, type: CallKeepEventType.callStarted);
    _eventsStreamController.add(event);
  }

  @override
  Future<void> endCall(String uuid) async {
    final call = _calls.firstWhere(
      (element) => element.uuid == uuid,
      orElse: () => CallEvent(uuid: ''),
    );
    // If the call is not found, return.
    if (call.uuid.isEmpty) return;
    _calls.remove(call);
    final event = (event: call, type: CallKeepEventType.callEnded);
    _eventsStreamController.add(event);
  }

  @override
  Future<void> endAllCalls() async {
    for (final call in _calls) {
      final event = (event: call, type: CallKeepEventType.callEnded);
      _eventsStreamController.add(event);
    }
    _calls.clear();
  }

  @override
  Future<List<CallEvent>> activeCalls() {
    return Future.value(_calls);
  }

  @override
  Future<String> getDevicePushTokenVoIP() async {
    return '';
  }

  @override
  bool get isCallDisplayedNatively => false;

  @override
  void dispose() {
    _eventsStreamController.close();
  }
}
