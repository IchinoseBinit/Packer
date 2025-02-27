import 'package:flutter_callkeep_platform_interface/src/models/callkeep_base_event.dart';

/// The data for toggling call group event from CallKeep
class CallGroupToggleEvent extends CallKeepBaseEvent {
  final String callUuidToGroupWith;

  CallGroupToggleEvent({
    required String callUuid,
    required this.callUuidToGroupWith,
  }) : super(uuid: callUuid);

  factory CallGroupToggleEvent.fromMap(Map<String, dynamic> map) {
    return CallGroupToggleEvent(
      callUuid: map['id'] ?? '',
      callUuidToGroupWith: map['callUUIDToGroupWith'] ?? '',
    );
  }
}
