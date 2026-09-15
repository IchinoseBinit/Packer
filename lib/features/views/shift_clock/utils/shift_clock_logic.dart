import 'package:packer/controllers/api/app_exception.dart';
import 'package:packer/features/views/audit_product/models/audit_status_enum.dart';
import 'package:packer/features/views/shift_clock/models/shift_session.dart';

/// Pure shift clock rules and the words packers see. No Flutter, no network,
/// so all of it is covered by test/shift_clock_test.dart.

class ShiftPushType {
  static const limitReached = 'shift_limit_reached';
  static const extensionDecided = 'shift_extension_decided';
  static const autoCheckout = 'shift_auto_checkout';

  static const all = {limitReached, extensionDecided, autoCheckout};
}

/// Hour choices on the extension request form.
const shiftExtensionHourChoices = <double>[0.5, 1, 2, 3, 4];

/// A check-out older than this is not announced any more.
const checkoutNoticeWindow = Duration(hours: 12);

/// True for the data map of a shift clock push (not an order).
bool isShiftClockPush(Map<dynamic, dynamic>? data) =>
    data != null && ShiftPushType.all.contains(data['type']);

/// True for the 409 the packer online-status API sends once the shift is complete.
bool isShiftCompleteError(Object? error) {
  if (error is! AppException || error.statusCode != 409) return false;
  final json = error.json;
  return json is Map && json['error'] == 'shift_complete';
}

/// Shift clock UI applies to a packer's own open, enforced session.
bool isShiftClockVisible(ShiftSessionState? state) {
  if (state == null || !state.enforced || !state.hasSession) return false;
  return state.role.isEmpty || state.role == 'packer';
}

// ---------------------------------------------------------------------------
// 12-hour times
// ---------------------------------------------------------------------------

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "6 AM", "6:30 PM", "12 PM" in the server's own time.
String formatShiftClock(ShiftTime time) {
  final wall = time.wallClock;
  final hour = wall.hour % 12 == 0 ? 12 : wall.hour % 12;
  final suffix = wall.hour < 12 ? 'AM' : 'PM';
  if (wall.minute == 0) return '$hour $suffix';
  return '$hour:${wall.minute.toString().padLeft(2, '0')} $suffix';
}

/// [formatShiftClock], plus "tomorrow" / "yesterday" / a date when [time] is
/// not on the same day as [reference] (normally server_time).
String formatShiftClockOn(ShiftTime time, ShiftTime? reference) {
  final clock = formatShiftClock(time);
  if (reference == null) return clock;
  final day = _dateOnly(time.wallClock);
  final today = _dateOnly(reference.wallClock);
  final days = day.difference(today).inDays;
  if (days == 0) return clock;
  if (days == 1) return '$clock tomorrow';
  if (days == -1) return '$clock yesterday';
  return '$clock, ${day.day} ${_months[day.month - 1]}';
}

DateTime _dateOnly(DateTime wall) => DateTime.utc(wall.year, wall.month, wall.day);

/// "30 min", "1 h", "1 h 30 min".
String formatShiftHours(double hours) {
  final minutes = (hours * 60).round();
  if (minutes < 60) return '$minutes min';
  final whole = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '$whole h' : '$whole h $rest min';
}

/// "overtime pay" / "normal pay".
String payLabel(String pay) =>
    pay == ShiftPay.normal ? 'normal pay' : 'overtime pay';

// ---------------------------------------------------------------------------
// Home status line
// ---------------------------------------------------------------------------

/// Regular hours (or the approved extension) are over.
bool isShiftOver(ShiftSessionState state) =>
    state.shiftComplete ||
    state.status == ShiftStatus.awaitingExtension ||
    state.status == ShiftStatus.closing;

/// "Shift ends 2 PM", "Extension until 8 PM" or "Shift complete"; null when hidden.
String? shiftStatusLine(ShiftSessionState state) {
  if (!isShiftClockVisible(state)) return null;
  if (isShiftOver(state)) return 'Shift complete';
  if (state.status == ShiftStatus.extended) {
    final until = state.hardLimitAt;
    return until == null
        ? 'Extension approved'
        : 'Extension until ${formatShiftClockOn(until, state.serverTime)}';
  }
  final end = state.regularLimitAt;
  return end == null
      ? 'On shift'
      : 'Shift ends ${formatShiftClockOn(end, state.serverTime)}';
}

/// The smaller line under the status.
String shiftStatusDetail(ShiftSessionState state) {
  if (isShiftOver(state)) {
    return state.pendingRequest != null
        ? 'Waiting for support to approve more time'
        : 'Tap to ask for more time or check out';
  }
  if (state.status == ShiftStatus.extended) {
    final decision = state.lastDecision;
    final pay = decision?.status == ShiftRequestStatus.approved
        ? decision?.approvedPay
        : null;
    return pay == null ? 'Approved by support' : 'Approved at ${payLabel(pay)}';
  }
  final started = state.startedAt;
  return started == null
      ? 'On shift'
      : 'Started ${formatShiftClockOn(started, state.serverTime)}';
}

