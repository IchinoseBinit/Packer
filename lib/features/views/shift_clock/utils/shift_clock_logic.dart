import 'package:packer/controllers/api/app_exception.dart';
import 'package:packer/features/views/audit_product/models/audit_status_enum.dart';
import 'package:packer/features/views/shift_clock/models/shift_refusal.dart';
import 'package:packer/features/views/shift_clock/models/shift_session.dart';

/// Pure shift clock rules and the words packers and drivers see. No Flutter,
/// no network, so all of it is covered by test/shift_clock_test.dart.

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

/// Added to a local deadline before the app looks again, so the server's own
/// minute tick has had time to move the shift on.
const shiftWakeUpSlack = Duration(seconds: 2);

/// How long the app keeps asking after its own countdown has run out and the
/// server has not moved the shift on yet. The backend tick runs every minute;
/// after this the app waits for a resume, a push or a refresh instead.
const shiftCatchUpWindow = Duration(minutes: 10);

/// The server's note (attendance.services.PACKER_BUSY_NOTE) while a check-out
/// is waiting for the packer to finish what they have in hand.
const packerBusyNote = 'Waiting for the basket/order in hand';

/// The same for a driver (attendance.services.DRIVER_BUSY_NOTE): a load packed
/// for them or on the road that the store at the other end has not received
/// yet. The server only writes it once the grace period is over, so before
/// that the app has to know about the driver's transfers itself (see
/// driverTransferCount). The wording it replaced, "Waiting for the transfer in
/// hand", is still read as work in hand by isWorkInHandNote.
const driverBusyNote = 'Waiting for the transfer to be received';

/// Session roles this app shows the clock for. A driver signs in on this app
/// too, and gets the same clock as a packer.
const shiftClockAppRoles = {'packer', 'driver'};

/// How long work has to look finished before the app believes it is.
///
/// The home screen empties the packer's assigned orders *before* it asks for
/// them again (HomeProvider.initialize -> clearLatestOrder, then
/// fetchLatestOrders), so on every pull to refresh "no order" means "asking
/// the server" for a whole round trip. The blocking screen must not jump up
/// over a packer who is still holding that order, so a work -> none edge is
/// believed only once it has held this long. Work arriving is believed at once.
const shiftWorkSettleDelay = Duration(seconds: 3);

/// True for the data map of a shift clock push (not an order).
bool isShiftClockPush(Map<dynamic, dynamic>? data) =>
    data != null && ShiftPushType.all.contains(data['type']);

/// True for the 409 the packer online-status API sends once the shift is complete.
bool isShiftCompleteError(Object? error) {
  if (error is! AppException || error.statusCode != 409) return false;
  final json = error.json;
  return json is Map && json['error'] == 'shift_complete';
}

/// Was a check-out refused by the server - a 4xx answer - rather than never
/// reaching it or failing on the way? A refusal says something about the
/// person checking out; the rest only say "try again".
bool isCheckoutRefusal(Object? error) {
  if (error is! AppException) return false;
  final code = error.statusCode;
  return code != null && code >= 400 && code < 500;
}

/// A refused check-out whose `error` names a transfer in hand
/// ('transfer_in_hand'). The backend words that refusal only in `message` so
/// far, which is why the app also looks at the driver's transfers itself (see
/// driverCheckoutRefusalStops); this takes the server's word once it gives it.
bool isTransferInHandRefusal(Object? error) {
  if (error is! AppException) return false;
  final json = error.json;
  return json is Map && json['error'] == 'transfer_in_hand';
}

/// Does a driver's refused check-out stop their logout?
///
/// Only a transfer in hand does: they have to deliver it first. The app reads
/// that from the driver's own transfers right after the refusal
/// ([transfersInHand]; null when it could not). Any other refusal is nothing
/// the driver can fix - "No active login session found.", say, once a plain
/// logout has already closed their online log - and stopping on it would
/// leave them on a screen Back does not leave, so the logout goes on, as a
/// packer's does when there is nothing to check out. No answer at all, or a
/// server error, stops it: they can try again.
bool driverCheckoutRefusalStops(Object? error, {required int? transfersInHand}) {
  if (!isCheckoutRefusal(error)) return true;
  if (isTransferInHandRefusal(error)) return true;
  return transfersInHand != 0;
}

/// Shift clock UI applies to a packer's or a driver's own open, enforced
/// session. The summary's `shift` block carries no role, so none means ours.
bool isShiftClockVisible(ShiftSessionState? state) {
  if (state == null || !state.enforced || !state.hasSession) return false;
  return state.role.isEmpty || shiftClockAppRoles.contains(state.role);
}

