import 'package:flutter_callkeep_platform_interface/src/models/callkeep_base_event.dart';

/// The data for audio session toggle event from CallKeep
///
/// It may hold data for [answerCall] or [outgoingCall]
class AudioSessionToggleEvent extends CallKeepBaseEvent {
  final bool isActivated;

  AudioSessionToggleEvent({
    required String callUuid,
    required this.isActivated,
  }) : super(uuid: callUuid);

  factory AudioSessionToggleEvent.fromMap(Map<String, dynamic> map) {
    return AudioSessionToggleEvent(
      callUuid: map['id'] ?? '',
      isActivated: map['isActivate'] ?? false,
    );
  }
}
