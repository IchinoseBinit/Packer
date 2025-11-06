import 'package:flutter_callkeep_platform_interface/src/models/callkeep_base_event.dart';

/// CallKeep hold toggling information from CallKit
class HoldToggleEvent extends CallKeepBaseEvent {
  final bool isOnHold;

  HoldToggleEvent({
    required this.isOnHold,
    required String callUuid,
  }) : super(uuid: callUuid);

  factory HoldToggleEvent.fromMap(Map<String, dynamic> map) {
    return HoldToggleEvent(
      isOnHold: map['isOnHold'] ?? false,
      callUuid: map['id'] ?? '',
    );
  }
}