// ---------------------------------------------------------------------------
// 12-hour times
// ---------------------------------------------------------------------------

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "6 AM", "6:30 PM", "12 PM" in the server's own time. [withMinutes] writes
/// "6:00 AM", for a line that sits beside one of the server's own sentences.
String formatShiftClock(ShiftTime time, {bool withMinutes = false}) {
  final wall = time.wallClock;
  final hour = wall.hour % 12 == 0 ? 12 : wall.hour % 12;
  final suffix = wall.hour < 12 ? 'AM' : 'PM';
  if (wall.minute == 0 && !withMinutes) return '$hour $suffix';
  return '$hour:${wall.minute.toString().padLeft(2, '0')} $suffix';
}

/// [formatShiftClock], plus "tomorrow" / "yesterday" / a date when [time] is
/// not on the same day as [reference].
///
/// [reference] must be the server's clock as it reads now
/// (`state.serverTimeAt(now)`), not the server_time the last response carried:
/// a night shift seeded before midnight would otherwise keep calling its own
/// morning "tomorrow" for the rest of the night.
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
// Work in hand
// ---------------------------------------------------------------------------

/// What the packer or driver still has to finish before the shift clock can
/// check them out - and while any of it is true the blocking screen never
/// shows. A packer holds an order or a basket, a driver a transfer.
enum ShiftWorkInHand { none, order, basket, transfer }

/// True for the server's note about work in hand ("Waiting for the
/// basket/order in hand", "Waiting for the transfer to be received"). A stock
/// audit note ("Waiting for stock audit: ...") is not work in hand: the packer
/// starts that from the shift complete screen.
bool isWorkInHandNote(String note) {
  final text = note.trim().toLowerCase();
  if (text.isEmpty) return false;
  return text == packerBusyNote.toLowerCase() ||
      text == driverBusyNote.toLowerCase() ||
      text.endsWith('in hand');
}

/// Work the packer has in hand: an order assigned to them, a basket session
/// they are still packing, or the server saying it is waiting for one.
ShiftWorkInHand shiftWorkInHand({
  required bool assignedOrder,
  required bool openBasket,
  required String note,
}) {
  if (assignedOrder) return ShiftWorkInHand.order;
  if (openBasket) return ShiftWorkInHand.basket;
  return isWorkInHandNote(note) ? ShiftWorkInHand.order : ShiftWorkInHand.none;
}

/// Work a driver has in hand: a transfer assigned to them that is packed (they
/// may be scanning its baskets onto the vehicle right now) or on the road, or
/// the server saying it is waiting for one.
///
/// The same two statuses hold the driver's check-out on the server
/// (attendance.services.DRIVER_BUSY_STATUSES), which also lets them load a
/// packed transfer past their hours. So a driver held here can always finish:
/// load it, deliver it, and the screen comes once the store has received it.
///
/// [transfers] is how many the app last found (null: it could not find out).
/// Not knowing reads as nothing in hand here, so the status line says only
/// "Shift over"; the blocking screen still waits for a count it could read
/// (see canShowShiftCompleteScreen's workKnown).
ShiftWorkInHand driverWorkInHand({
  required int? transfers,
  required String note,
}) {
  if ((transfers ?? 0) > 0 || isWorkInHandNote(note)) {
    return ShiftWorkInHand.transfer;
  }
  return ShiftWorkInHand.none;
}

/// How many transfers one of the driver transfer lists holds
/// (GET /driver/scan-baskets/ for the packed ones assigned to the driver,
/// GET /driver/in-transit-transfers/ for the ones on the road with them), both
/// `{"transfers": [...]}`.
///
/// Throws a FormatException for anything else: an answer the app cannot read
/// says nothing about whether the driver is carrying stock.
int driverTransferCount(dynamic data) {
  final transfers = data is Map ? data['transfers'] : null;
  if (transfers is! List) {
    throw const FormatException('Unexpected driver transfer list');
  }
  return transfers.length;
}

/// Should the clock look at the driver's transfers along with [state]?
///
/// Only once the shift is over: that is when the transfers decide whether the
/// blocking screen may show and what the status line says. Before that they
/// change nothing, and with enforcement off the clock shows nothing at all,
/// so a driver's app makes no extra calls.
bool shouldCheckDriverTransfers(ShiftSessionState? state) =>
    state != null &&
    isShiftClockVisible(state) &&
    (state.showDialog || isShiftOver(state));

