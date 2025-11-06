import 'package:flutter_callkeep_platform_interface/src/models/callkeep_base_event.dart';

/// CallKeep mute toggling information from CallKit
class MuteToggleEvent extends CallKeepBaseEvent {
  final bool isMuted;

  MuteToggleEvent({
    required String callUuid,
    required this.isMuted,
  }) : super(uuid: callUuid);

  factory MuteToggleEvent.fromMap(Map<String, dynamic> map) {
    return MuteToggleEvent(
      callUuid: map['id'] ?? '',
      isMuted: map['isMuted'] ?? false,
    );
  }
}
