/// The shift clock as GET /attendance/session/ returns it, and as the packer
/// summary carries it in its `shift` block.
///
/// Parsing is defensive: any missing key, null or wrong type falls back to a
/// value that shows nothing, so a partial response can never block a packer.
library;

class ShiftStatus {
  static const active = 'active';
  static const awaitingExtension = 'awaiting_extension';
  static const extended = 'extended';
  static const closing = 'closing';
}

class ShiftPay {
  static const normal = 'normal';
  static const overtime = 'overtime';

  static bool isValid(String? value) => value == normal || value == overtime;
}

class ShiftEndReason {
  static const manual = 'manual';
  static const auto = 'auto';
  static const forcedBySupport = 'forced_by_support';
}

class ShiftRequestStatus {
  static const pending = 'pending';
  static const approved = 'approved';
  static const rejected = 'rejected';
  static const expired = 'expired';
  static const cancelled = 'cancelled';
}

/// A server time. Keeps the offset the server sent (+05:45) so times read the
/// same on the phone whatever its own time zone is.
class ShiftTime {
  /// The moment, in UTC.
  final DateTime instant;

  /// The offset carried by the ISO string.
  final Duration offset;

  const ShiftTime(this.instant, this.offset);

  static final _offsetPattern =
      RegExp(r'(Z|[+-]\d{2}:?\d{2})$', caseSensitive: false);

  static ShiftTime? tryParse(dynamic value) {
    if (value is! String) return null;
    final text = value.trim();
    if (text.isEmpty) return null;
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return null;

    final match = _offsetPattern.firstMatch(text);
    Duration offset;
    if (match == null) {
      // No offset: DateTime.parse read it as the phone's local time.
      offset = parsed.timeZoneOffset;
    } else if (match.group(1)!.toUpperCase() == 'Z') {
      offset = Duration.zero;
    } else {
      final raw = match.group(1)!.replaceAll(':', '');
      final sign = raw.startsWith('-') ? -1 : 1;
      final hours = int.parse(raw.substring(1, 3));
      final minutes = int.parse(raw.substring(3, 5));
      offset = Duration(minutes: sign * (hours * 60 + minutes));
    }
    return ShiftTime(parsed.toUtc(), offset);
  }

  /// A UTC DateTime whose fields read as the server's wall clock.
  DateTime get wallClock => instant.add(offset);

  ShiftTime add(Duration duration) => ShiftTime(instant.add(duration), offset);

  @override
  bool operator ==(Object other) =>
      other is ShiftTime && other.instant == instant && other.offset == offset;

  @override
  int get hashCode => Object.hash(instant, offset);

  @override
  String toString() => 'ShiftTime($instant, $offset)';
}

class ShiftRoster {
  final String shift;
  final bool otAllowed;

  /// [ShiftPay.normal], [ShiftPay.overtime] or '' when unknown.
  final String otPayType;
  final double? otMaxHours;

  const ShiftRoster({
    required this.shift,
    required this.otAllowed,
    required this.otPayType,
    required this.otMaxHours,
  });

  static ShiftRoster? fromJson(dynamic json) {
    final map = asJsonMap(json);
    if (map == null) return null;
    final pay = map['ot_pay_type'];
    return ShiftRoster(
      shift: jsonString(map['shift']),
      otAllowed: jsonBool(map['ot_allowed']),
      otPayType: ShiftPay.isValid(pay) ? pay as String : '',
      otMaxHours: jsonDouble(map['ot_max_hours']),
    );
  }
}

class ShiftRequest {
  final int? id;
  final String status;
  final ShiftTime? requestedAt;
  final double? requestedHours;
  final ShiftTime? requestedUntil;
  final String requestedPay;
  final String reason;
  final bool matchesRoster;
  final ShiftTime? reviewedAt;
  final String reviewNote;
  final ShiftTime? approvedUntil;
  final String? approvedPay;

  const ShiftRequest({
    this.id,
    this.status = '',
    this.requestedAt,
    this.requestedHours,
    this.requestedUntil,
    this.requestedPay = '',
    this.reason = '',
    this.matchesRoster = false,
    this.reviewedAt,
    this.reviewNote = '',
    this.approvedUntil,
    this.approvedPay,
  });

  static ShiftRequest? fromJson(dynamic json) {
    final map = asJsonMap(json);
    if (map == null) return null;
    final approvedPay = map['approved_pay'];
    return ShiftRequest(
      id: jsonInt(map['id']),
      status: jsonString(map['status']),
      requestedAt: ShiftTime.tryParse(map['requested_at']),
      requestedHours: jsonDouble(map['requested_hours']),
      requestedUntil: ShiftTime.tryParse(map['requested_until']),
      requestedPay: jsonString(map['requested_pay']),
      reason: jsonString(map['reason']),
      matchesRoster: jsonBool(map['matches_roster']),
      reviewedAt: ShiftTime.tryParse(map['reviewed_at']),
      reviewNote: jsonString(map['review_note']),
      approvedUntil: ShiftTime.tryParse(map['approved_until']),
      approvedPay: ShiftPay.isValid(approvedPay) ? approvedPay as String : null,
    );
  }
}