/// May the blocking "Your shift is complete" screen show?
///
/// Only for a shift the clock itself confirmed (a summary seed is checked with
/// GET /attendance/session/ first) that the server says to show, and never
/// while work is in hand: that packer or driver reads it in the home status
/// line and gets the screen as soon as the work is done.
///
/// [workKnown] false: the app could not read what is in hand (a driver's
/// transfers), so it cannot promise there is nothing - no screen until it can.
bool canShowShiftCompleteScreen({
  required ShiftSessionState? state,
  required ShiftWorkInHand work,
  bool workKnown = true,
}) =>
    state != null &&
    isShiftClockVisible(state) &&
    state.showDialog &&
    !state.fromSummary &&
    workKnown &&
    work == ShiftWorkInHand.none;

// ---------------------------------------------------------------------------
// Home status line
// ---------------------------------------------------------------------------

/// Regular hours (or the approved extension) are over.
bool isShiftOver(ShiftSessionState state) =>
    state.shiftComplete ||
    state.status == ShiftStatus.awaitingExtension ||
    state.status == ShiftStatus.closing;

/// "2 h 15 m left", "45 m left", "less than a minute left"; null once [left]
/// has run out or is unknown.
String? shiftCountdown(Duration? left) {
  if (left == null || left <= Duration.zero) return null;
  if (left < const Duration(minutes: 1)) return 'less than a minute left';
  final hours = left.inHours;
  final minutes = left.inMinutes % 60;
  if (hours == 0) return '$minutes m left';
  if (minutes == 0) return '$hours h left';
  return '$hours h $minutes m left';
}

/// "Shift ends 6 PM · 2 h 15 m left", "Extension until 8 PM", "Shift over",
/// "Shift over · finish this order" or, for a driver, "Shift over · deliver
/// this transfer"; null when hidden.
///
/// The countdown runs off the phone clock corrected against server_time, so a
/// phone set to the wrong time still shows the right time left.
String? shiftStatusLine(
  ShiftSessionState state, {
  DateTime? now,
  ShiftWorkInHand work = ShiftWorkInHand.none,
}) {
  if (!isShiftClockVisible(state)) return null;
  if (isShiftOver(state)) {
    switch (work) {
      case ShiftWorkInHand.order:
        return 'Shift over · finish this order';
      case ShiftWorkInHand.basket:
        return 'Shift over · finish this basket';
      case ShiftWorkInHand.transfer:
        return 'Shift over · deliver this transfer';
      case ShiftWorkInHand.none:
        return 'Shift over';
    }
  }
  final at = now ?? DateTime.now();
  if (state.status == ShiftStatus.extended) {
    final until = state.hardLimitAt;
    return until == null
        ? 'Extension approved'
        : 'Extension until ${formatShiftClockOn(until, state.serverTimeAt(at))}';
  }
  final end = state.regularLimitAt;
  if (end == null) return 'On shift';
  final line = 'Shift ends ${formatShiftClockOn(end, state.serverTimeAt(at))}';
  final left = shiftCountdown(state.remainingTo(end, at));
  return left == null ? line : '$line · $left';
}

/// True while [shiftStatusLine] has a countdown in it that still has to move,
/// so the home card only ticks while something is actually counting down.
bool shiftStatusLineTicks(ShiftSessionState? state, DateTime now) {
  if (state == null || !isShiftClockVisible(state)) return false;
  if (isShiftOver(state) || state.status == ShiftStatus.extended) return false;
  return shiftCountdown(state.remainingTo(state.regularLimitAt, now)) != null;
}