// ---------------------------------------------------------------------------
// Shift complete screen
// ---------------------------------------------------------------------------

String rosterLine(ShiftRoster? roster) {
  if (roster == null) return "You're not on today's roster";
  if (!roster.otAllowed) return 'No overtime planned on your roster';
  final pay = roster.otPayType.isEmpty ? '' : ' at ${payLabel(roster.otPayType)}';
  final max = roster.otMaxHours;
  final upTo = max == null || max <= 0 ? '' : ', up to ${formatShiftHours(max)}';
  return 'Your roster allows overtime$pay$upTo';
}

/// When the packer will be checked out if nothing is approved.
String graceLine(ShiftSessionState state, DateTime now) {
  final hardLimit = state.hardLimitAt;
  final secondsLeft = state.secondsToHardLimitAt(now);
  if (hardLimit != null && (secondsLeft == null || secondsLeft > 0)) {
    return "You'll be checked out at "
        '${formatShiftClockOn(hardLimit, state.serverTime)} '
        'unless support approves more time';
  }
  if (state.pendingRequest != null) {
    return "Support is looking at your request. You won't be checked out until they decide";
  }
  return "Your time is up. You'll be checked out soon unless support approves more time";
}

String pendingRequestLine(ShiftRequest request, ShiftTime? reference) {
  final until = request.requestedUntil;
  final pay = ShiftPay.isValid(request.requestedPay)
      ? ' at ${payLabel(request.requestedPay)}'
      : '';
  if (until == null) return 'Waiting for support to approve your request$pay';
  return 'Waiting for support to approve working until '
      '${formatShiftClockOn(until, reference)}$pay';
}

const rejectedRequestLine = "Support didn't approve your last request";

/// "Your extension ended at 8 PM" when an approved extension ran out.
String? extensionEndedLine(ShiftSessionState state) {
  final decision = state.lastDecision;
  if (state.pendingRequest != null ||
      decision == null ||
      decision.status != ShiftRequestStatus.approved ||
      decision.approvedUntil == null) {
    return null;
  }
  return 'Your extension ended at '
      '${formatShiftClockOn(decision.approvedUntil!, state.serverTime)}';
}

String extensionApprovedMessage(ShiftTime? until, ShiftTime? reference) =>
    until == null
        ? 'Extension approved'
        : 'Extension approved until ${formatShiftClockOn(until, reference)}';

String checkoutNoticeMessage(String endReason) =>
    endReason == ShiftEndReason.forcedBySupport
        ? 'Support has checked you out'
        : "Your shift has ended and you've been checked out";

String defaultExtensionPay(ShiftRoster? roster) =>
    roster != null && ShiftPay.isValid(roster.otPayType)
        ? roster.otPayType
        : ShiftPay.overtime;

double defaultExtensionHours(ShiftRoster? roster) {
  final max = roster?.otMaxHours;
  if (roster != null &&
      roster.otAllowed &&
      max != null &&
      shiftExtensionHourChoices.contains(max)) {
    return max;
  }
  return 1;
}

/// Roughly when a request for [hours] would end: extra hours count from
/// extension_base, or from now once that has passed.
ShiftTime? estimateRequestedUntil(
    ShiftSessionState state, double hours, DateTime now) {
  final base = state.extensionBase;
  if (base == null) return null;
  var start = base;
  final server = state.serverTime;
  if (server != null) {
    final elapsed = now.difference(state.receivedAt);
    final serverNow = server.add(elapsed.isNegative ? Duration.zero : elapsed);
    if (serverNow.instant.isAfter(start.instant)) {
      start = ShiftTime(serverNow.instant, base.offset);
    }
  }
  return start.add(Duration(seconds: (hours * 3600).round()));
}

// ---------------------------------------------------------------------------
// Transitions
// ---------------------------------------------------------------------------

/// The approved end time when this refresh shows a new approval; else null.
ShiftTime? approvedUntilOnTransition(
    ShiftSessionState? previous, ShiftSessionState next) {
  if (previous == null || !previous.hasSession || !next.hasSession) return null;
  if (next.status != ShiftStatus.extended) return null;
  if (previous.sessionId != next.sessionId) return null;
  final decision = next.lastDecision;
  final newlyExtended = previous.status != ShiftStatus.extended;
  final newApproval = decision != null &&
      decision.status == ShiftRequestStatus.approved &&
      decision.id != previous.lastDecision?.id;
  if (!newlyExtended && !newApproval) return null;
  return decision?.approvedUntil ?? next.hardLimitAt;
}