/// The session that closed last, sent only when none is open.
class LastShiftSession {
  final ShiftTime? endedAt;

  /// ended_at exactly as sent; used to remember which check-out was shown.
  final String endedAtRaw;
  final String endReason;

  const LastShiftSession({
    required this.endedAt,
    required this.endedAtRaw,
    required this.endReason,
  });

  static LastShiftSession? fromJson(dynamic json) {
    final map = asJsonMap(json);
    if (map == null) return null;
    return LastShiftSession(
      endedAt: ShiftTime.tryParse(map['ended_at']),
      endedAtRaw: jsonString(map['ended_at']),
      endReason: jsonString(map['end_reason']),
    );
  }
}

class ShiftSessionState {
  static const defaultPollSeconds = 60;
  static const minPollSeconds = 15;
  static const maxPollSeconds = 900;

  final bool hasSession;
  final bool enforced;
  final int pollSeconds;
  final ShiftTime? serverTime;
  final bool canTakeWork;
  final bool showDialog;
  final bool locked;
  final LastShiftSession? lastSession;

  final int? sessionId;
  final String status;
  final String role;
  final ShiftTime? startedAt;
  final double? regularHours;
  final ShiftTime? regularLimitAt;
  final ShiftTime? hardLimitAt;
  final int? secondsToRegularLimit;
  final int? secondsToHardLimit;
  final bool shiftComplete;
  final bool canRequest;
  final String note;
  final ShiftTime? extensionBase;
  final ShiftRoster? roster;
  final ShiftRequest? pendingRequest;
  final ShiftRequest? lastDecision;

  /// Phone clock when the response arrived; anchors the seconds_to_* values
  /// and, with [serverTime], the correction for a wrong device clock.
  final DateTime receivedAt;

  /// True while the newest word about this shift came from the summary's
  /// `shift` block rather than from GET /attendance/session/. Such a state
  /// runs the countdown but is confirmed with the clock itself before the app
  /// acts on it (opens the shift complete screen).
  final bool fromSummary;

  const ShiftSessionState({
    required this.hasSession,
    required this.enforced,
    required this.pollSeconds,
    required this.serverTime,
    required this.canTakeWork,
    required this.showDialog,
    required this.locked,
    required this.lastSession,
    required this.sessionId,
    required this.status,
    required this.role,
    required this.startedAt,
    required this.regularHours,
    required this.regularLimitAt,
    required this.hardLimitAt,
    required this.secondsToRegularLimit,
    required this.secondsToHardLimit,
    required this.shiftComplete,
    required this.canRequest,
    required this.note,
    required this.extensionBase,
    required this.roster,
    required this.pendingRequest,
    required this.lastDecision,
    required this.receivedAt,
    this.fromSummary = false,
  });

  factory ShiftSessionState.fromJson(Map<dynamic, dynamic> json,
      {DateTime? receivedAt, bool fromSummary = false}) {
    final poll = jsonInt(json['poll_seconds']);
    final hasSession = jsonBool(json['has_session']);
    return ShiftSessionState(
      hasSession: hasSession,
      enforced: jsonBool(json['enforced']),
      pollSeconds: poll == null || poll <= 0
          ? defaultPollSeconds
          : poll.clamp(minPollSeconds, maxPollSeconds),
      serverTime: ShiftTime.tryParse(json['server_time']),
      canTakeWork: jsonBool(json['can_take_work'], fallback: true),
      showDialog: hasSession && jsonBool(json['show_dialog']),
      locked: jsonBool(json['locked']),
      lastSession: LastShiftSession.fromJson(json['last_session']),
      sessionId: jsonInt(json['session_id']),
      status: jsonString(json['status']),
      role: jsonString(json['role']),
      startedAt: ShiftTime.tryParse(json['started_at']),
      regularHours: jsonDouble(json['regular_hours']),
      regularLimitAt: ShiftTime.tryParse(json['regular_limit_at']),
      hardLimitAt: ShiftTime.tryParse(json['hard_limit_at']),
      secondsToRegularLimit: jsonInt(json['seconds_to_regular_limit']),
      secondsToHardLimit: jsonInt(json['seconds_to_hard_limit']),
      shiftComplete: jsonBool(json['shift_complete']),
      // Missing means "don't offer a form": the server always sends it with a session.
      canRequest: jsonBool(json['can_request']),
      note: jsonString(json['note']).trim(),
      extensionBase: ShiftTime.tryParse(json['extension_base']),
      roster: ShiftRoster.fromJson(json['roster']),
      pendingRequest: ShiftRequest.fromJson(json['pending_request']),
      lastDecision: ShiftRequest.fromJson(json['last_decision']),
      receivedAt: receivedAt ?? DateTime.now(),
      fromSummary: fromSummary,
    );
  }

