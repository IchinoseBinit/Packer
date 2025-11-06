import 'package:flutter_callkeep_platform_interface/src/models/callkeep_base_event.dart';

/// The device push token data for VoIP
///
/// [token] is always an empty String on non iOS platforms
class VoipTokenEvent extends CallKeepBaseEvent {
  final String token;

  VoipTokenEvent({
    required this.token,
    required String callUuid,
  }) : super(uuid: callUuid);

  factory VoipTokenEvent.fromMap(Map<String, dynamic> map) {
    return VoipTokenEvent(
      token: map['deviceTokenVoIP'] ?? '',
      callUuid: map['id'] ?? '',
    );
  }
}
