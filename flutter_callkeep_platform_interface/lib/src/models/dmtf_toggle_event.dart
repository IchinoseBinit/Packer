import 'package:flutter_callkeep_platform_interface/src/models/callkeep_base_event.dart';

/// CallKeep DMTF toggling information from CallKit
class DmtfToggleEvent extends CallKeepBaseEvent {
  final String digits;
  final DmtfActionType actionType;

  DmtfToggleEvent({
    required String callUuid,
    required this.digits,
    required this.actionType,
  }) : super(uuid: callUuid);

  factory DmtfToggleEvent.fromMap(Map<String, dynamic> map) {
    return DmtfToggleEvent(
      callUuid: map['id'] ?? '',
      digits: map['digits'] ?? '',
      actionType: DmtfActionType.values[(map['type'] ?? 0) + 1],
    );
  }
}

/// The action type of [DmtfToggleEvent]
enum DmtfActionType { singleTone, softPause, hardPause }