  /// The `shift` block of a summary response, or null when the endpoint sent
  /// none (an older backend, or the server could not build it).
  static ShiftSessionState? fromSummaryJson(dynamic json,
      {DateTime? receivedAt}) {
    final map = asJsonMap(json);
    if (map == null) return null;
    return ShiftSessionState.fromJson(map,
        receivedAt: receivedAt, fromSummary: true);
  }

  /// server_time minus the phone clock when this state arrived: what has to be
  /// added to the phone's own time to read it as the server does. Zero when
  /// the server sent no server_time, which leaves the phone clock as it is.
  Duration get clockSkew {
    final server = serverTime;
    if (server == null) return Duration.zero;
    return server.instant.difference(receivedAt.toUtc());
  }

  /// The phone clock [now] read as the server's clock.
  DateTime serverInstantAt(DateTime now) => now.toUtc().add(clockSkew);

  /// How long is left until [time] on the server's clock; null when [time] is
  /// unknown. Negative once it has passed.
  Duration? remainingTo(ShiftTime? time, DateTime now) =>
      time?.instant.difference(serverInstantAt(now));

  /// seconds_to_hard_limit counted down to [now] on the phone; worked out from
  /// hard_limit_at and the clock correction when the server sent no countdown
  /// (the summary's `shift` block never does).
  int? secondsToHardLimitAt(DateTime now) {
    final seconds = secondsToHardLimit;
    if (seconds == null) return remainingTo(hardLimitAt, now)?.inSeconds;
    return seconds - now.difference(receivedAt).inSeconds;
  }

  /// This state with the summary's `shift` block [seed] applied over it: the
  /// times and flags the seed carries win, and everything it does not carry
  /// (the roster, the requests, the session that closed last) is kept.
  ///
  /// The result stays confirmed - [fromSummary] false - only while the seed
  /// says nothing new about the session, its status or what the packer may
  /// do; anything new is confirmed with GET /attendance/session/ before the
  /// app acts on it.
  ShiftSessionState withSeed(ShiftSessionState seed) {
    final sameSession = hasSession == seed.hasSession &&
        (!hasSession || sessionId == seed.sessionId);
    if (!sameSession) return seed;
    final confirmed = !fromSummary &&
        status == seed.status &&
        showDialog == seed.showDialog &&
        shiftComplete == seed.shiftComplete &&
        canTakeWork == seed.canTakeWork &&
        canRequest == seed.canRequest;
    return ShiftSessionState(
      hasSession: seed.hasSession,
      enforced: seed.enforced,
      pollSeconds: seed.pollSeconds,
      serverTime: seed.serverTime ?? serverTime,
      canTakeWork: seed.canTakeWork,
      showDialog: seed.showDialog,
      locked: locked,
      lastSession: lastSession,
      sessionId: seed.sessionId ?? sessionId,
      status: seed.status,
      role: seed.role.isEmpty ? role : seed.role,
      startedAt: seed.startedAt ?? startedAt,
      regularHours: regularHours,
      regularLimitAt: seed.regularLimitAt ?? regularLimitAt,
      hardLimitAt: seed.hardLimitAt ?? hardLimitAt,
      // Anchored to the old receivedAt: the limits above and the clock
      // correction say the same thing against the seed's own arrival.
      secondsToRegularLimit: null,
      secondsToHardLimit: null,
      shiftComplete: seed.shiftComplete,
      canRequest: seed.canRequest,
      note: seed.note,
      extensionBase: extensionBase,
      roster: roster,
      // can_request true means the server holds no pending request any more.
      pendingRequest: seed.canRequest ? null : pendingRequest,
      lastDecision: lastDecision,
      receivedAt: seed.receivedAt,
      fromSummary: !confirmed,
    );
  }
}

Map<String, dynamic>? asJsonMap(dynamic value) {
  if (value is! Map) return null;
  return value.map((key, v) => MapEntry(key.toString(), v));
}

bool jsonBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final text = value.trim().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
  }
  return fallback;
}

int? jsonInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) {
    return int.tryParse(value.trim()) ?? double.tryParse(value.trim())?.round();
  }
  return null;
}

double? jsonDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

String jsonString(dynamic value) => value == null ? '' : value.toString();
