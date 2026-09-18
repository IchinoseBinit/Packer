import 'package:packer/features/views/shift_clock/models/shift_session.dart';

/// The `error` codes of the roster sign-in gate (attendance.login_gate).
class ShiftRefusalCode {
  static const shiftNotStarted = 'shift_not_started';
  static const shiftOver = 'shift_over';
  static const notRostered = 'not_rostered';

  static const all = {shiftNotStarted, shiftOver, notRostered};
}

/// The roster sign-in gate turning a packer or driver away.
///
/// Always an HTTP 403, never a 401 (a 401 sends the app off to refresh and
/// retry), with `{"success": false, "error": <code>, "message": <a sentence in
/// 12-hour time>, "shift": {"starts_at", "ends_at", "name"} | null}`. It comes
/// back from signing in, from a token refresh, from going online, and from any
/// request once the shift clock has checked someone out. The server never
/// sends it to anyone with a shift session open, so it never reaches work in
/// hand.
class ShiftRefusal {
  /// One of [ShiftRefusalCode.all].
  final String code;

  /// Written to be shown as it is: "Your shift starts at 6:00 AM. You can sign
  /// in from 5:00 AM." Empty only if the server left it out.
  final String message;

  /// The shift the message is about - the one not started yet, or the one
  /// that is over. Null for not_rostered, and for a sign-in the clock ended
  /// (the server names no shift then).
  final ShiftTime? startsAt;
  final ShiftTime? endsAt;
  final String shiftName;

  const ShiftRefusal({
    required this.code,
    required this.message,
    this.startsAt,
    this.endsAt,
    this.shiftName = '',
  });

  /// The refusal in a response, or null for anything else: every other 403
  /// (a role the endpoint does not serve, a blacklisted account), and the 409
  /// shift_complete that going online answers before the gate is asked.
  static ShiftRefusal? fromResponse(int? statusCode, dynamic data) {
    if (statusCode != 403) return null;
    final map = asJsonMap(data);
    final code = map?['error'];
    if (map == null || code is! String || !ShiftRefusalCode.all.contains(code)) {
      return null;
    }
    final shift = asJsonMap(map['shift']);
    return ShiftRefusal(
      code: code,
      message: jsonString(map['message']).trim(),
      startsAt: ShiftTime.tryParse(shift?['starts_at']),
      endsAt: ShiftTime.tryParse(shift?['ends_at']),
      shiftName: jsonString(shift?['name']).trim(),
    );
  }
}