/// The smaller line under the status.
String shiftStatusDetail(
  ShiftSessionState state, {
  DateTime? now,
  ShiftWorkInHand work = ShiftWorkInHand.none,
}) {
  if (isShiftOver(state)) {
    if (state.pendingRequest != null) {
      return 'Waiting for support to approve more time';
    }
    switch (work) {
      case ShiftWorkInHand.none:
        return 'Tap to ask for more time or check out';
      case ShiftWorkInHand.transfer:
        // A transfer holds the driver until the store at the other end scans
        // it in, not until they hand it over: say what ends the wait, or a
        // driver who has delivered keeps waiting for a screen with no idea why.
        return 'Once the store receives it, ask for more time or check out';
      case ShiftWorkInHand.order:
      case ShiftWorkInHand.basket:
        return 'Finish it, then ask for more time or check out';
    }
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
      : 'Started ${formatShiftClockOn(started, state.serverTimeAt(now ?? DateTime.now()))}';
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
        '${formatShiftClockOn(hardLimit, state.serverTimeAt(now))} '
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
String? extensionEndedLine(ShiftSessionState state, {DateTime? now}) {
  final decision = state.lastDecision;
  if (state.pendingRequest != null ||
      decision == null ||
      decision.status != ShiftRequestStatus.approved ||
      decision.approvedUntil == null) {
    return null;
  }
  return 'Your extension ended at '
      '${formatShiftClockOn(decision.approvedUntil!, state.serverTimeAt(now ?? DateTime.now()))}';
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
// When to look at the clock again
// ---------------------------------------------------------------------------

/// How long to wait before looking at the clock again, from the shift's own
/// deadlines: the next of the shift end and the grace deadline still ahead on
/// the server's clock. Null when there is nothing to wait for - no enforced
/// session, no times, or both deadlines already passed - and the app then
/// waits for a resume, a push or a refresh instead.
Duration? shiftWakeUpDelay(ShiftSessionState? state, DateTime now) {
  if (state == null || !state.enforced || !state.hasSession) return null;
  Duration? best;
  for (final deadline in [state.regularLimitAt, state.hardLimitAt]) {
    final left = state.remainingTo(deadline, now);
    if (left == null || left <= Duration.zero) continue;
    if (best == null || left < best) best = left;
  }
  return best == null ? null : best + shiftWakeUpSlack;
}

/// Keep asking every poll_seconds (in the foreground) only while something is
/// genuinely waiting on an answer: the shift complete screen is up or wanted,
/// support is holding a request, the shift is past its regular hours
/// (awaiting_extension) or running on an approved extension, or the app's own
/// countdown has just run out and the server's minute tick has yet to catch
/// up. Anything else - enforcement off, or the shift end still ahead - runs on
/// the local countdown ([shiftWakeUpDelay]) with no repeating calls at all.
bool shouldPollShiftClock({
  required bool screenOpen,
  required ShiftSessionState? state,
  DateTime? now,
}) {
  if (screenOpen) return true;
  if (state == null || !state.enforced || !state.hasSession) return false;
  if (state.showDialog || state.pendingRequest != null) return true;
  if (state.status == ShiftStatus.awaitingExtension ||
      state.status == ShiftStatus.extended ||
      state.status == ShiftStatus.closing) {
    return true;
  }
  final left = state.remainingTo(state.regularLimitAt, now ?? DateTime.now());
  return left != null && left <= Duration.zero && left > -shiftCatchUpWindow;
}

// ---------------------------------------------------------------------------
// The stock audit
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Sign-in refused outside the shift
// ---------------------------------------------------------------------------

/// The heading over a sign-in refusal. Packers and drivers sign in on the same
/// screen, so nothing here names a role.
String shiftRefusalTitle(ShiftRefusal refusal) {
  switch (refusal.code) {
    case ShiftRefusalCode.shiftNotStarted:
      return "Your shift hasn't started yet";
    case ShiftRefusalCode.shiftOver:
      return 'Your shift is over';
    default:
      // not_rostered: the server's sentence under it says why and who can
      // put it right, so the heading only says what happened.
      return "You can't sign in right now";
  }
}

/// The server's own sentence, which says when they can sign in. Should one
/// ever come without it, what the code alone can tell them.
String shiftRefusalMessage(ShiftRefusal refusal) {
  if (refusal.message.isNotEmpty) return refusal.message;
  switch (refusal.code) {
    case ShiftRefusalCode.shiftNotStarted:
      return 'You can sign in shortly before your shift starts.';
    case ShiftRefusalCode.shiftOver:
      return 'Sign in again when your next shift starts.';
    default:
      return "You are not on today's roster. Ask your manager to add you to it.";
  }
}

/// "Day shift · 6:00 AM – 6:00 PM" for the shift a refusal names, with
/// "tomorrow", "yesterday" or the date after the name when it does not start
/// today. Null when it names none: not_rostered, and a sign-in the clock ended.
///
/// A refusal carries no server_time, so "today" is [now] - the phone's clock -
/// read in the shift's own offset.
String? shiftRefusalShiftLine(ShiftRefusal refusal, {DateTime? now}) {
  final start = refusal.startsAt;
  if (start == null) return null;
  final name = refusal.shiftName;
  var label = name.isEmpty
      ? 'Your shift'
      : name.toLowerCase().contains('shift')
          ? name
          : '$name shift';

  final phone = ShiftTime((now ?? DateTime.now()).toUtc(), start.offset);
  final day = _dateOnly(start.wallClock);
  final days = day.difference(_dateOnly(phone.wallClock)).inDays;
  if (days == 1) {
    label = '$label tomorrow';
  } else if (days == -1) {
    label = '$label yesterday';
  } else if (days != 0) {
    label = '$label, ${day.day} ${_months[day.month - 1]}';
  }

  final from = formatShiftClock(start, withMinutes: true);
  final end = refusal.endsAt;
  final times = end == null
      ? 'from $from'
      : '$from – ${formatShiftClock(end, withMinutes: true)}';
  return '$label · $times';
}