/// Is this an auto or support check-out the app hasn't dealt with yet, however
/// long ago it happened?
///
/// [handledMarker] is what the app stored the last time it dealt with one: the
/// ended_at it handled, or `push:` plus a UTC ISO time when it was handled from
/// a push before the server could be reached.
bool isUnhandledServerCheckout(ShiftSessionState state, String? handledMarker) {
  if (state.hasSession) return false;
  final last = state.lastSession;
  final endedAt = last?.endedAt;
  if (last == null || endedAt == null) return false;
  if (last.endReason != ShiftEndReason.auto &&
      last.endReason != ShiftEndReason.forcedBySupport) {
    return false;
  }

  final marker = handledMarker?.trim() ?? '';
  if (marker.isEmpty) return true;
  if (marker == last.endedAtRaw) return false;
  if (marker.startsWith('push:')) {
    final shownAt = DateTime.tryParse(marker.substring(5));
    return shownAt == null ||
        shownAt.toUtc().difference(endedAt.instant).abs() >
            const Duration(minutes: 15);
  }
  final handled = ShiftTime.tryParse(marker);
  return handled == null || endedAt.instant.isAfter(handled.instant);
}

/// Did the check-out in [state] happen recently enough to tell the packer?
bool isRecentCheckout(ShiftSessionState state, {required DateTime now}) {
  final endedAt = state.lastSession?.endedAt;
  if (endedAt == null) return false;
  final serverNow = state.serverTime?.instant ?? now.toUtc();
  return serverNow.difference(endedAt.instant) <= checkoutNoticeWindow;
}

/// Should the "checked out" notice be shown for this state?
bool isNewCheckoutNotice(
  ShiftSessionState state,
  String? handledMarker, {
  required DateTime now,
}) =>
    isUnhandledServerCheckout(state, handledMarker) &&
    isRecentCheckout(state, now: now);

enum ServerCheckoutAction {
  /// Nothing to do.
  none,

  /// Forget the stored check-in and show the packer offline, quietly: the
  /// check-out is too old to announce.
  forgetCheckIn,

  /// Forget the stored check-in, show the packer offline and tell them.
  forgetCheckInAndTell,
}

/// What to do about the check-out in [state].
///
/// The stored check-in is forgotten for every unhandled auto or support
/// check-out, however old: otherwise the next go-online would skip the store
/// QR check-in. Only recent ones are announced.
///
/// [wentOnlineMeanwhile]: the packer went online while this state was being
/// fetched, so it may predate their new check-in. Leave it to the refresh
/// that follows going online.
ServerCheckoutAction serverCheckoutAction(
  ShiftSessionState state,
  String? handledMarker, {
  required DateTime now,
  bool wentOnlineMeanwhile = false,
}) {
  if (wentOnlineMeanwhile) return ServerCheckoutAction.none;
  if (!isUnhandledServerCheckout(state, handledMarker)) {
    return ServerCheckoutAction.none;
  }
  return isRecentCheckout(state, now: now)
      ? ServerCheckoutAction.forgetCheckInAndTell
      : ServerCheckoutAction.forgetCheckIn;
}

// ---------------------------------------------------------------------------
// Polling and the stock audit
// ---------------------------------------------------------------------------

/// Keep refreshing every poll_seconds (in the foreground) while the packer is
/// online, and also while the shift complete screen is up or wanted: an
/// offline packer refused with 409 sits on that screen, and support's answer
/// may never arrive as a push.
bool shouldPollShiftClock({
  required bool online,
  required bool screenOpen,
  required ShiftSessionState? state,
}) =>
    online ||
    screenOpen ||
    (state != null && state.hasSession && state.showDialog);

/// What the shift complete screen says and offers about the stock audit.
class ShiftAuditPrompt {
  final String text;
  final String button;

  const ShiftAuditPrompt({required this.text, required this.button});
}

/// The stock audit a dark-store packer still owes before they can check out,
/// from packerSummary.auditStatus (null for main-store and warehouse packers).
ShiftAuditPrompt? shiftAuditPrompt(AuditStatusEnum? status) {
  switch (status) {
    case AuditStatusEnum.notCreated:
      return const ShiftAuditPrompt(
        text: "This shift's stock audit hasn't been started. "
            'Start it before you check out.',
        button: 'Start stock audit',
      );
    case AuditStatusEnum.ongoing:
      return const ShiftAuditPrompt(
        text: "This shift's stock audit isn't finished. "
            'Finish it before you check out.',
        button: 'Continue stock audit',
      );
    case AuditStatusEnum.completed:
    case null:
      return null;
  }
}

/// Changes whenever something the packer should see again changes.
String shiftSnoozeSignature(ShiftSessionState state) => [
      state.sessionId,
      state.status,
      state.note,
      state.pendingRequest?.id,
      state.lastDecision?.id,
      state.lastDecision?.status,
      state.hardLimitAt?.instant.millisecondsSinceEpoch,
    ].join('|');
