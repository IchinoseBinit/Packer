import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart'
    show Headers, HttpClientAdapter, RequestOptions, ResponseBody;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:packer/constants/app_constants.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/constants/secure_storage_constants.dart';
import 'package:packer/controllers/api/app_exception.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/api/error_handler.dart';
import 'package:packer/controllers/api/model/custom_exception.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/hive_db/basket_dao.dart';
import 'package:packer/controllers/services/hive_db/hive_db_service.dart';
import 'package:packer/controllers/services/router.dart';
import 'package:packer/controllers/services/secure_storage_helper.dart';
import 'package:packer/features/views/auth/provider/auth_provider.dart';
import 'package:packer/features/views/audit_product/models/audit_status_enum.dart';
import 'package:packer/features/views/auth/model/order_notification.dart';
import 'package:packer/features/views/auth/model/packer_summary.dart';
import 'package:packer/features/views/auth/model/user.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/auth/views/login_screen.dart';
import 'package:packer/features/views/driver/controller/driver_controller.dart';
import 'package:packer/features/views/driver/views/driver_home_screen.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:packer/features/views/shift_clock/models/shift_refusal.dart';
import 'package:packer/features/views/shift_clock/models/shift_session.dart';
import 'package:packer/features/views/shift_clock/providers/shift_clock_provider.dart';
import 'package:packer/features/views/shift_clock/repo/shift_clock_repo.dart';
import 'package:packer/features/views/shift_clock/screens/shift_complete_screen.dart';
import 'package:packer/features/views/shift_clock/utils/shift_clock_logic.dart';
import 'package:packer/features/views/shift_clock/utils/sign_in_refusal.dart';
import 'package:packer/features/views/shift_clock/widgets/shift_refusal_card.dart';
import 'package:packer/features/views/shift_clock/widgets/shift_status_card.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:packer/features/views/widgets/post_basket_model.dart';

ShiftTime at(String iso) => ShiftTime.tryParse(iso)!;

/// Phone clock when the fixture "arrived" (18:10 Kathmandu).
final received = DateTime.utc(2026, 9, 15, 12, 25);

Map<String, dynamic> openSession([Map<String, dynamic> changes = const {}]) => {
      'has_session': true,
      'enforced': true,
      'poll_seconds': 60,
      'server_time': '2026-09-15T18:10:00+05:45',
      'session_id': 7,
      // Past the grace: stopped. The extra time before it is extraTime() below.
      'status': 'closing',
      'role': 'packer',
      'started_at': '2026-09-15T06:00:00+05:45',
      'regular_hours': 12.0,
      'regular_limit_at': '2026-09-15T18:00:00+05:45',
      'hard_limit_at': '2026-09-15T19:00:00+05:45',
      'seconds_to_regular_limit': -600,
      'seconds_to_hard_limit': 3000,
      'shift_complete': true,
      'in_extra_time': false,
      'locked': false,
      'show_dialog': true,
      'show_warning': false,
      'can_take_work': false,
      'can_request': true,
      'note': '',
      'extra_hours_pay': 'overtime',
      'extension_base': '2026-09-15T18:10:00+05:45',
      'roster': {
        'shift': 'Day',
        'ot_allowed': true,
        'ot_pay_type': 'overtime',
        'ot_max_hours': 2.0,
      },
      'pending_request': null,
      'last_decision': null,
      ...changes,
    };

Map<String, dynamic> request([Map<String, dynamic> changes = const {}]) => {
      'id': 31,
      'status': 'pending',
      'requested_at': '2026-09-15T18:05:00+05:45',
      'requested_hours': 2.0,
      'requested_until': '2026-09-15T20:00:00+05:45',
      'requested_pay': 'overtime',
      'reason': 'Evening rush',
      'matches_roster': true,
      'reviewed_at': null,
      'review_note': '',
      'approved_until': null,
      'approved_pay': null,
      ...changes,
    };

/// The same shift ten minutes earlier: past the regular hours, inside the
/// grace. Warned, still packing, still taking orders - the screen stays away.
Map<String, dynamic> extraTime([Map<String, dynamic> changes = const {}]) =>
    openSession({
      'status': 'awaiting_extension',
      'shift_complete': false,
      'in_extra_time': true,
      'show_dialog': false,
      'show_warning': true,
      'can_take_work': true,
      ...changes,
    });

ShiftSessionState parse(Map<String, dynamic> json) =>
    ShiftSessionState.fromJson(json, receivedAt: received);

/// The `shift` block the packer summary carries (contract A): a subset of the
/// session payload, with no roster, requests or seconds_to_* countdowns.
Map<String, dynamic> shiftBlock([Map<String, dynamic> changes = const {}]) => {
      'enforced': true,
      'has_session': true,
      'session_id': 7,
      'status': 'active',
      'started_at': '2026-09-15T06:00:00+05:45',
      'regular_limit_at': '2026-09-15T18:00:00+05:45',
      'hard_limit_at': '2026-09-15T19:00:00+05:45',
      'server_time': '2026-09-15T16:00:00+05:45',
      'shift_complete': false,
      'show_dialog': false,
      'can_take_work': true,
      'can_request': true,
      'note': '',
      'extra_hours_pay': 'overtime',
      'poll_seconds': 60,
      ...changes,
    };

ShiftSessionState seed(Map<String, dynamic> json, {DateTime? receivedAt}) =>
    ShiftSessionState.fromSummaryJson(json,
        receivedAt: receivedAt ?? received)!;

String isoUtc(DateTime time) => time.toUtc().toIso8601String();

/// An open session around the phone's own clock, for the provider tests: the
/// shift ends [endsIn] from now and the grace period runs [grace] longer.
Map<String, dynamic> liveSession({
  Duration endsIn = const Duration(hours: 2),
  Duration grace = const Duration(hours: 1),
  Map<String, dynamic> changes = const {},
}) {
  final now = DateTime.now();
  return openSession({
    'status': 'active',
    'shift_complete': false,
    'show_dialog': false,
    'can_take_work': true,
    'server_time': isoUtc(now),
    'started_at': isoUtc(now.subtract(const Duration(hours: 8))),
    'regular_limit_at': isoUtc(now.add(endsIn)),
    'hard_limit_at': isoUtc(now.add(endsIn + grace)),
    'seconds_to_regular_limit': endsIn.inSeconds,
    'seconds_to_hard_limit': (endsIn + grace).inSeconds,
    'extension_base': isoUtc(now.add(endsIn)),
    ...changes,
  });
}

/// [liveSession] read as it would be on arrival (receivedAt = now).
ShiftSessionState parseLive(Map<String, dynamic> json) =>
    ShiftSessionState.fromJson(json);

/// The summary's `shift` block for [liveSession]'s shift.
Map<String, dynamic> liveShiftBlock({
  Duration endsIn = const Duration(hours: 2),
  Duration grace = const Duration(hours: 1),
  Map<String, dynamic> changes = const {},
}) {
  final now = DateTime.now();
  return shiftBlock({
    'server_time': isoUtc(now),
    'started_at': isoUtc(now.subtract(const Duration(hours: 8))),
    'regular_limit_at': isoUtc(now.add(endsIn)),
    'hard_limit_at': isoUtc(now.add(endsIn + grace)),
    ...changes,
  });
}

/// [liveShiftBlock] read as it would be on arrival (receivedAt = now).
ShiftSessionState liveSeed({
  Duration endsIn = const Duration(hours: 2),
  Duration grace = const Duration(hours: 1),
  Map<String, dynamic> changes = const {},
}) =>
    ShiftSessionState.fromSummaryJson(
        liveShiftBlock(endsIn: endsIn, grace: grace, changes: changes))!;

OrderNotification anOrder() => OrderNotification.fromJson({
      'order_id': 91,
      'customer_name': 'Anita',
      'status': 'packer_assigned',
    });

Map<String, dynamic> noSession(Map<String, dynamic>? last) => {
      'has_session': false,
      'enforced': true,
      'poll_seconds': 60,
      'server_time': '2026-09-15T19:30:00+05:45',
      'can_take_work': true,
      'show_dialog': false,
      'locked': false,
      'last_session': last,
    };

// The roster sign-in gate's sentences (attendance.login_gate, services).
const notStartedMessage =
    'Your shift starts at 6:00 AM. You can sign in from 5:00 AM.';
const overMessage =
    'Your shift ended at 6:00 PM. Your next shift starts at 6:00 AM tomorrow.';
const notRosteredMessage =
    "You are not on today's roster. Ask your manager to add you to it.";
const clockSignedOutMessage =
    'Your shift has ended and you have been checked out. Sign in again when your next shift starts.';

/// The gate's 403 body (login_gate.Refusal.as_json).
Map<String, dynamic> refusalBody(String code, String message,
        [Map<String, dynamic>? shift]) =>
    {'success': false, 'error': code, 'message': message, 'shift': shift};

/// A refusal's `shift` block: 6 AM to 6 PM on [date].
Map<String, dynamic> dayShift([String date = '2026-09-15']) => {
      'starts_at': '${date}T06:00:00+05:45',
      'ends_at': '${date}T18:00:00+05:45',
      'name': 'Day',
    };

/// Today on the server's clock (+05:45), for a screen that reads the phone's.
String kathmanduToday() {
  final now =
      DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 45));
  String two(int n) => n.toString().padLeft(2, '0');
  return '${now.year}-${two(now.month)}-${two(now.day)}';
}

void main() {
  group('ShiftTime', () {
    test('keeps the server offset whatever the phone time zone is', () {
      final time = at('2026-09-15T18:00:00+05:45');
      expect(time.instant, DateTime.utc(2026, 9, 15, 12, 15));
      expect(time.offset, const Duration(hours: 5, minutes: 45));
      expect(time.wallClock.hour, 18);
      expect(time.wallClock.minute, 0);
    });

    test('reads Z, microseconds and rejects garbage', () {
      expect(at('2026-09-15T12:15:00Z').offset, Duration.zero);
      expect(at('2026-09-15T18:00:00.123456+05:45').wallClock.hour, 18);
      expect(ShiftTime.tryParse('not a time'), isNull);
      expect(ShiftTime.tryParse(''), isNull);
      expect(ShiftTime.tryParse(null), isNull);
      expect(ShiftTime.tryParse(42), isNull);
    });
  });

  group('parsing', () {
    test('no open session', () {
      final state = parse(noSession({
        'ended_at': '2026-09-15T19:05:00+05:45',
        'end_reason': 'auto',
      }));
      expect(state.hasSession, isFalse);
      expect(state.enforced, isTrue);
      expect(state.showDialog, isFalse);
      expect(state.canTakeWork, isTrue);
      expect(state.lastSession?.endReason, ShiftEndReason.auto);
      expect(state.lastSession?.endedAtRaw, '2026-09-15T19:05:00+05:45');
      expect(isShiftClockVisible(state), isFalse);
    });

    test('open session with roster, pending request and decision', () {
      final state = parse(openSession({
        'pending_request': request(),
        'last_decision': request({
          'id': 30,
          'status': 'rejected',
          'review_note': 'Enough packers tonight',
          'reviewed_at': '2026-09-15T18:02:00+05:45',
        }),
        'can_request': false,
      }));
      expect(state.hasSession, isTrue);
      expect(state.sessionId, 7);
      expect(state.status, ShiftStatus.closing);
      expect(state.regularHours, 12.0);
      expect(state.showDialog, isTrue);
      expect(state.showWarning, isFalse);
      expect(state.inExtraTime, isFalse);
      expect(state.canRequest, isFalse);
      expect(state.roster?.otAllowed, isTrue);
      expect(state.roster?.otPayType, ShiftPay.overtime);
      expect(state.roster?.otMaxHours, 2.0);
      expect(state.extraHoursPay, ShiftPay.overtime,
          reason: 'the server works the pay out from the roster placement');
      expect(state.pendingRequest?.id, 31);
      expect(state.pendingRequest?.requestedUntil, at('2026-09-15T20:00:00+05:45'));
      expect(state.pendingRequest?.approvedPay, isNull);
      expect(state.lastDecision?.status, ShiftRequestStatus.rejected);
      expect(state.lastDecision?.reviewNote, 'Enough packers tonight');
      expect(isShiftClockVisible(state), isTrue);
    });

    test('the two marks the clock has: warned, then stopped', () {
      final warned = parse(extraTime());
      expect(warned.status, ShiftStatus.awaitingExtension);
      expect(warned.inExtraTime, isTrue);
      expect(warned.showWarning, isTrue);
      expect(warned.showDialog, isFalse);
      expect(warned.canTakeWork, isTrue);
      expect(isInExtraTime(warned), isTrue);
      expect(isShiftOver(warned), isFalse,
          reason: 'past the regular hours is not stopped: they pack on');

      final stopped = parse(openSession());
      expect(isInExtraTime(stopped), isFalse);
      expect(isShiftOver(stopped), isTrue);
      expect(stopped.canTakeWork, isFalse);
    });

    test('an older backend that sends neither flag still reads the status', () {
      final json = openSession({
        'status': 'awaiting_extension',
        'shift_complete': false,
        'show_dialog': false,
      })
        ..remove('in_extra_time')
        ..remove('show_warning');
      final warned = parse(json);
      expect(warned.inExtraTime, isFalse);
      expect(isInExtraTime(warned), isTrue,
          reason: 'awaiting_extension without shift_complete is the extra time');
    });

    test('missing keys, nulls and wrong types fall back to showing nothing', () {
      final empty = ShiftSessionState.fromJson(const {});
      expect(empty.hasSession, isFalse);
      expect(empty.enforced, isFalse);
      expect(empty.showDialog, isFalse);
      expect(empty.canTakeWork, isTrue);
      expect(empty.pollSeconds, ShiftSessionState.defaultPollSeconds);
      expect(empty.lastSession, isNull);
      expect(empty.extraHoursPay, isNull);

      final odd = parse({
        'has_session': 'true',
        'enforced': 1,
        'poll_seconds': '5',
        'session_id': '7',
        'regular_hours': '12',
        'roster': 'Day',
        'pending_request': <dynamic>[],
        'last_decision': {'status': 'approved', 'approved_pay': 'double'},
        'note': null,
        'show_dialog': null,
        'extra_hours_pay': 3,
      });
      expect(odd.hasSession, isTrue);
      expect(odd.enforced, isTrue);
      expect(odd.pollSeconds, ShiftSessionState.minPollSeconds);
      expect(odd.sessionId, 7);
      expect(odd.regularHours, 12);
      expect(odd.roster, isNull);
      expect(odd.pendingRequest, isNull);
      expect(odd.lastDecision?.id, isNull);
      expect(odd.lastDecision?.approvedPay, isNull);
      expect(odd.note, '');
      expect(odd.showDialog, isFalse);
      expect(odd.canRequest, isFalse);
      expect(odd.extraHoursPay, isNull);
    });

    test('show_dialog without a session is ignored', () {
      expect(parse({'has_session': false, 'show_dialog': true}).showDialog,
          isFalse);
    });
  });

  group('12-hour times', () {
    test('formats hours and minutes', () {
      expect(formatShiftClock(at('2026-09-15T18:00:00+05:45')), '6 PM');
      expect(formatShiftClock(at('2026-09-15T18:30:00+05:45')), '6:30 PM');
      expect(formatShiftClock(at('2026-09-15T06:05:00+05:45')), '6:05 AM');
      expect(formatShiftClock(at('2026-09-15T00:00:00+05:45')), '12 AM');
      expect(formatShiftClock(at('2026-09-15T12:00:00+05:45')), '12 PM');
      expect(formatShiftClock(at('2026-09-15T23:59:00+05:45')), '11:59 PM');
    });

    test('uses the offset the server sent', () {
      expect(formatShiftClock(at('2026-09-15T12:15:00Z')), '12:15 PM');
    });

    test('names the day when it is not today', () {
      final now = at('2026-09-15T22:00:00+05:45');
      expect(formatShiftClockOn(at('2026-09-15T23:00:00+05:45'), now), '11 PM');
      expect(formatShiftClockOn(at('2026-09-16T06:00:00+05:45'), now),
          '6 AM tomorrow');
      expect(formatShiftClockOn(at('2026-09-14T22:00:00+05:45'), now),
          '10 PM yesterday');
      expect(formatShiftClockOn(at('2026-09-18T09:00:00+05:45'), now),
          '9 AM, 18 Sep');
      expect(formatShiftClockOn(at('2026-09-16T06:00:00+05:45'), null), '6 AM');
    });

    test('formats hours', () {
      expect(formatShiftHours(0.5), '30 min');
      expect(formatShiftHours(1), '1 h');
      expect(formatShiftHours(1.5), '1 h 30 min');
      expect(formatShiftHours(2), '2 h');
      expect(shiftExtensionHourChoices.map(formatShiftHours),
          ['30 min', '1 h', '2 h', '3 h', '4 h']);
    });
  });

  group('home status line', () {
    test('active, extended and over', () {
      final active = parse(openSession({
        'status': 'active',
        'shift_complete': false,
        'show_dialog': false,
        'server_time': '2026-09-15T13:00:00+05:45',
      }));
      // server_time 1 PM arrived at [received], so 5 h of shift are left.
      expect(shiftStatusLine(active, now: received),
          'Shift ends 6 PM · 5 h left');
      expect(shiftStatusDetail(active, now: received), 'Started 6 AM');

      final extended = parse(openSession({
        'status': 'extended',
        'shift_complete': false,
        'show_dialog': false,
        'hard_limit_at': '2026-09-15T20:00:00+05:45',
        'last_decision': request({
          'status': 'approved',
          'approved_until': '2026-09-15T20:00:00+05:45',
          'approved_pay': 'overtime',
        }),
      }));
      expect(shiftStatusLine(extended, now: received), 'Extension until 8 PM');
      expect(shiftStatusDetail(extended, now: received),
          'Approved at overtime pay');

      final over = parse(openSession());
      expect(shiftStatusLine(over, now: received), 'Shift over');
      expect(shiftStatusDetail(over, now: received),
          'Tap to ask for more time or check out');
      expect(
          shiftStatusDetail(parse(openSession({'pending_request': request()})),
              now: received),
          'Waiting for support to approve more time');
    });

    test('says what to finish first while work is in hand', () {
      final over = parse(openSession());
      expect(shiftStatusLine(over, now: received, work: ShiftWorkInHand.order),
          'Shift over · finish this order');
      expect(shiftStatusLine(over, now: received, work: ShiftWorkInHand.basket),
          'Shift over · finish this basket');
      expect(shiftStatusDetail(over, now: received, work: ShiftWorkInHand.order),
          'Finish it, then ask for more time or check out');
      // Support already has a request: that is the news, work or not.
      expect(
        shiftStatusDetail(parse(openSession({'pending_request': request()})),
            now: received, work: ShiftWorkInHand.order),
        'Waiting for support to approve more time',
      );
      // Still on shift: the countdown, whatever is in hand.
      final active = parse(openSession({
        'status': 'active',
        'shift_complete': false,
        'show_dialog': false,
        'server_time': '2026-09-15T17:30:00+05:45',
      }));
      expect(shiftStatusLine(active, now: received, work: ShiftWorkInHand.order),
          'Shift ends 6 PM · 30 m left');
    });

    test('the day word follows the clock, not the last response (packer-2)', () {
      // A 22:00 - 06:00 shift, seeded at 22:05 and never asked about again:
      // this round's whole point is that the app can hold one response for the
      // length of a shift. The countdown moves, so the day word must too.
      final seededAt = DateTime.utc(2026, 9, 15, 16, 20); // 22:05 +05:45
      final night = seed(
        shiftBlock({
          'started_at': '2026-09-15T22:00:00+05:45',
          'regular_limit_at': '2026-09-16T06:00:00+05:45',
          'hard_limit_at': '2026-09-16T07:00:00+05:45',
          'server_time': '2026-09-15T22:05:00+05:45',
        }),
        receivedAt: seededAt,
      );
      expect(shiftStatusLine(night, now: seededAt),
          'Shift ends 6 AM tomorrow · 7 h 55 m left');
      expect(shiftStatusDetail(night, now: seededAt), 'Started 10 PM');

      // 03:05, same response: it is the 16th now, so 6 AM is today.
      final afterMidnight = seededAt.add(const Duration(hours: 5));
      expect(shiftStatusLine(night, now: afterMidnight),
          'Shift ends 6 AM · 2 h 55 m left');
      expect(shiftStatusDetail(night, now: afterMidnight),
          'Started 10 PM yesterday');
      expect(
          graceLine(night, afterMidnight),
          'Your extra time runs to 7 AM. After that no new work comes until '
          'support approves more');
    });

    test('the extra time says so and leaves the work alone', () {
      final warned = parse(extraTime());
      expect(shiftStatusLine(warned, now: received),
          'Extra time until 7 PM · 50 m left');
      expect(shiftStatusDetail(warned, now: received),
          'Ask for more time or check out before it runs out');
      expect(shiftStatusLineTicks(warned, received), isTrue,
          reason: 'the countdown to the grace mark is still moving');
      expect(
        canShowShiftCompleteScreen(
            state: warned, work: ShiftWorkInHand.none),
        isFalse,
        reason: 'no screen while they are still working',
      );
    });

    test('a request waiting for support shows in the extra time too', () {
      final warned = parse(extraTime({'pending_request': request()}));
      expect(shiftStatusDetail(warned, now: received),
          'Waiting for support to approve more time');
    });

    test('hidden when not enforced, no session or not a packer session', () {
      expect(shiftStatusLine(parse(openSession({'enforced': false}))), isNull);
      expect(shiftStatusLine(parse(noSession(null))), isNull);
      expect(shiftStatusLine(parse(openSession({'role': 'rider'}))), isNull);
      expect(shiftStatusLine(parse(openSession({'role': null})), now: received),
          'Shift over');
    });
  });

  group('countdown (packer-5)', () {
    test('hours and minutes, and nothing once it has run out', () {
      expect(shiftCountdown(const Duration(hours: 2, minutes: 15)),
          '2 h 15 m left');
      expect(shiftCountdown(const Duration(hours: 2)), '2 h left');
      expect(shiftCountdown(const Duration(minutes: 45)), '45 m left');
      expect(shiftCountdown(const Duration(minutes: 1)), '1 m left');
      expect(shiftCountdown(const Duration(seconds: 30)),
          'less than a minute left');
      expect(shiftCountdown(Duration.zero), isNull);
      expect(shiftCountdown(const Duration(minutes: -5)), isNull);
      expect(shiftCountdown(null), isNull);
      // The seconds inside a minute are dropped, never rounded up.
      expect(shiftCountdown(const Duration(minutes: 119, seconds: 59)),
          '1 h 59 m left');
    });

    test('runs off the server clock, not the phone one', () {
      final state = seed(shiftBlock());
      // server_time 4 PM against a phone reading 6:10 PM: 2 h of shift left.
      expect(state.clockSkew, const Duration(hours: -2, minutes: -10));
      expect(state.serverInstantAt(received), DateTime.utc(2026, 9, 15, 10, 15));
      expect(state.remainingTo(state.regularLimitAt, received),
          const Duration(hours: 2));
      expect(shiftStatusLine(state, now: received),
          'Shift ends 6 PM · 2 h left');

      // The same block on a phone running three hours fast still says 2 h.
      final fast = seed(shiftBlock(),
          receivedAt: received.add(const Duration(hours: 3)));
      expect(
          shiftStatusLine(fast, now: received.add(const Duration(hours: 3))),
          'Shift ends 6 PM · 2 h left');

      // Twenty minutes later, twenty minutes less.
      expect(
        shiftStatusLine(state, now: received.add(const Duration(minutes: 20))),
        'Shift ends 6 PM · 1 h 40 m left',
      );
    });

    test('the home card only ticks while a countdown is running', () {
      final state = seed(shiftBlock());
      expect(shiftStatusLineTicks(state, received), isTrue);
      // Run out, over, on an extension, hidden or nothing at all: no ticking.
      expect(
          shiftStatusLineTicks(
              state, received.add(const Duration(hours: 2))),
          isFalse);
      expect(shiftStatusLineTicks(parse(openSession()), received), isFalse);
      expect(
          shiftStatusLineTicks(
              parse(openSession({
                'status': 'extended',
                'shift_complete': false,
                'show_dialog': false,
              })),
              received),
          isFalse);
      expect(
          shiftStatusLineTicks(
              seed(shiftBlock({'enforced': false})), received),
          isFalse);
      expect(
          shiftStatusLineTicks(
              seed(shiftBlock({'regular_limit_at': null})), received),
          isFalse);
      expect(shiftStatusLineTicks(null, received), isFalse);
    });

    test('no server_time leaves the phone clock as it is', () {
      // No server_time: the phone clock is taken as it is.
      final noServerTime = seed(shiftBlock({'server_time': null}));
      expect(noServerTime.clockSkew, Duration.zero);
      expect(noServerTime.remainingTo(noServerTime.regularLimitAt, received),
          const Duration(minutes: -10));
      expect(shiftStatusLine(noServerTime, now: received), 'Shift ends 6 PM');
    });
  });

  group('shift complete screen', () {
    test('roster line', () {
      expect(rosterLine(null), "You're not on today's roster");
      expect(
        rosterLine(const ShiftRoster(
            shift: 'Day', otAllowed: false, otPayType: '', otMaxHours: null)),
        'No overtime planned on your roster',
      );
      expect(rosterLine(parse(openSession()).roster),
          'Your roster allows overtime at overtime pay, up to 2 h');
      expect(
        rosterLine(const ShiftRoster(
            shift: 'Night',
            otAllowed: true,
            otPayType: 'normal',
            otMaxHours: null)),
        'Your roster allows overtime at normal pay',
      );
    });

    test('grace line', () {
      final state = parse(openSession());
      expect(
          graceLine(state, received),
          'Your extra time runs to 7 PM. After that no new work comes until '
          'support approves more');
      final later = received.add(const Duration(seconds: 3001));
      expect(graceLine(state, later),
          'Your time is up. Ask support for more, or check out');
      expect(
        graceLine(parse(openSession({'pending_request': request()})), later),
        'Support is looking at your request. Nothing else happens until they decide',
      );
    });

    test('pending, rejected, ended and approved lines', () {
      final state = parse(openSession({'pending_request': request()}));
      expect(pendingRequestLine(state.pendingRequest!, state.serverTime),
          'Waiting for support to approve working until 8 PM at overtime pay');
      expect(rejectedRequestLine, "Support didn't approve your last request");
      expect(
        extensionEndedLine(
            parse(openSession({
              'last_decision': request({
                'status': 'approved',
                'approved_until': '2026-09-15T20:00:00+05:45',
              }),
            })),
            now: received),
        'Your extension ended at 8 PM',
      );
      expect(extensionEndedLine(parse(openSession()), now: received), isNull);
      expect(extensionApprovedMessage(at('2026-09-15T20:00:00+05:45'), null),
          'Extension approved until 8 PM');
    });

    test('check-out notices', () {
      expect(checkoutNoticeMessage(ShiftEndReason.auto),
          "Your shift has ended and you've been checked out");
      expect(checkoutNoticeMessage(ShiftEndReason.forcedBySupport),
          'Support has checked you out');
    });

    test('the hours the form starts on come from the roster', () {
      final roster = parse(openSession()).roster;
      expect(defaultExtensionHours(roster), 2);
      expect(defaultExtensionHours(null), 1);
      expect(
        defaultExtensionHours(const ShiftRoster(
            shift: 'Day', otAllowed: true, otPayType: 'normal', otMaxHours: 6)),
        1,
      );
    });

    test('the pay is the server\'s word, never a choice on the form', () {
      expect(extraHoursPayLine(ShiftPay.normal),
          'Extra hours will be paid at normal pay.');
      expect(extraHoursPayLine(ShiftPay.overtime),
          'Extra hours will be paid at overtime pay.');

      // Rostered where overtime is allowed: the roster's own pay.
      expect(extraHoursPayLine(parse(openSession()).extraHoursPay),
          'Extra hours will be paid at overtime pay.');

      // Rostered with no overtime allowed, and not rostered at all: the form
      // is still offered, at normal pay.
      final noOvertime = parse(openSession({
        'extra_hours_pay': 'normal',
        'roster': {
          'shift': 'Day',
          'ot_allowed': false,
          'ot_pay_type': '',
          'ot_max_hours': null,
        },
      }));
      expect(noOvertime.canRequest, isTrue);
      expect(extraHoursPayLine(noOvertime.extraHoursPay),
          'Extra hours will be paid at normal pay.');
      final offRoster = parse(openSession({
        'extra_hours_pay': 'normal',
        'roster': null,
      }));
      expect(offRoster.canRequest, isTrue);
      expect(extraHoursPayLine(offRoster.extraHoursPay),
          'Extra hours will be paid at normal pay.');

      // Nothing to say: an older server, no session, or a word we don't know.
      expect(extraHoursPayLine(null), isNull);
      expect(extraHoursPayLine(''), isNull);
      expect(extraHoursPayLine('double'), isNull);
      expect(parse(openSession({'extra_hours_pay': null})).extraHoursPay,
          isNull);
    });

    test('estimated end of a request', () {
      final state = parse(openSession());
      expect(formatShiftClock(estimateRequestedUntil(state, 2, received)!),
          '8:10 PM');
      final later = received.add(const Duration(minutes: 10));
      expect(formatShiftClock(estimateRequestedUntil(state, 2, later)!),
          '8:20 PM');
      final ahead = parse(openSession({
        'extension_base': '2026-09-15T20:00:00+05:45',
      }));
      expect(formatShiftClock(estimateRequestedUntil(ahead, 0.5, later)!),
          '8:30 PM');
    });
  });

  group('asking for more time', () {
    late _FakeServer server;
    final requestPath = Uri.parse(AppUrls.attendanceRequestUrl).path;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      DioClient.token = packerJwt();
      DioClient.refreshToken = '';
      server = _FakeServer();
      DioClient().httpClientAdapter = server;
    });

    tearDown(() => DioClient.token = '');

    test('the request carries the hours and the reason, and no pay', () async {
      server.answer(
          AppUrls.attendanceRequestUrl,
          201,
          openSession({
            'pending_request': request(),
            'can_request': false,
          }));

      final state = await ShiftClockRepo.requestExtension(
          hours: 2, reason: 'Evening rush');

      expect(server.calls, ['POST $requestPath']);
      final body =
          jsonDecode(server.bodies[requestPath] as String) as Map<String, dynamic>;
      // The server works the pay out from the roster placement when the
      // request is made; this app has nothing to say about it.
      expect(body, {'hours': 2.0, 'reason': 'Evening rush'});
      expect(body.containsKey('pay_type'), isFalse);
      expect(state.pendingRequest?.id, 31);
      expect(state.canRequest, isFalse);
      expect(state.extraHoursPay, ShiftPay.overtime);
    });

    test('an empty reason is still sent, and no pay with it', () async {
      server.answer(AppUrls.attendanceRequestUrl, 201,
          openSession({'extra_hours_pay': 'normal'}));

      final state = await ShiftClockRepo.requestExtension(hours: 0.5);

      final body =
          jsonDecode(server.bodies[requestPath] as String) as Map<String, dynamic>;
      expect(body, {'hours': 0.5, 'reason': ''});
      expect(state.extraHoursPay, ShiftPay.normal);
    });
  });

  group('decisions', () {
    test('shift pushes are told apart from orders', () {
      expect(isShiftClockPush({'type': 'shift_limit_reached'}), isTrue);
      expect(isShiftClockPush({'type': 'shift_extension_decided'}), isTrue);
      expect(isShiftClockPush({'type': 'shift_auto_checkout', 'by': 'support'}),
          isTrue);
      expect(isShiftClockPush({'order_id': '12'}), isFalse);
      expect(isShiftClockPush({'type': 'order'}), isFalse);
      expect(isShiftClockPush(null), isFalse);
    });

    test('409 shift_complete from going online', () {
      expect(
        isShiftCompleteError(AppException(
          statusCode: 409,
          message: 'Your shift is complete.',
          json: {'success': false, 'error': 'shift_complete', 'message': 'x'},
        )),
        isTrue,
      );
      expect(
        isShiftCompleteError(AppException(
            statusCode: 400, message: 'x', json: {'error': 'shift_complete'})),
        isFalse,
      );
      expect(isShiftCompleteError(AppException(statusCode: 409, message: 'x')),
          isFalse);
      expect(isShiftCompleteError(Exception('409')), isFalse);
    });

    test('approval is announced once, on the change', () {
      final waiting = parse(openSession({'pending_request': request()}));
      final approved = parse(openSession({
        'status': 'extended',
        'show_dialog': false,
        'shift_complete': false,
        'hard_limit_at': '2026-09-15T20:00:00+05:45',
        'last_decision': request({
          'status': 'approved',
          'approved_until': '2026-09-15T20:00:00+05:45',
        }),
      }));
      expect(approvedUntilOnTransition(waiting, approved),
          at('2026-09-15T20:00:00+05:45'));
      expect(approvedUntilOnTransition(null, approved), isNull);
      expect(approvedUntilOnTransition(approved, approved), isNull);

      final approvedAgain = parse(openSession({
        'status': 'extended',
        'hard_limit_at': '2026-09-15T21:00:00+05:45',
        'last_decision': request({
          'id': 40,
          'status': 'approved',
          'approved_until': '2026-09-15T21:00:00+05:45',
        }),
      }));
      expect(approvedUntilOnTransition(approved, approvedAgain),
          at('2026-09-15T21:00:00+05:45'));
      expect(
          approvedUntilOnTransition(
              parse(openSession({'session_id': 6})), approved),
          isNull);
    });

    test('check-out notice shows once, only for auto or support check-outs', () {
      final now = DateTime.utc(2026, 9, 15, 13, 45);
      ShiftSessionState ended(String reason,
              [String endedAt = '2026-09-15T19:05:00+05:45']) =>
          parse(noSession({'ended_at': endedAt, 'end_reason': reason}));

      expect(isNewCheckoutNotice(ended('auto'), null, now: now), isTrue);
      expect(isNewCheckoutNotice(ended('forced_by_support'), '', now: now),
          isTrue);
      expect(isNewCheckoutNotice(ended('manual'), null, now: now), isFalse);
      expect(
          isNewCheckoutNotice(ended('auto'), '2026-09-15T19:05:00+05:45',
              now: now),
          isFalse);
      expect(
          isNewCheckoutNotice(ended('auto'), '2026-09-14T19:05:00+05:45',
              now: now),
          isTrue);
      expect(
          isNewCheckoutNotice(ended('auto', '2026-09-15T05:00:00+05:45'), null,
              now: now),
          isFalse);
      expect(
          isNewCheckoutNotice(ended('auto'), 'push:2026-09-15T13:25:00.000Z',
              now: now),
          isFalse);
      expect(
          isNewCheckoutNotice(ended('auto'), 'push:2026-09-14T13:25:00.000Z',
              now: now),
          isTrue);
      expect(isNewCheckoutNotice(parse(openSession()), null, now: now), isFalse);
      expect(isNewCheckoutNotice(parse(noSession(null)), null, now: now),
          isFalse);
    });

  });

  // -------------------------------------------------------------------------
  // Review repairs: packer-1 .. packer-4
  // -------------------------------------------------------------------------

  group('check-out clean-up is separate from the notice (packer-3)', () {
    final now = DateTime.utc(2026, 9, 16, 2, 25);
    ShiftSessionState checkedOut(String reason,
            {String endedAt = '2026-09-15T19:05:00+05:45',
            String serverTime = '2026-09-16T08:10:00+05:45'}) =>
        parse({
          ...noSession({'ended_at': endedAt, 'end_reason': reason}),
          'server_time': serverTime,
        });

    test('an auto check-out first seen 13 h later still forgets the check-in',
        () {
      final stale = checkedOut('auto');
      expect(isNewCheckoutNotice(stale, null, now: now), isFalse,
          reason: 'too old to announce');
      expect(isUnhandledServerCheckout(stale, null), isTrue);
      expect(serverCheckoutAction(stale, null, now: now),
          ServerCheckoutAction.forgetCheckIn);
      expect(serverCheckoutAction(checkedOut('forced_by_support'), null, now: now),
          ServerCheckoutAction.forgetCheckIn);
    });

    test('a recent one is forgotten and announced', () {
      final recent = checkedOut('auto', serverTime: '2026-09-15T19:30:00+05:45');
      expect(serverCheckoutAction(recent, null, now: now),
          ServerCheckoutAction.forgetCheckInAndTell);
    });

    test('handled, manual and newer check-ins are left alone', () {
      final stale = checkedOut('auto');
      expect(serverCheckoutAction(stale, '2026-09-15T19:05:00+05:45', now: now),
          ServerCheckoutAction.none);
      expect(
          serverCheckoutAction(stale, 'push:2026-09-15T13:25:00.000Z', now: now),
          ServerCheckoutAction.none);
      expect(serverCheckoutAction(stale, '2026-09-14T19:05:00+05:45', now: now),
          ServerCheckoutAction.forgetCheckIn);
      expect(serverCheckoutAction(checkedOut('manual'), null, now: now),
          ServerCheckoutAction.none);
      expect(serverCheckoutAction(parse(openSession()), null, now: now),
          ServerCheckoutAction.none);
      expect(
          serverCheckoutAction(stale, null,
              now: now, wentOnlineMeanwhile: true),
          ServerCheckoutAction.none,
          reason: 'the packer checked in while this state was being fetched');
    });
  });

  group('work in hand (packer-6)', () {
    test('an order, a basket or the server saying it is waiting for one', () {
      ShiftWorkInHand work({
        bool order = false,
        bool basket = false,
        String note = '',
      }) =>
          shiftWorkInHand(
              assignedOrder: order, openBasket: basket, note: note);

      expect(work(order: true), ShiftWorkInHand.order);
      expect(work(basket: true), ShiftWorkInHand.basket);
      expect(work(note: packerBusyNote), ShiftWorkInHand.order);
      expect(work(note: '  waiting for the delivery in hand '),
          ShiftWorkInHand.order);
      expect(work(), ShiftWorkInHand.none);
      // A stock audit is not work in hand: it is started from the screen.
      expect(work(note: 'Waiting for stock audit: 12 racks left'),
          ShiftWorkInHand.none);
      expect(work(note: 'Locked to day closing'), ShiftWorkInHand.none);
      // An order in hand wins: that is the wording the packer gets.
      expect(work(order: true, basket: true), ShiftWorkInHand.order);
    });

    test('the blocking screen waits for the work to be done', () {
      final complete = parse(openSession());
      expect(
          canShowShiftCompleteScreen(
              state: complete, work: ShiftWorkInHand.none),
          isTrue);
      expect(
          canShowShiftCompleteScreen(
              state: complete, work: ShiftWorkInHand.order),
          isFalse);
      expect(
          canShowShiftCompleteScreen(
              state: complete, work: ShiftWorkInHand.basket),
          isFalse);

      // A shift only the summary has told us about is confirmed with
      // GET /attendance/session/ first.
      expect(
        canShowShiftCompleteScreen(
          state: seed(shiftBlock(
              {'status': 'awaiting_extension', 'show_dialog': true})),
          work: ShiftWorkInHand.none,
        ),
        isFalse,
      );

      // Nothing to show.
      for (final json in [
        openSession({'show_dialog': false}),
        openSession({'enforced': false}),
        openSession({'role': 'rider'}),
        noSession(null),
      ]) {
        expect(
            canShowShiftCompleteScreen(
                state: parse(json), work: ShiftWorkInHand.none),
            isFalse,
            reason: json.toString());
      }
      expect(
          canShowShiftCompleteScreen(state: null, work: ShiftWorkInHand.none),
          isFalse);
    });
  });

  group('when to look at the clock again (packer-4, packer-5)', () {
    test('waits for the shift end, then for the grace deadline', () {
      final state = seed(shiftBlock());
      // 2 h to the shift end, 3 h to the grace deadline.
      expect(shiftWakeUpDelay(state, received),
          const Duration(hours: 2) + shiftWakeUpSlack);
      // Past the shift end: the grace deadline is next.
      final late = received.add(const Duration(hours: 2, minutes: 30));
      expect(shiftWakeUpDelay(state, late),
          const Duration(minutes: 30) + shiftWakeUpSlack);
      // Both gone: nothing to wait for, a resume or a push does the rest.
      expect(
          shiftWakeUpDelay(state, received.add(const Duration(hours: 4))),
          isNull);
      expect(shiftWakeUpDelay(null, received), isNull);
      expect(shiftWakeUpDelay(seed(shiftBlock({'enforced': false})), received),
          isNull);
      expect(shiftWakeUpDelay(parse(noSession(null)), received), isNull);
      // No limits sent at all.
      expect(
        shiftWakeUpDelay(
            seed(shiftBlock(
                {'regular_limit_at': null, 'hard_limit_at': null})),
            received),
        isNull,
      );
    });

    test('polls only while something is waiting on an answer', () {
      bool polls(ShiftSessionState? state, {bool screenOpen = false}) =>
          shouldPollShiftClock(
              screenOpen: screenOpen, state: state, now: received);

      // The shift complete screen is up, or wanted.
      expect(polls(null, screenOpen: true), isTrue);
      expect(polls(parse(openSession())), isTrue);
      // Support is holding a request, or has approved one.
      expect(
          polls(parse(openSession({
            'status': 'extended',
            'shift_complete': false,
            'show_dialog': false,
          }))),
          isTrue);
      expect(
          polls(parse(openSession({
            'status': 'active',
            'shift_complete': false,
            'show_dialog': false,
            'pending_request': request(),
          }))),
          isTrue);
      // The local countdown has just run out: the server's minute tick has
      // yet to catch up.
      expect(polls(seed(shiftBlock({
            'server_time': '2026-09-15T18:01:00+05:45',
          }))),
          isTrue);
    });

    test('nothing repeating while the shift end is still ahead', () {
      bool polls(ShiftSessionState? state) =>
          shouldPollShiftClock(screenOpen: false, state: state, now: received);

      expect(polls(seed(shiftBlock())), isFalse, reason: '2 h still to go');
      expect(polls(seed(shiftBlock({'enforced': false}))), isFalse);
      expect(polls(parse(noSession(null))), isFalse);
      expect(polls(null), isFalse);
      // Long past the shift end with the server still calling it active: stop
      // asking rather than poll for ever.
      expect(
          polls(seed(shiftBlock({
            'server_time': '2026-09-15T18:30:00+05:45',
          }))),
          isFalse);
    });
  });

  group('the summary shift block (packer-5)', () {
    test('a missing or broken block is ignored', () {
      expect(ShiftSessionState.fromSummaryJson(null), isNull);
      expect(ShiftSessionState.fromSummaryJson('nonsense'), isNull);
      final empty = ShiftSessionState.fromSummaryJson({})!;
      expect(empty.enforced, isFalse);
      expect(empty.hasSession, isFalse);
      expect(empty.showDialog, isFalse);
      expect(empty.canTakeWork, isTrue);
      expect(empty.pollSeconds, ShiftSessionState.defaultPollSeconds);
      expect(shiftStatusLine(empty, now: received), isNull);
      expect(shiftWakeUpDelay(empty, received), isNull);
    });

    test('is read like the clock itself, minus what it does not carry', () {
      final state = seed(shiftBlock());
      expect(state.fromSummary, isTrue);
      expect(state.enforced, isTrue);
      expect(state.hasSession, isTrue);
      expect(state.sessionId, 7);
      expect(state.status, ShiftStatus.active);
      expect(state.role, isEmpty, reason: 'the block sends no role');
      expect(state.canRequest, isTrue);
      expect(state.regularLimitAt, at('2026-09-15T18:00:00+05:45'));
      expect(state.hardLimitAt, at('2026-09-15T19:00:00+05:45'));
      expect(state.roster, isNull);
      expect(state.pendingRequest, isNull);
      expect(state.lastDecision, isNull);
      expect(state.secondsToHardLimit, isNull);
      // Worked out from hard_limit_at and the clock correction instead.
      expect(state.secondsToHardLimitAt(received), 3 * 3600);
      expect(isShiftClockVisible(state), isTrue);
    });

    test('merged over the clock: it keeps the roster and the request', () {
      final clock = parse(openSession({
        'status': 'active',
        'shift_complete': false,
        'show_dialog': false,
        'can_take_work': true,
        'pending_request': request(),
        'can_request': false,
      }));
      final same = clock.withSeed(seed(shiftBlock({'can_request': false}),
          receivedAt: received.add(const Duration(minutes: 5))));
      expect(same.fromSummary, isFalse,
          reason: 'nothing new: no need to ask the clock');
      expect(same.roster, isNotNull);
      expect(same.pendingRequest?.id, 31);
      expect(same.extensionBase, isNotNull);
      expect(same.receivedAt, received.add(const Duration(minutes: 5)));
      expect(same.role, 'packer', reason: 'kept: the block sends no role');
      expect(same.status, ShiftStatus.active);

      // The seed says the shift is over: shown in the status line, but the
      // screen waits for GET /attendance/session/ to confirm it.
      final over = clock.withSeed(seed(shiftBlock({
        'status': 'awaiting_extension',
        'shift_complete': true,
        'show_dialog': true,
        'can_take_work': false,
        'can_request': false,
        'note': packerBusyNote,
      })));
      expect(over.fromSummary, isTrue);
      expect(over.shiftComplete, isTrue);
      expect(over.note, packerBusyNote);
      expect(over.roster, isNotNull);
      expect(shiftStatusLine(over, now: received), 'Shift over');
      expect(
          canShowShiftCompleteScreen(
              state: over, work: ShiftWorkInHand.none),
          isFalse);

      // Support decided the request while the app was not looking.
      final decided = clock.withSeed(seed(shiftBlock()));
      expect(decided.fromSummary, isTrue);
      expect(decided.pendingRequest, isNull,
          reason: 'can_request true means the server holds no request');
    });

    test('it carries the pay for extra hours, and an older one keeps ours',
        () {
      expect(seed(shiftBlock()).extraHoursPay, ShiftPay.overtime);

      final clock = parse(openSession());
      expect(clock.extraHoursPay, ShiftPay.overtime);

      // The roster placement changed while the app was not looking.
      final moved =
          clock.withSeed(seed(shiftBlock({'extra_hours_pay': 'normal'})));
      expect(moved.extraHoursPay, ShiftPay.normal);

      // A backend whose summary doesn't send it yet: keep the clock's word.
      final older = clock.withSeed(seed(shiftBlock({'extra_hours_pay': null})));
      expect(older.extraHoursPay, ShiftPay.overtime);
    });

    test('a different session, or none, replaces what we had', () {
      final clock = parse(openSession());
      final next = clock.withSeed(seed(shiftBlock({'session_id': 8})));
      expect(next.sessionId, 8);
      expect(next.roster, isNull);
      expect(next.pendingRequest, isNull);
      expect(next.fromSummary, isTrue);

      final ended = clock.withSeed(seed(shiftBlock({
        'has_session': false,
        'session_id': null,
        'status': null,
        'shift_complete': false,
        'show_dialog': false,
        'can_request': false,
      })));
      expect(ended.hasSession, isFalse);
      expect(ended.fromSummary, isTrue, reason: 'the check-out is confirmed');
      expect(shiftStatusLine(ended, now: received), isNull);

      // Nothing new about a packer who is already checked out.
      final checkedOut = parse(noSession({
        'ended_at': '2026-09-15T19:05:00+05:45',
        'end_reason': 'auto',
      }));
      final still = checkedOut.withSeed(seed(shiftBlock({
        'has_session': false,
        'session_id': null,
        'status': null,
        'shift_complete': false,
        'show_dialog': false,
        'can_request': false,
      })));
      expect(still.fromSummary, isFalse, reason: 'nothing to confirm');
      expect(still.lastSession?.endReason, ShiftEndReason.auto,
          reason: 'the block sends no last_session; keep ours');
    });
  });

  group('stock audit prompt (packer-2)', () {
    test('offers to start or continue an owed audit', () {
      final start = shiftAuditPrompt(AuditStatusEnum.notCreated);
      expect(start?.button, 'Start stock audit');
      expect(start?.text,
          "This shift's stock audit hasn't been started. Start it before you check out.");
      final resume = shiftAuditPrompt(AuditStatusEnum.ongoing);
      expect(resume?.button, 'Continue stock audit');
      expect(resume?.text,
          "This shift's stock audit isn't finished. Finish it before you check out.");
    });

    test('nothing once done, or for main-store and warehouse packers', () {
      expect(shiftAuditPrompt(AuditStatusEnum.completed), isNull);
      expect(shiftAuditPrompt(null), isNull);
    });
  });

  group('drivers (driver-1)', () {
    test('a driver session is shown like a packer one, other roles still are not',
        () {
      final driver = parse(openSession({'role': 'driver'}));
      expect(isShiftClockVisible(driver), isTrue);
      expect(shiftStatusLine(driver, now: received), 'Shift over');
      for (final role in ['rider', 'staff', 'manager', 'tagger']) {
        expect(isShiftClockVisible(parse(openSession({'role': role}))), isFalse,
            reason: role);
      }
    });

    test('a transfer packed for them or on the road, or the server waiting for one',
        () {
      ShiftWorkInHand work({int? transfers, String note = ''}) =>
          driverWorkInHand(transfers: transfers, note: note);

      expect(work(transfers: 1), ShiftWorkInHand.transfer);
      expect(work(transfers: 3), ShiftWorkInHand.transfer);
      expect(work(transfers: 0, note: driverBusyNote), ShiftWorkInHand.transfer);
      // attendance.services.DRIVER_BUSY_NOTE, word for word (p-1): the server
      // holds a driver until the load is received, and says so.
      expect(work(note: 'Waiting for the transfer to be received'),
          ShiftWorkInHand.transfer);
      // ...and the wording it had before.
      expect(work(note: '  waiting for the transfer in hand '),
          ShiftWorkInHand.transfer);
      expect(work(transfers: 0), ShiftWorkInHand.none);
      // Not knowing says nothing in the words; the screen has its own gate.
      expect(work(), ShiftWorkInHand.none);
      // Never a packer's audit.
      expect(work(transfers: 0, note: 'Waiting for stock audit: 12 racks left'),
          ShiftWorkInHand.none);
    });

    test('the words a driver reads', () {
      final over = parse(openSession({'role': 'driver'}));
      expect(
          shiftStatusLine(over, now: received, work: ShiftWorkInHand.transfer),
          'Shift over · deliver this transfer');
      // What ends the wait is the store receiving it, not the hand-over
      // (p-1): a driver who has delivered is not told to deliver again.
      expect(
          shiftStatusDetail(over,
              now: received, work: ShiftWorkInHand.transfer),
          'Once the store receives it, ask for more time or check out');
      expect(shiftStatusDetail(over, now: received),
          'Tap to ask for more time or check out');
    });

    test('a refused check-out stops a driver only over a transfer in hand (p-2)',
        () {
      final noLog = AppException(
        statusCode: 400,
        message: 'No active login session found.',
        json: {'success': false, 'message': 'No active login session found.'},
      );
      final coded = AppException(
        statusCode: 400,
        message: 'Deliver it first.',
        json: {'success': false, 'error': 'transfer_in_hand'},
      );
      final offline = AppException(message: 'Cannot process at the moment.');
      final serverDown = AppException(statusCode: 502, message: 'Bad gateway');

      expect(isCheckoutRefusal(noLog), isTrue);
      expect(isCheckoutRefusal(AppException(statusCode: 404, message: 'x')),
          isTrue);
      for (final error in <Object?>[
        offline,
        serverDown,
        const SocketException('no network'),
        null,
      ]) {
        expect(isCheckoutRefusal(error), isFalse, reason: '$error');
      }
      expect(isTransferInHandRefusal(coded), isTrue);
      expect(isTransferInHandRefusal(noLog), isFalse);

      bool stops(Object? error, int? transfers) =>
          driverCheckoutRefusalStops(error, transfersInHand: transfers);

      // Nothing in hand: the refusal is nothing the driver can fix, so the
      // logout goes on.
      expect(stops(noLog, 0), isFalse);
      // A transfer in hand, or no way to tell: they stay and are told why.
      expect(stops(noLog, 1), isTrue);
      expect(stops(noLog, null), isTrue);
      // The server naming the transfer is believed over the app's own look.
      expect(stops(coded, 0), isTrue);
      // No answer, or the server failing: nothing was refused - try again.
      expect(stops(offline, 0), isTrue);
      expect(stops(serverDown, 0), isTrue);
      expect(stops(const SocketException('no network'), 0), isTrue);
    });

    test('no blocking screen over a transfer, or over transfers nobody could read',
        () {
      final complete = parse(openSession({'role': 'driver'}));
      expect(
          canShowShiftCompleteScreen(
              state: complete, work: ShiftWorkInHand.none),
          isTrue);
      expect(
          canShowShiftCompleteScreen(
              state: complete, work: ShiftWorkInHand.transfer),
          isFalse);
      expect(
          canShowShiftCompleteScreen(
              state: complete, work: ShiftWorkInHand.none, workKnown: false),
          isFalse);
    });

    test('reads the driver transfer lists, and refuses anything else', () {
      Map<String, dynamic> transfer(int id) => {
            'inventory_transfer_id': id,
            'transfer_identifier': 'transfer-Mother Warehouse-Nayabazar DS-$id',
            'destination_store_id': 7,
            'destination_store_name': 'Nayabazar DS',
            'destination_store_latitude': 27.728817,
            'destination_store_longitude': 85.309325,
            'basket_identifiers': ['basket-Nayabazar DS-328c62'],
          };
      expect(driverTransferCount({'transfers': []}), 0);
      expect(driverTransferCount({'transfers': [transfer(15), transfer(16)]}), 2);
      for (final junk in <dynamic>[
        null,
        'Server in deployment phase',
        <String, dynamic>{},
        {'transfers': null},
        {'transfers': 'none'},
        [transfer(15)],
      ]) {
        expect(() => driverTransferCount(junk), throwsFormatException,
            reason: '$junk');
      }
    });

    test('transfers are looked at only once an enforced shift is over', () {
      expect(shouldCheckDriverTransfers(parse(openSession({'role': 'driver'}))),
          isTrue);
      for (final json in [
        // Still on shift, or on an approved extension: nothing to decide.
        openSession({
          'role': 'driver',
          'status': 'active',
          'shift_complete': false,
          'show_dialog': false,
        }),
        openSession({
          'role': 'driver',
          'status': 'extended',
          'shift_complete': false,
          'show_dialog': false,
        }),
        // Enforcement off: the clock shows nothing, so it asks nothing.
        openSession({'role': 'driver', 'enforced': false, 'show_dialog': false}),
        noSession(null),
      ]) {
        expect(shouldCheckDriverTransfers(parse(json)), isFalse,
            reason: json.toString());
      }
      expect(shouldCheckDriverTransfers(null), isFalse);
    });
  });

  group('ShiftClockProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      DioClient.token = packerJwt();
    });

    testWidgets(
        'packer-1: keeps running when a second dashboard goes away, stops with the last',
        (tester) async {
      var loads = 0;
      final home = _TestHome()..isOnline = true;
      final clock = ShiftClockProvider(loadSession: () async {
        loads++;
        return parse(openSession({
          'status': 'active',
          'shift_complete': false,
          'show_dialog': false,
          'poll_seconds': 15,
          // Support is holding a request, which is one of the few things the
          // clock keeps asking about.
          'pending_request': request(),
          'can_request': false,
        }));
      });
      _dashboards.clear();

      final router = GoRouter(initialLocation: '/', routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('splash')),
          routes: [
            GoRoute(
                path: 'dashboard', builder: (_, __) => const _FakeDashboard()),
            GoRoute(
                path: 'order-details',
                builder: (_, __) => const Scaffold(body: Text('order'))),
            GoRoute(
                path: 'login',
                builder: (_, __) => const Scaffold(body: Text('login'))),
          ],
        ),
      ]);
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<HomeProvider>.value(value: home),
          ChangeNotifierProvider<ShiftClockProvider>.value(value: clock),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));

      // Dashboard A after an order (go), then an order call pushes dashboard
      // B and order details, then the order ends with go(dashboard).
      router.go('/dashboard');
      await tester.pumpAndSettle();
      router.push('/dashboard');
      await tester.pumpAndSettle();
      router.push('/order-details');
      await tester.pumpAndSettle();
      router.go('/dashboard');
      await tester.pumpAndSettle();

      expect(_dashboards.length, 2);
      expect(_dashboards[0].mounted, isTrue, reason: 'dashboard A still shown');
      expect(_dashboards[1].mounted, isFalse, reason: 'dashboard B disposed');
      expect(clock.isRunning, isTrue);
      expect(clock.isPolling, isTrue);
      expect(clock.visibleSession, isNotNull);

      final before = loads;
      await tester.pump(const Duration(seconds: 16));
      expect(loads, before + 1, reason: 'still polling');

      // Logout / session expiry: the last dashboard goes.
      router.go('/login');
      await tester.pumpAndSettle();
      expect(_dashboards[0].mounted, isFalse);
      expect(clock.isRunning, isFalse);
      expect(clock.isScheduled, isFalse);
    });

    testWidgets(
        'packer-3: an auto check-out first seen 13 h later forgets the check-in quietly',
        (tester) async {
      FlutterSecureStorage.setMockInitialValues(
          {SecureStorageConstants.isOnlineKey: 'true'});
      final home = _TestHome();
      final owner = Object();
      final clock = ShiftClockProvider(
          loadSession: () async => parse({
                ...noSession({
                  'ended_at': '2026-09-15T19:05:00+05:45',
                  'end_reason': 'auto',
                }),
                'server_time': '2026-09-16T08:10:00+05:45',
              }));

      await clock.start(home, owner: owner);
      await tester.pump();

      expect(
          await SecureStorageHelper()
              .readKey(key: SecureStorageConstants.isOnlineKey),
          isNull,
          reason: 'next go-online asks for the store QR check-in again');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('shift_clock_checkout_notice_5'),
          '2026-09-15T19:05:00+05:45');
      expect(home.summaryFetches, 1, reason: 'shown offline');

      // Seen again: already handled.
      await clock.refresh();
      expect(home.summaryFetches, 1);

      clock.stop(owner: owner);
    });

    testWidgets(
        'packer-3: a check-out fetched while the packer was checking in is left alone',
        (tester) async {
      FlutterSecureStorage.setMockInitialValues(
          {SecureStorageConstants.isOnlineKey: 'true'});
      final home = _TestHome();
      final owner = Object();
      final clock = ShiftClockProvider(loadSession: () async {
        // QR check-in and going online happened while this was in flight.
        home.isOnline = true;
        return parse({
          ...noSession({
            'ended_at': '2026-09-15T19:05:00+05:45',
            'end_reason': 'auto',
          }),
          'server_time': '2026-09-16T08:10:00+05:45',
        });
      });

      await clock.start(home, owner: owner);
      await tester.pump();

      expect(
          await SecureStorageHelper()
              .readKey(key: SecureStorageConstants.isOnlineKey),
          'true');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('shift_clock_checkout_notice_5'), isNull);
      expect(home.summaryFetches, 0);

      clock.stop(owner: owner);
    });

    testWidgets(
        'packer-4: after a 409 the clock keeps refreshing while offline and the screen is wanted',
        (tester) async {
      var next = openSession({
        'status': 'active',
        'shift_complete': false,
        'show_dialog': false,
        'poll_seconds': 15,
      });
      var loads = 0;
      final home = _TestHome();
      final owner = Object();
      final clock = ShiftClockProvider(loadSession: () async {
        loads++;
        return parse(next);
      });

      // Offline, nothing to show: nothing to poll.
      await clock.start(home, owner: owner);
      expect(clock.isPolling, isFalse);

      // Taps ONLINE after regular hours: toggleOnlineStatus flips isOnline,
      // the PATCH is refused with 409 shift_complete, and it flips back.
      next = openSession({'poll_seconds': 15, 'pending_request': request()});
      home.isOnline = true;
      final refused = clock.onShiftCompleteRefused();
      home.setOnline(false);
      await refused;
      expect(clock.wantsScreen, isTrue);
      expect(clock.isPolling, isTrue);

      // Support rejects and the push is lost: the next poll shows it.
      next = openSession({
        'poll_seconds': 15,
        'last_decision': request({
          'status': 'rejected',
          'review_note': 'Enough packers tonight',
        }),
      });
      final before = loads;
      await tester.pump(const Duration(seconds: 16));
      expect(loads, before + 1);
      expect(clock.state?.lastDecision?.status, ShiftRequestStatus.rejected);
      expect(clock.state?.pendingRequest, isNull);
      expect(clock.isPolling, isTrue);

      clock.stop(owner: owner);
      expect(clock.isPolling, isFalse);
      // Let the wait for a free navigator (there is none here) give up.
      await tester.pump(const Duration(seconds: 31));
    });

    testWidgets(
        'packer-5: counts the shift down itself and asks once when the time is up',
        (tester) async {
      var loads = 0;
      var next = liveSession(endsIn: const Duration(hours: 2));
      final home = _TestHome()..isOnline = true;
      final owner = Object();
      final clock = ShiftClockProvider(loadSession: () async {
        loads++;
        return parseLive(next);
      });

      // The summary fetched at login already knows when this shift ends.
      home.setShift(liveSeed());
      await clock.start(home, owner: owner);
      await tester.pump();

      expect(loads, 1, reason: 'one confirming call at start');
      expect(clock.isPolling, isFalse, reason: 'the shift end is 2 h away');
      expect(clock.isWaitingForDeadline, isTrue);
      expect(clock.state?.regularLimitAt, isNotNull);

      // Another summary arrives saying nothing new: no call, still no poll.
      home.setShift(liveSeed());
      await tester.pump();
      expect(loads, 1);
      expect(clock.state?.fromSummary, isFalse, reason: 'nothing to confirm');
      expect(clock.isPolling, isFalse);
      expect(clock.isWaitingForDeadline, isTrue);

      // Two hours of shift go by without a single call.
      await tester.pump(const Duration(hours: 1));
      expect(loads, 1);
      await tester.pump(const Duration(hours: 1));
      expect(loads, 1, reason: 'the local countdown has not run out yet');

      // The shift ends: the app's own timer fires and confirms it once.
      next = liveSession(endsIn: Duration.zero, changes: {
        'status': 'awaiting_extension',
        'shift_complete': true,
        'show_dialog': true,
        'can_take_work': false,
      });
      await tester.pump(const Duration(seconds: 5));
      expect(loads, 2,
          reason: 'one GET /attendance/session/ when the timer fires');
      expect(clock.state?.showDialog, isTrue);
      expect(clock.wantsScreen, isTrue);
      expect(clock.isPolling, isTrue,
          reason: 'now waiting on support or a check-out');

      clock.stop(owner: owner);
      expect(clock.isScheduled, isFalse);
      // Let the wait for a free navigator (there is none here) give up.
      await tester.pump(const Duration(seconds: 31));
    });

    testWidgets(
        'packer-5: a summary saying the shift is over is confirmed before the screen shows',
        (tester) async {
      var loads = 0;
      var next = liveSession(endsIn: const Duration(hours: 2));
      final home = _TestHome()..isOnline = true;
      final owner = Object();
      final clock = ShiftClockProvider(loadSession: () async {
        loads++;
        return parseLive(next);
      });

      home.setShift(liveSeed());
      await clock.start(home, owner: owner);
      await tester.pump();
      expect(loads, 1);
      expect(clock.wantsScreen, isFalse);

      // The next summary says the shift is over. The status line follows it
      // at once; the blocking screen waits for the clock itself.
      next = liveSession(endsIn: Duration.zero, changes: {
        'status': 'awaiting_extension',
        'shift_complete': true,
        'show_dialog': true,
        'can_take_work': false,
      });
      home.setShift(liveSeed(endsIn: Duration.zero, changes: {
        'status': 'awaiting_extension',
        'shift_complete': true,
        'show_dialog': true,
        'can_take_work': false,
        'can_request': false,
      }));
      expect(clock.state?.fromSummary, isTrue);
      expect(clock.state?.shiftComplete, isTrue);
      expect(shiftStatusLine(clock.visibleSession!, now: DateTime.now()),
          'Shift over');
      expect(clock.wantsScreen, isFalse, reason: 'not confirmed yet');

      await tester.pump();
      expect(loads, 2, reason: 'the seed is confirmed with the clock');
      expect(clock.state?.fromSummary, isFalse);
      expect(clock.wantsScreen, isTrue);

      clock.stop(owner: owner);
      await tester.pump(const Duration(seconds: 31));
    });

    testWidgets(
        'packer-6: work in hand keeps the blocking screen away until it is done',
        (tester) async {
      var next = openSession({'poll_seconds': 15});
      final home = _TestHome()
        ..isOnline = true
        ..latestOrder = [anOrder()];
      final orders = _TestOrders();
      final owner = Object();
      final clock = ShiftClockProvider(loadSession: () async => parse(next));

      await clock.start(home, owner: owner, order: orders);
      await tester.pump();

      final session = clock.visibleSession!;
      expect(session.showDialog, isTrue);
      expect(clock.workInHand, ShiftWorkInHand.order);
      expect(clock.wantsScreen, isFalse, reason: 'an order is still in hand');
      expect(shiftStatusLine(session, now: received, work: clock.workInHand),
          'Shift over · finish this order');
      expect(shiftStatusDetail(session, now: received, work: clock.workInHand),
          'Finish it, then ask for more time or check out');
      // Nothing to open from the home card either.
      clock.openScreen();
      expect(clock.wantsScreen, isFalse);

      // The order goes out, but a basket is still being packed.
      orders.setBaskets([Basket(identifier: 'B1', productIdentifiers: const [])]);
      home.setOrders(const []);
      await tester.pump();
      expect(clock.workInHand, ShiftWorkInHand.basket);
      expect(clock.wantsScreen, isFalse);
      expect(shiftStatusLine(session, now: received, work: clock.workInHand),
          'Shift over · finish this basket');

      // The basket is closed. Work only counts as done once it has stayed
      // done for a moment (see the pull-to-refresh test below).
      orders.setBaskets(const []);
      await tester.pump();
      expect(clock.workInHand, ShiftWorkInHand.basket);
      expect(clock.wantsScreen, isFalse);
      await tester.pump(shiftWorkSettleDelay);
      expect(clock.workInHand, ShiftWorkInHand.none);
      expect(clock.wantsScreen, isTrue);

      // The server saying it is waiting for work in hand counts too.
      next = openSession({'poll_seconds': 15, 'note': packerBusyNote});
      await clock.refresh();
      await tester.pump();
      expect(clock.workInHand, ShiftWorkInHand.order);
      expect(clock.wantsScreen, isFalse);

      clock.stop(owner: owner);
      await tester.pump(const Duration(seconds: 31));
    });

    testWidgets(
        'packer-1: pull to refresh never puts the blocking screen up over an order in hand',
        (tester) async {
      final home = _TestHome()
        ..isOnline = true
        ..latestOrder = [anOrder()];
      final orders = _TestOrders();
      final owner = Object();
      final clock = ShiftClockProvider(
          loadSession: () async => parse(openSession({'poll_seconds': 15})));

      await clock.start(home, owner: owner, order: orders);
      await tester.pump();
      expect(clock.workInHand, ShiftWorkInHand.order);
      expect(clock.wantsScreen, isFalse);

      // Pull to refresh: HomeProvider.initialize empties the assigned orders
      // and tells everyone, then asks the server for them again. The packer is
      // still holding that order all the while.
      home.clearLatestOrder();
      home.isLoading = true;
      await tester.pump();
      expect(clock.workInHand, ShiftWorkInHand.order,
          reason: 'an emptied list on its own is not a finished order');
      expect(clock.wantsScreen, isFalse);
      expect(clock.isScreenOpen, isFalse);
      expect(
          shiftStatusLine(clock.visibleSession!,
              now: received, work: clock.workInHand),
          'Shift over · finish this order');

      // A slow answer: the wait holds while the orders are still being asked for.
      await tester.pump(shiftWorkSettleDelay * 3);
      expect(clock.workInHand, ShiftWorkInHand.order);
      expect(clock.wantsScreen, isFalse);

      // The orders come back, the same one among them: nothing has changed.
      home.isLoading = false;
      home.setOrders([anOrder()]);
      await tester.pump(shiftWorkSettleDelay);
      expect(clock.workInHand, ShiftWorkInHand.order);
      expect(clock.wantsScreen, isFalse);

      // The order really is done: the screen follows once that has held.
      home.setOrders(<OrderNotification>[]);
      await tester.pump();
      expect(clock.wantsScreen, isFalse, reason: 'not believed yet');
      await tester.pump(shiftWorkSettleDelay);
      expect(clock.workInHand, ShiftWorkInHand.none);
      expect(clock.wantsScreen, isTrue);

      clock.stop(owner: owner);
      await tester.pump(const Duration(seconds: 31));
    });

    testWidgets(
        'packer-3: a basket left behind is not work in hand for the next packer',
        (tester) async {
      final orders = _TestOrders()
        ..setBaskets([Basket(identifier: 'B1', productIdentifiers: const [])]);
      final first = _TestHome()..isOnline = true;
      final firstOwner = Object();
      final clock = ShiftClockProvider(
          loadSession: () async => parse(openSession({'poll_seconds': 15})));

      await clock.start(first, owner: firstOwner, order: orders);
      await tester.pump();
      expect(clock.workInHand, ShiftWorkInHand.basket);
      expect(clock.wantsScreen, isFalse);

      // They log out with it still scanned. The order flow is app-scoped and
      // outlives the login, so the clock empties it as it stops.
      clock.stop(owner: firstOwner);
      await tester.pump();
      expect(orders.baskets, isEmpty);

      // The next packer signs in on the same phone: they have nothing in hand.
      final second = _TestHome()..isOnline = true;
      final secondOwner = Object();
      await clock.start(second, owner: secondOwner, order: orders);
      await tester.pump();
      expect(clock.workInHand, ShiftWorkInHand.none);
      expect(clock.wantsScreen, isTrue,
          reason: "someone else's basket must not hold the screen back");

      clock.stop(owner: secondOwner);
      await tester.pump(const Duration(seconds: 31));
    });

    testWidgets(
        'the request form states the pay for the extra hours and offers no choice',
        (tester) async {
      var session = openSession();
      final home = _TestHome();
      final owner = Object();
      final clock = ShiftClockProvider(loadSession: () async => parse(session));
      final router = _shiftScreenRouter();
      await tester.pumpWidget(_shiftScreenApp(home, clock, router));
      await clock.start(home, owner: owner);
      router.push('/${NavigationConstants.shiftCompleteScreenRoute}');
      await tester.pumpAndSettle();

      expect(find.text('Ask to keep working'), findsOneWidget);
      expect(find.text('Request extension'), findsOneWidget);
      expect(find.text('Extra hours will be paid at overtime pay.'),
          findsOneWidget);
      // Nobody picks their own rate any more.
      expect(find.text('Pay'), findsNothing);
      expect(find.text('Overtime pay'), findsNothing);
      expect(find.text('Normal pay'), findsNothing);
      // The hours are still theirs to choose.
      expect(find.widgetWithText(ChoiceChip, '2 h'), findsOneWidget);

      // Off the roster, or rostered where overtime isn't allowed: the form is
      // still offered, and the server says the hours are at normal pay.
      session = openSession({'extra_hours_pay': 'normal', 'roster': null});
      await clock.refresh();
      await tester.pumpAndSettle();
      expect(find.text("You're not on today's roster"), findsOneWidget);
      expect(find.text('Request extension'), findsOneWidget);
      expect(
          find.text('Extra hours will be paid at normal pay.'), findsOneWidget);
      expect(find.text('Normal pay'), findsNothing);

      // A backend that doesn't send it yet: the form works, and says nothing
      // about the pay rather than naming a rate.
      session = openSession({'extra_hours_pay': null});
      await clock.refresh();
      await tester.pumpAndSettle();
      expect(find.text('Request extension'), findsOneWidget);
      expect(find.textContaining('Extra hours will be paid'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      clock.stop(owner: owner);
      await tester.pump(const Duration(seconds: 31));
    });

    testWidgets(
        'packer-2: the shift complete screen offers the owed stock audit and comes back after it',
        (tester) async {
      final home = _TestHome()..packerSummary = summary('ongoing');
      final owner = Object();
      final clock = ShiftClockProvider(
          loadSession: () async => parse(openSession({'poll_seconds': 15})));
      final router = GoRouter(initialLocation: '/', routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('home')),
          routes: [
            GoRoute(
              path: NavigationConstants.shiftCompleteScreenRoute,
              builder: (_, __) => const ShiftCompleteScreen(),
            ),
            GoRoute(
              path: NavigationConstants.auditProductScreenRoute,
              builder: (_, __) => const Scaffold(body: Text('audit screen')),
            ),
          ],
        ),
      ]);
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<HomeProvider>.value(value: home),
          ChangeNotifierProvider<ShiftClockProvider>.value(value: clock),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, __) => MaterialApp.router(routerConfig: router),
        ),
      ));
      await clock.start(home, owner: owner);
      router.push('/${NavigationConstants.shiftCompleteScreenRoute}');
      await tester.pumpAndSettle();

      expect(find.text('Your shift is complete'), findsOneWidget);
      expect(
          find.text(
              "This shift's stock audit isn't finished. Finish it before you check out."),
          findsOneWidget);
      final continueAudit = find.text('Continue stock audit');
      expect(continueAudit, findsOneWidget);

      await tester.ensureVisible(continueAudit);
      await tester.pumpAndSettle();
      await tester.tap(continueAudit);
      await tester.pumpAndSettle();
      expect(find.text('audit screen'), findsOneWidget);

      // Back from the audit: the shift complete screen is still there.
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Your shift is complete'), findsOneWidget);
      expect(find.text('Check out and log out'), findsOneWidget);

      home.setSummary(summary('not_created'));
      await tester.pump();
      expect(find.text('Start stock audit'), findsOneWidget);

      home.setSummary(summary('completed'));
      await tester.pump();
      expect(find.text('Start stock audit'), findsNothing);
      expect(find.text('Continue stock audit'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      clock.stop(owner: owner);
      await tester.pump(const Duration(seconds: 31));
    });
  });

  group('ShiftClockProvider for a driver', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      DioClient.token = driverJwt();
    });

    Map<String, dynamic> driverOver([Map<String, dynamic> changes = const {}]) =>
        openSession({'role': 'driver', 'poll_seconds': 15, ...changes});

    testWidgets(
        'driver-1: counts down like a packer and asks about transfers only once the shift is over',
        (tester) async {
      var loads = 0;
      var transferLoads = 0;
      var next = liveSession(changes: {'role': 'driver'});
      final home = _TestHome()..isOnline = true;
      final owner = Object();
      final clock = ShiftClockProvider(
        loadSession: () async {
          loads++;
          return parseLive(next);
        },
        loadDriverTransfers: () async {
          transferLoads++;
          return 0;
        },
      );

      // The summary fetched at login already knows when this shift ends.
      home.setShift(liveSeed());
      await clock.start(home, owner: owner);
      await tester.pump();

      expect(clock.isDriver, isTrue);
      expect(clock.isRunning, isTrue);
      final session = clock.visibleSession;
      expect(session, isNotNull, reason: 'a driver gets the clock');
      expect(shiftStatusLine(session!), startsWith('Shift ends '));
      expect(clock.isPolling, isFalse, reason: 'the shift end is 2 h away');
      expect(clock.isWaitingForDeadline, isTrue);
      expect(transferLoads, 0, reason: 'nothing to decide before the shift end');

      // The shift ends: the app's own timer fires, reads the clock and then
      // the transfers that decide whether the screen may show.
      next = liveSession(endsIn: Duration.zero, changes: {
        'role': 'driver',
        'status': 'awaiting_extension',
        'shift_complete': true,
        'show_dialog': true,
        'can_take_work': false,
      });
      await tester.pump(const Duration(hours: 1));
      await tester.pump(const Duration(hours: 1));
      expect(loads, 1);
      await tester.pump(const Duration(seconds: 5));
      expect(loads, 2);
      expect(transferLoads, 1);
      expect(clock.workInHand, ShiftWorkInHand.none);
      expect(clock.wantsScreen, isTrue);
      expect(clock.isPolling, isTrue,
          reason: 'now waiting on support or a check-out');

      clock.stop(owner: owner);
      expect(clock.isScheduled, isFalse);
      await tester.pump(const Duration(seconds: 31));
    });

    testWidgets(
        'driver-2: a transfer in hand keeps the screen away; it comes within a poll of the delivery',
        (tester) async {
      var transfers = 1;
      var transferLoads = 0;
      var next = driverOver();
      final home = _TestHome()..isOnline = true;
      final owner = Object();
      final clock = ShiftClockProvider(
        loadSession: () async => parse(next),
        loadDriverTransfers: () async {
          transferLoads++;
          return transfers;
        },
      );

      await clock.start(home, owner: owner);
      await tester.pump();
      expect(transferLoads, 1);
      expect(clock.workInHand, ShiftWorkInHand.transfer);
      expect(clock.wantsScreen, isFalse, reason: 'a transfer is still in hand');
      clock.openScreen();
      expect(clock.wantsScreen, isFalse);

      // The home card says so, in a driver's words, and opens nothing.
      await tester.pumpWidget(ChangeNotifierProvider<ShiftClockProvider>.value(
        value: clock,
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, __) =>
              const MaterialApp(home: Scaffold(body: ShiftStatusCard())),
        ),
      ));
      expect(find.text('Shift over · deliver this transfer'), findsOneWidget);
      expect(
          find.text(
              'Once the store receives it, ask for more time or check out'),
          findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios), findsNothing);

      // Received at the destination store. Nothing tells the driver's phone;
      // the clock polls while the shift is over and the next poll reads the
      // transfers again.
      expect(clock.isPolling, isTrue);
      transfers = 0;
      await tester.pump(const Duration(seconds: 16));
      expect(transferLoads, 2);
      expect(clock.workInHand, ShiftWorkInHand.none);
      expect(clock.wantsScreen, isTrue);
      expect(find.text('Shift over'), findsOneWidget);
      expect(find.text('Tap to ask for more time or check out'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);

      // The server saying it is waiting for the transfer holds it too.
      next = driverOver({'note': driverBusyNote});
      await clock.refresh();
      await tester.pump();
      expect(clock.workInHand, ShiftWorkInHand.transfer);
      expect(clock.wantsScreen, isFalse);

      await tester.pumpWidget(const SizedBox());
      clock.stop(owner: owner);
      await tester.pump(const Duration(seconds: 31));
    });

    testWidgets(
        'driver-3: transfers that could not be read hold the screen back; the home card asks again',
        (tester) async {
      var reachable = false;
      var transferLoads = 0;
      final home = _TestHome()..isOnline = true;
      final owner = Object();
      final clock = ShiftClockProvider(
        loadSession: () async => parse(driverOver()),
        loadDriverTransfers: () async {
          transferLoads++;
          if (!reachable) throw const SocketException('no network');
          return 0;
        },
      );

      await clock.start(home, owner: owner);
      await tester.pump();
      expect(transferLoads, 1);
      expect(clock.visibleSession, isNotNull);
      expect(clock.wantsScreen, isFalse,
          reason: 'a transfer may be in hand for all the app knows');
      expect(clock.workInHand, ShiftWorkInHand.none);
      expect(
          shiftStatusLine(clock.visibleSession!,
              now: received, work: clock.workInHand),
          'Shift over');

      // A tap on the home card makes the clock look again.
      reachable = true;
      clock.openScreen();
      await tester.pump();
      expect(transferLoads, 2);
      expect(clock.wantsScreen, isTrue);

      clock.stop(owner: owner);
      await tester.pump(const Duration(seconds: 31));
    });

    testWidgets(
        'driver-4: with driver enforcement off nothing shows and nothing asks about transfers',
        (tester) async {
      var transferLoads = 0;
      final home = _TestHome()..isOnline = true;
      final owner = Object();
      final clock = ShiftClockProvider(
        loadSession: () async => parse(driverOver({
              'enforced': false,
              'show_dialog': false,
              'can_take_work': true,
            })),
        loadDriverTransfers: () async {
          transferLoads++;
          return 1;
        },
      );

      await clock.start(home, owner: owner);
      await tester.pump();
      expect(clock.isRunning, isTrue);
      expect(clock.visibleSession, isNull);
      expect(clock.wantsScreen, isFalse);
      expect(clock.isScheduled, isFalse);
      expect(transferLoads, 0);

      clock.stop(owner: owner);
    });

    testWidgets("driver-5: a driver's clock never reads the packer order flow",
        (tester) async {
      final orders = _TestOrders()
        ..setBaskets([Basket(identifier: 'B1', productIdentifiers: const [])]);
      final home = _TestHome()
        ..isOnline = true
        ..latestOrder = [anOrder()];
      final owner = Object();
      final clock = ShiftClockProvider(
        loadSession: () async => parse(driverOver()),
        loadDriverTransfers: () async => 0,
      );

      await clock.start(home, owner: owner, order: orders);
      await tester.pump();
      expect(clock.workInHand, ShiftWorkInHand.none,
          reason: "orders and baskets are a packer's, never a driver's");
      expect(clock.wantsScreen, isTrue);

      // Nor does it empty it on the way out: it never took it on.
      clock.stop(owner: owner);
      await tester.pump();
      expect(orders.baskets, hasLength(1));
      await tester.pump(const Duration(seconds: 31));
    });

    testWidgets('driver-5: roles other than packer and driver still get no clock',
        (tester) async {
      DioClient.token = managerJwt();
      var loads = 0;
      final clock = ShiftClockProvider(loadSession: () async {
        loads++;
        return parse(openSession({'role': 'manager'}));
      });

      await clock.start(_TestHome(), owner: Object());
      expect(clock.isRunning, isFalse);
      expect(clock.visibleSession, isNull);
      expect(loads, 0);
    });

    testWidgets(
        'driver-6: the shift complete screen offers a driver no stock audit and checks them out without a QR',
        (tester) async {
      // The flag a packer's QR check-out goes by: a driver never sets it, and
      // even with it set a driver is not sent to the scanner.
      FlutterSecureStorage.setMockInitialValues(
          {SecureStorageConstants.isOnlineKey: 'true'});
      const refusal = 'A transfer loaded for you has not been received yet. '
          'Deliver it before logging out.';
      final home = _TestHome()
        // A driver on a dark store's books still gets its audit status.
        ..packerSummary = summary('ongoing')
        ..driverCheckoutError = AppException(
          statusCode: 400,
          message: refusal,
          json: {'success': false, 'message': refusal},
        );
      final owner = Object();
      var transfers = 0;
      final clock = ShiftClockProvider(
        loadSession: () async => parse(driverOver()),
        loadDriverTransfers: () async => transfers,
      );
      final router = GoRouter(initialLocation: '/', routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('home')),
          routes: [
            GoRoute(
              path: NavigationConstants.shiftCompleteScreenRoute,
              builder: (_, __) => const ShiftCompleteScreen(),
            ),
            GoRoute(
              path: NavigationConstants.packerCheckoutScanRoute,
              builder: (_, __) => const Scaffold(body: Text('qr scanner')),
            ),
          ],
        ),
      ]);
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<HomeProvider>.value(value: home),
          ChangeNotifierProvider<ShiftClockProvider>.value(value: clock),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, __) => MaterialApp.router(routerConfig: router),
        ),
      ));
      await clock.start(home, owner: owner);
      router.push('/${NavigationConstants.shiftCompleteScreenRoute}');
      await tester.pumpAndSettle();

      expect(find.text('Your shift is complete'), findsOneWidget);
      expect(find.text('Continue stock audit'), findsNothing);
      expect(find.text('Start stock audit'), findsNothing);
      expect(home.summaryFetches, 0,
          reason: "no audit status is fetched for a driver's screen");
      expect(find.text('Request extension'), findsOneWidget);

      // A transfer is packed for them after the clock last looked.
      transfers = 1;
      final checkOut = find.text('Check out and log out');
      await tester.ensureVisible(checkOut);
      await tester.pumpAndSettle();
      await tester.tap(checkOut);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(home.driverCheckouts, 1);
      expect(find.text('qr scanner'), findsNothing);
      // Refused over it: they hear why, and are neither taken offline nor
      // logged out.
      expect(find.text(refusal), findsOneWidget);
      expect(home.onlineUpdates, isEmpty);

      await tester.tap(find.text('Ok'));
      await tester.pumpAndSettle();
      expect(find.text('Your shift is complete'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      clock.stop(owner: owner);
      await tester.pump(const Duration(seconds: 31));
    });

    testWidgets(
        'driver-7: a check-out refused over anything but a transfer in hand still logs the driver out (p-2)',
        (tester) async {
      const noLog = 'No active login session found.';
      // Set at sign-in in the app; the logout this reaches sends it.
      DioClient.refreshToken = 'refresh';
      final home = _TestHome()
        // No answer at all first: nothing was refused, so they stay on the
        // screen and can try again.
        ..driverCheckoutError = AppException(message: ErrorHandler.errorMessage);
      final owner = Object();
      var transferLoads = 0;
      final clock = ShiftClockProvider(
        loadSession: () async => parse(driverOver()),
        loadDriverTransfers: () async {
          transferLoads++;
          return 0;
        },
      );
      final router = _shiftScreenRouter();
      await tester.pumpWidget(_shiftScreenApp(home, clock, router));
      await clock.start(home, owner: owner);
      router.push('/${NavigationConstants.shiftCompleteScreenRoute}');
      await tester.pumpAndSettle();
      expect(find.text('Your shift is complete'), findsOneWidget);
      expect(transferLoads, 1, reason: "the clock's own look");

      Future<void> checkOut() async {
        final button = find.text('Check out and log out');
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.tap(button);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();
      }

      await checkOut();
      expect(home.driverCheckouts, 1);
      expect(transferLoads, 1,
          reason: 'with no answer there is no refusal to tell apart');
      expect(find.text(ErrorHandler.errorMessage), findsOneWidget);
      expect(home.onlineUpdates, isEmpty);
      await tester.tap(find.text('Ok'));
      await tester.pumpAndSettle();
      expect(find.text('Your shift is complete'), findsOneWidget);

      // Their plain logout earlier in the shift closed the online log, and
      // past their hours they cannot go online to open another: the server
      // finds nothing to check out. With no transfer in hand that is no
      // reason to keep them on a screen Back does not leave.
      home.driverCheckoutError = AppException(
        statusCode: 400,
        message: noLog,
        json: {'success': false, 'message': noLog},
      );
      await checkOut();
      expect(home.driverCheckouts, 2);
      expect(transferLoads, 2, reason: 'looked before letting them go');
      expect(find.text(noLog), findsNothing);
      expect(home.onlineUpdates, [false],
          reason: 'taken offline, and on to the logout');

      await tester.pumpWidget(const SizedBox());
      clock.stop(owner: owner);
      await tester.pump(const Duration(seconds: 31));
    });

    testWidgets(
        'driver-8: one failed look at the transfers leaves an open shift complete screen alone (p-3)',
        (tester) async {
      // What the transfer lists give: a count, or an error to throw.
      Object transfers = 0;
      var transferLoads = 0;
      final home = _TestHome()..isOnline = true;
      final owner = Object();
      final clock = ShiftClockProvider(
        loadSession: () async => parse(driverOver()),
        loadDriverTransfers: () async {
          transferLoads++;
          final answer = transfers;
          if (answer is int) return answer;
          throw answer;
        },
      );
      final router = _shiftScreenRouter();
      await tester.pumpWidget(_shiftScreenApp(home, clock, router));
      await clock.start(home, owner: owner);
      router.push('/${NavigationConstants.shiftCompleteScreenRoute}');
      await tester.pumpAndSettle();
      expect(clock.isScreenOpen, isTrue);
      expect(clock.isPolling, isTrue);

      const reason = 'Two more stores to cover';
      await tester.enterText(find.byType(TextField), reason);
      await tester.pump();

      // A network blip on the next poll, on the transfer lists alone.
      transfers = const SocketException('no network');
      var before = transferLoads;
      await tester.pump(const Duration(seconds: 16));
      await tester.pumpAndSettle();
      expect(transferLoads, before + 1);
      expect(clock.wantsScreen, isTrue);
      expect(find.text('Your shift is complete'), findsOneWidget);
      expect(find.text(reason), findsOneWidget, reason: 'nothing typed is lost');
      expect(find.text('home'), findsNothing);

      // A good look that finds a transfer still takes it down.
      transfers = 1;
      before = transferLoads;
      await tester.pump(const Duration(seconds: 16));
      await tester.pumpAndSettle();
      expect(transferLoads, before + 1);
      expect(clock.workInHand, ShiftWorkInHand.transfer);
      expect(find.text('Your shift is complete'), findsNothing);
      expect(find.text('home'), findsOneWidget);

      // With the screen down, not knowing keeps it down.
      transfers = const SocketException('no network');
      await tester.pump(const Duration(seconds: 16));
      await tester.pumpAndSettle();
      expect(clock.wantsScreen, isFalse);
      expect(find.text('Your shift is complete'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      clock.stop(owner: owner);
      await tester.pump(const Duration(seconds: 31));
    });

    testWidgets(
        'driver-9: a hidden status card takes no room on the driver home (p-4)',
        (tester) async {
      // Driver enforcement off, as it ships.
      var next = parse(driverOver({
        'enforced': false,
        'show_dialog': false,
        'can_take_work': true,
      }));
      final home = _TestHome();
      final owner = Object();
      final clock = ShiftClockProvider(
        loadSession: () async => next,
        loadDriverTransfers: () async => 0,
      );
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<HomeProvider>.value(value: home),
          ChangeNotifierProvider<ShiftClockProvider>.value(value: clock),
          ChangeNotifierProvider<DriverController>.value(value: _TestDrivers()),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, __) => const MaterialApp(home: DriverHomeScreen()),
        ),
      ));
      await clock.start(home, owner: owner);
      await tester.pump();

      double appBarBottom() => tester.getBottomLeft(find.byType(AppBar)).dy;
      double contentTop() =>
          tester.getTopLeft(find.byType(RefreshIndicator).first).dy;

      expect(clock.visibleSession, isNull);
      expect(find.text('You are offline'), findsOneWidget);
      expect(contentTop(), appBarBottom(),
          reason: 'nothing between the app bar and the transfers');

      // Enforcement on: the card shows, with its room around it.
      next = parseLive(liveSession(changes: {'role': 'driver'}));
      await clock.refresh();
      await tester.pump();
      final line = find.textContaining('Shift ends ');
      expect(line, findsOneWidget);
      expect(tester.getTopLeft(line).dy, greaterThan(appBarBottom()));
      expect(contentTop(), greaterThan(tester.getBottomLeft(line).dy));

      await tester.pumpWidget(const SizedBox());
      clock.stop(owner: owner);
      await tester.pump();
    });
  });

  group('logout', () {
    const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
    late Directory appDocDir;

    void answerWith(Future<dynamic> Function(MethodCall call) handler) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProvider, handler);
    }

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      appDocDir = await Directory.systemTemp.createTemp('packer_hive');
      answerWith((_) async => appDocDir.path);
      await HiveDBService.initHive();
    });

    tearDownAll(() async {
      await Hive.close();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProvider, null);
      await appDocDir.delete(recursive: true);
    });

    setUp(() {
      FlutterSecureStorage.setMockInitialValues(
          {SecureStorageConstants.accessTokenKey: 'token'});
      DioClient.token = packerJwt();
    });

    test('leaves no saved basket behind, and nothing else of anyone\'s',
        () async {
      // A packer part-way through two orders and a return: until those are
      // posted the tags they scanned are on this phone and nowhere else, and
      // the return is restored into the same scanned list the order is.
      const first = '${HiveConstants.order}4321';
      const second = '${HiveConstants.order}99';
      const aReturn = '${HiveConstants.orderReturn}4321';
      for (final order in [first, second, aReturn]) {
        await BasketDao(await Hive.openBox<Basket>(order)).addOrUpdateBasket(
            Basket(identifier: 'B1', productIdentifiers: ['77-1']));
      }

      // A box that is not a basket: stock counted against the store.
      final audit = Hive.box(HiveConstants.auditScanBox);
      await audit.put('rack-3', 'counted');

      await AuthController().removeTokens();

      for (final order in [first, second, aReturn]) {
        expect(await Hive.boxExists(order), isFalse,
            reason: 'the next packer on this phone inherits nothing');
        expect(Hive.isBoxOpen(order), isFalse);
      }
      expect(audit.get('rack-3'), 'counted',
          reason: 'the owed stock audit is not a basket');
    });

    test('a session expiring takes the tokens with the baskets', () async {
      // DioClient's 401 branch puts the packer back on the login screen
      // without a logout call of any kind. It ends the session through
      // removeTokens, the same as every other way out: the tokens it was
      // refused with are dead, so they do not sit on the phone afterwards.
      // (The call site itself needs a live interceptor, so it is read, not run.)
      const order = '${HiveConstants.order}77';
      await BasketDao(await Hive.openBox<Basket>(order)).addOrUpdateBasket(
          Basket(identifier: 'B2', productIdentifiers: ['77-2']));

      await AuthController().removeTokens();

      expect(await Hive.boxExists(order), isFalse);
      expect(DioClient.token, isEmpty,
          reason: 'a refused token is not kept');
      expect(DioClient.refreshToken, isEmpty);
      expect(
          await SecureStorageHelper()
              .readKey(key: SecureStorageConstants.accessTokenKey),
          isNull);
      expect(
          await SecureStorageHelper()
              .readKey(key: SecureStorageConstants.refreshTokenKey),
          isNull);
    });

    test('goes through even when the baskets cannot be cleared', () async {
      // Nothing can be read off disk: the clear cannot even start. A logout
      // that threw here would leave the packer signed out of the server with
      // the app still on their screen.
      answerWith((_) async => throw PlatformException(code: 'unavailable'));
      addTearDown(() => answerWith((_) async => appDocDir.path));

      await expectLater(AuthController().removeTokens(), completes);

      expect(DioClient.token, isEmpty);
      expect(
          await SecureStorageHelper()
              .readKey(key: SecureStorageConstants.accessTokenKey),
          isNull);
    });
  });

  group('sign-in refused outside the shift (login gate)', () {
    final early = ShiftRefusal.fromResponse(
        403,
        refusalBody(ShiftRefusalCode.shiftNotStarted, notStartedMessage,
            dayShift()))!;
    final over = ShiftRefusal.fromResponse(
        403, refusalBody(ShiftRefusalCode.shiftOver, overMessage, dayShift()))!;
    final stranger = ShiftRefusal.fromResponse(
        403, refusalBody(ShiftRefusalCode.notRostered, notRosteredMessage))!;
    // A token the clock signed out: the server names no shift then.
    final checkedOut = ShiftRefusal.fromResponse(
        403, refusalBody(ShiftRefusalCode.shiftOver, clockSignedOutMessage))!;

    test("reads the gate's 403 for each of its three codes", () {
      expect(early.code, 'shift_not_started');
      expect(early.message, notStartedMessage);
      expect(early.startsAt, at('2026-09-15T06:00:00+05:45'));
      expect(early.endsAt, at('2026-09-15T18:00:00+05:45'));
      expect(early.shiftName, 'Day');

      expect(over.code, 'shift_over');
      expect(over.message, overMessage);
      expect(over.startsAt, isNotNull);

      expect(stranger.code, 'not_rostered');
      expect(stranger.message, notRosteredMessage);
      expect(stranger.startsAt, isNull);
      expect(stranger.endsAt, isNull);
      expect(stranger.shiftName, isEmpty);

      expect(checkedOut.code, 'shift_over');
      expect(checkedOut.startsAt, isNull);
    });

    test('nothing else is a refusal, so nothing else changes', () {
      // Going online answers this first once the shift is complete.
      expect(
          ShiftRefusal.fromResponse(409, {
            'success': false,
            'error': 'shift_complete',
            'message': 'Your shift is complete.',
          }),
          isNull);
      // A 403 of another kind: an endpoint that does not serve this role, an
      // account the server has turned off, a carton claimed elsewhere.
      expect(
          ShiftRefusal.fromResponse(403, {
            'success': false,
            'message': 'Only packers can access cleanliness tasks.',
          }),
          isNull);
      expect(
          ShiftRefusal.fromResponse(403, {
            'message': 'You have been blacklisted and cannot access the system.',
            'type': '',
          }),
          isNull);
      expect(
          ShiftRefusal.fromResponse(
              403, {'detail': 'This carton was claimed from another phone.'}),
          isNull);
      expect(ShiftRefusal.fromResponse(403, {'error': 'shift_complete'}),
          isNull);
      // Not JSON at all: a proxy's page.
      expect(ShiftRefusal.fromResponse(403, '<html>Forbidden</html>'), isNull);
      expect(ShiftRefusal.fromResponse(403, null), isNull);
      // The gate never answers 401: the app refreshes and retries those.
      expect(
          ShiftRefusal.fromResponse(
              401, refusalBody(ShiftRefusalCode.shiftOver, overMessage)),
          isNull);
    });

    test('a shift block it cannot read leaves the refusal without a shift', () {
      final named = ShiftRefusal.fromResponse(403, {
        ...refusalBody(ShiftRefusalCode.shiftNotStarted, notStartedMessage),
        'shift': 'Day',
      })!;
      expect(named.startsAt, isNull);
      expect(shiftRefusalShiftLine(named), isNull);

      final garbled = ShiftRefusal.fromResponse(
          403,
          refusalBody(ShiftRefusalCode.shiftNotStarted, notStartedMessage,
              {'starts_at': 'soon', 'ends_at': null, 'name': null}))!;
      expect(garbled.startsAt, isNull);
      expect(garbled.shiftName, isEmpty);
      expect(shiftRefusalMessage(garbled), notStartedMessage);
    });

    test("shows the server's sentence as it is, with a heading for each code",
        () {
      expect(shiftRefusalTitle(early), "Your shift hasn't started yet");
      expect(shiftRefusalMessage(early), notStartedMessage);
      expect(shiftRefusalTitle(over), 'Your shift is over');
      expect(shiftRefusalMessage(over), overMessage);
      expect(shiftRefusalTitle(checkedOut), 'Your shift is over');
      expect(shiftRefusalMessage(checkedOut), clockSignedOutMessage);
      // not_rostered: the sentence says why and who can put it right, so the
      // heading does not say it again.
      expect(shiftRefusalTitle(stranger), "You can't sign in right now");
      expect(shiftRefusalMessage(stranger), notRosteredMessage);
    });

    test('says something for each code should the sentence ever be missing',
        () {
      for (final code in ShiftRefusalCode.all) {
        final bare = ShiftRefusal.fromResponse(
            403, {'success': false, 'error': code, 'shift': null})!;
        expect(bare.message, isEmpty);
        expect(shiftRefusalMessage(bare), isNotEmpty, reason: code);
      }
    });

    test('the same words for a driver as for a packer', () {
      // Both sign in on this screen; the server's sentences name no role,
      // and nothing the app adds may either.
      final now = DateTime.utc(2026, 9, 14, 23, 0);
      for (final refusal in [early, over, stranger, checkedOut]) {
        final words = [
          shiftRefusalTitle(refusal),
          shiftRefusalMessage(refusal),
          shiftRefusalShiftLine(refusal, now: now) ?? '',
        ].join(' ').toLowerCase();
        expect(words, isNot(contains('packer')), reason: refusal.code);
        expect(words, isNot(contains('order')), reason: refusal.code);
        expect(words, isNot(contains('basket')), reason: refusal.code);
      }
    });

    test('names the shift with its start and end in 12-hour time', () {
      // 4:45 AM on the 15th in Kathmandu.
      final dawn = DateTime.utc(2026, 9, 14, 23, 0);
      expect(shiftRefusalShiftLine(early, now: dawn),
          'Day shift · 6:00 AM – 6:00 PM');
      expect(shiftRefusalShiftLine(over, now: DateTime.utc(2026, 9, 15, 13, 15)),
          'Day shift · 6:00 AM – 6:00 PM');

      // Turned away at 11 PM: the shift is tomorrow's.
      expect(
          shiftRefusalShiftLine(early, now: DateTime.utc(2026, 9, 14, 17, 15)),
          'Day shift tomorrow · 6:00 AM – 6:00 PM');
      // A night shift that ended this morning.
      final night = ShiftRefusal.fromResponse(
          403,
          refusalBody(ShiftRefusalCode.shiftOver, overMessage, {
            'starts_at': '2026-09-14T22:00:00+05:45',
            'ends_at': '2026-09-15T06:00:00+05:45',
            'name': 'Night',
          }))!;
      expect(shiftRefusalShiftLine(night, now: DateTime.utc(2026, 9, 15, 1, 45)),
          'Night shift yesterday · 10:00 PM – 6:00 AM');
      // Further off.
      expect(shiftRefusalShiftLine(early, now: DateTime.utc(2026, 9, 12, 6, 15)),
          'Day shift, 15 Sep · 6:00 AM – 6:00 PM');
      // Refused on a phone set to another time zone: the shift's own offset.
      expect(
          shiftRefusalShiftLine(early, now: DateTime.utc(2026, 9, 15, 3, 0)),
          'Day shift · 6:00 AM – 6:00 PM');

      ShiftRefusal named(Map<String, dynamic> shift) => ShiftRefusal.fromResponse(
          403,
          refusalBody(
              ShiftRefusalCode.shiftNotStarted, notStartedMessage, shift))!;
      expect(
          shiftRefusalShiftLine(
              named({
                'starts_at': '2026-09-15T07:30:00+05:45',
                'ends_at': '2026-09-15T15:30:00+05:45',
                'name': 'Morning Shift',
              }),
              now: dawn),
          'Morning Shift · 7:30 AM – 3:30 PM');
      expect(
          shiftRefusalShiftLine(
              named({
                'starts_at': '2026-09-15T06:00:00+05:45',
                'ends_at': '2026-09-15T12:00:00+05:45',
                'name': '',
              }),
              now: dawn),
          'Your shift · 6:00 AM – 12:00 PM');
      expect(
          shiftRefusalShiftLine(
              named({'starts_at': '2026-09-15T06:00:00+05:45', 'name': 'Day'}),
              now: dawn),
          'Day shift · from 6:00 AM');

      expect(shiftRefusalShiftLine(stranger, now: dawn), isNull);
      expect(shiftRefusalShiftLine(checkedOut, now: dawn), isNull);
    });

    test('the refusal card writes 6:00 AM; the clock elsewhere keeps 6 AM', () {
      expect(formatShiftClock(at('2026-09-15T18:00:00+05:45'), withMinutes: true),
          '6:00 PM');
      expect(formatShiftClock(at('2026-09-15T00:00:00+05:45'), withMinutes: true),
          '12:00 AM');
      expect(formatShiftClock(at('2026-09-15T18:30:00+05:45'), withMinutes: true),
          '6:30 PM');
      expect(formatShiftClock(at('2026-09-15T18:00:00+05:45')), '6 PM');
    });
  });

  group('the login screen after a shift refusal', () {
    const toastChannel = MethodChannel('PonnamKarthik/fluttertoast');
    const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
    final toasts = <String>[];
    late _FakeServer server;

    void answerChannel(
        MethodChannel channel, Future<dynamic> Function(MethodCall)? handler) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, handler);
    }

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      DioClient.token = '';
      DioClient.refreshToken = '';
      signInRefusal.value = null;
      toasts.clear();
      server = _FakeServer();
      DioClient().httpClientAdapter = server;
      answerChannel(toastChannel, (call) async {
        if (call.method == 'showToast') {
          toasts.add((call.arguments as Map)['msg'].toString());
        }
        return true;
      });
      // No saved baskets to clear: removeTokens logs that and goes on.
      answerChannel(pathProvider,
          (_) async => throw PlatformException(code: 'unavailable'));
    });

    tearDown(() {
      signInRefusal.value = null;
      DioClient.token = '';
      DioClient.refreshToken = '';
      answerChannel(toastChannel, null);
      answerChannel(pathProvider, null);
    });

    /// Signed in, as the app is while someone works.
    void signedInAs(String jwt) {
      FlutterSecureStorage.setMockInitialValues({
        SecureStorageConstants.accessTokenKey: jwt,
        SecureStorageConstants.refreshTokenKey: 'refresh-1',
      });
      DioClient.token = jwt;
      DioClient.refreshToken = 'refresh-1';
    }

    Future<Object?> requestSummary(WidgetTester tester) => _request(
        tester, RequestType.getWithToken, AppUrls.packerSummaryUrl);

    testWidgets(
        'a sign-in refused before the shift keeps the reason on the login screen, not in a toast',
        (tester) async {
      server.answer(
          AppUrls.loginUrl,
          403,
          refusalBody(ShiftRefusalCode.shiftNotStarted, notStartedMessage,
              dayShift(kathmanduToday())));
      await tester.pumpWidget(_loginApp(_loginRouter()));
      await tester.pumpAndSettle();
      final login = tester.state(find.byType(LoginScreen));

      await _signIn(tester, 'packer1', 'secret');

      expect(find.text("Your shift hasn't started yet"), findsOneWidget);
      expect(find.text(notStartedMessage), findsOneWidget);
      expect(find.text('Day shift · 6:00 AM – 6:00 PM'), findsOneWidget);
      expect(toasts, isEmpty, reason: 'the card says it, and keeps saying it');
      // The same login screen, as they typed it, with the loader gone.
      expect(tester.state(find.byType(LoginScreen)), same(login));
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('packer1'), findsOneWidget);
      expect(DioClient.token, isEmpty);
      expect(server.calls, ['POST /auth/api/token/']);

      // Nothing takes it down but another try.
      await tester.pump(const Duration(minutes: 5));
      expect(find.text(notStartedMessage), findsOneWidget);

      // Someone else, with a wrong password: the card was not about them.
      server.answer(
          AppUrls.loginUrl, 401, {'error': 'Invalid username or password.'});
      await _signIn(tester, 'driver2', 'wrong');
      expect(find.text(notStartedMessage), findsNothing);
      expect(find.text("Your shift hasn't started yet"), findsNothing);
      expect(toasts, ['Invalid username or password.']);
    });

    testWidgets('a sign-in refused off the roster says so with no shift to name',
        (tester) async {
      server.answer(AppUrls.loginUrl, 403,
          refusalBody(ShiftRefusalCode.notRostered, notRosteredMessage));
      await tester.pumpWidget(_loginApp(_loginRouter()));
      await tester.pumpAndSettle();

      await _signIn(tester, 'packer1', 'secret');

      expect(find.text("You can't sign in right now"), findsOneWidget);
      expect(find.text(notRosteredMessage), findsOneWidget);
      expect(find.textContaining(' shift · '), findsNothing);
      expect(toasts, isEmpty);
    });

    testWidgets(
        'a packer the clock checked out lands on the login screen with the reason',
        (tester) async {
      signedInAs(packerJwt());
      server.answer(AppUrls.packerSummaryUrl, 403,
          refusalBody(ShiftRefusalCode.shiftOver, clockSignedOutMessage));
      await tester.pumpWidget(_loginApp(_loginRouter(location: '/dashboard')));
      await tester.pumpAndSettle();
      expect(find.text('dashboard of packer'), findsOneWidget);

      final thrown = await requestSummary(tester);
      await tester.pumpAndSettle();

      expect(thrown, isA<LogoutException>());
      expect(thrown.toString(), clockSignedOutMessage);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Your shift is over'), findsOneWidget);
      expect(find.text(clockSignedOutMessage), findsOneWidget);
      expect(DioClient.token, isEmpty, reason: 'a refused token is not kept');
      expect(
          await SecureStorageHelper()
              .readKey(key: SecureStorageConstants.accessTokenKey),
          isNull);
    });

    testWidgets(
        'a driver the clock checked out reads the same, with no packer wording',
        (tester) async {
      signedInAs(driverJwt());
      server.answer(
          AppUrls.driverInTransitTransfersUrl,
          403,
          refusalBody(ShiftRefusalCode.shiftOver, overMessage,
              dayShift(kathmanduToday())));
      await tester.pumpWidget(_loginApp(_loginRouter(location: '/dashboard')));
      await tester.pumpAndSettle();
      expect(find.text('dashboard of driver'), findsOneWidget);

      final thrown = await _request(tester, RequestType.getWithToken,
          AppUrls.driverInTransitTransfersUrl);
      await tester.pumpAndSettle();

      expect(thrown, isA<LogoutException>());

      expect(find.text('Your shift is over'), findsOneWidget);
      expect(find.text(overMessage), findsOneWidget);
      expect(find.text('Day shift · 6:00 AM – 6:00 PM'), findsOneWidget);
      expect(find.textContaining(RegExp('packer', caseSensitive: false)),
          findsNothing);
    });

    testWidgets(
        'a refresh refused outside the shift lands on the login screen with the reason',
        (tester) async {
      // The access token ran out overnight; the refresh is a sign-in too.
      signedInAs(packerJwt());
      server.answer(AppUrls.packerSummaryUrl, 401, {
        'message': 'Given token not valid for any token type',
        'type': 'invalid_token',
      });
      server.answer(
          AppUrls.refreshTokenUrl,
          403,
          refusalBody(ShiftRefusalCode.shiftNotStarted, notStartedMessage,
              dayShift(kathmanduToday())));
      await tester.pumpWidget(_loginApp(_loginRouter(location: '/dashboard')));
      await tester.pumpAndSettle();

      final thrown = await requestSummary(tester);
      await tester.pumpAndSettle();

      expect(thrown, isNotNull);
      expect(server.calls,
          ['GET /staff/packer/summary/', 'POST /auth/verify-otp/refresh']);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text("Your shift hasn't started yet"), findsOneWidget);
      expect(find.text(notStartedMessage), findsOneWidget);
      expect(DioClient.token, isEmpty);
    });

    testWidgets(
        'any other 403 still signs out as it always has, with no shift reason on screen',
        (tester) async {
      // An account the server turned off: DRF answers its authentication
      // failures with a 403 here, and signing out is right for those.
      signedInAs(packerJwt());
      server.answer(AppUrls.packerSummaryUrl, 403, {
        'message': 'You have been blacklisted and cannot access the system.',
        'type': '',
      });
      await tester.pumpWidget(_loginApp(_loginRouter(location: '/dashboard')));
      await tester.pumpAndSettle();

      final thrown = await requestSummary(tester);
      await tester.pumpAndSettle();

      expect(thrown, isA<LogoutException>());
      expect(thrown.toString(),
          'You have been blacklisted and cannot access the system.');
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(DioClient.token, isEmpty);
      expect(signInRefusal.value, isNull);
      expect(find.byType(ShiftRefusalCard), findsOneWidget);
      expect(find.text('Your shift is over'), findsNothing);
      expect(find.text("You can't sign in right now"), findsNothing);
    });

    testWidgets(
        'the 409 going online answers first is no refusal: nobody is signed out',
        (tester) async {
      signedInAs(packerJwt());
      server.answer(AppUrls.packerOnlineStatus, 409, {
        'success': false,
        'error': 'shift_complete',
        'message': 'Your shift is complete.',
      });
      await tester.pumpWidget(_loginApp(_loginRouter(location: '/dashboard')));
      await tester.pumpAndSettle();

      final thrown = await _request(
          tester, RequestType.patchWithToken, AppUrls.packerOnlineStatus,
          body: {'is_online': true});
      await tester.pumpAndSettle();

      expect(isShiftCompleteError(thrown), isTrue);
      expect(DioClient.token, packerJwt());
      expect(signInRefusal.value, isNull);
      expect(find.text('dashboard of packer'), findsOneWidget);
    });

    testWidgets(
        'signing in drops the refusal and the person the clock signed out before',
        (tester) async {
      // A packer worked on this phone until the clock checked them out and
      // their next request was refused: no logout, so their user stayed.
      DioClient.token = packerJwt();
      final home = _TestHome();
      expect(home.user.role, UserRole.packer);
      DioClient.token = '';
      signInRefusal.value = ShiftRefusal.fromResponse(
          403, refusalBody(ShiftRefusalCode.shiftOver, clockSignedOutMessage));

      server.answer(
          AppUrls.loginUrl, 200, {'access': driverJwt(), 'refresh': 'refresh-2'});
      server.answer(AppUrls.fcmTokenUrl, 200, {'success': true});
      await tester.pumpWidget(_loginApp(_loginRouter(), home: home));
      await tester.pumpAndSettle();
      expect(find.text('Your shift is over'), findsOneWidget);

      await _signIn(tester, 'driver2', 'secret');
      await tester.pumpAndSettle();

      expect(signInRefusal.value, isNull);
      expect(find.text('dashboard of driver'), findsOneWidget,
          reason: 'the driver who signed in, not the packer before them');
      expect(home.user.name, 'Driver');
      expect(home.summaryFetches, 1);
      expect(toasts, isEmpty);
    });
  });
}

String packerJwt() =>
    _jwt({'user_id': 5, 'name': 'Packer', 'role': 'packer', 'store_id': 2});

/// A driver signs in on this app too, on the main store's books.
String driverJwt() =>
    _jwt({'user_id': 6, 'name': 'Driver', 'role': 'driver', 'store_id': 1});

String managerJwt() =>
    _jwt({'user_id': 8, 'name': 'Manager', 'role': 'manager', 'store_id': 2});

String _jwt(Map<String, dynamic> claims) {
  String encode(Map<String, dynamic> map) =>
      base64Url.encode(utf8.encode(jsonEncode(map))).replaceAll('=', '');
  return '${encode({'alg': 'HS256', 'typ': 'JWT'})}.${encode(claims)}.sig';
}

PackerSummary summary(String auditStatus) => PackerSummary.fromJson({
      'total_online_time': '0',
      'total_order_count': 0,
      'is_online': false,
      'store_type': 'dark',
      'scan_gap_time': 10,
      'store_id': 2,
      'audit_status': auditStatus,
    });

/// HomeProvider without the network.
class _TestHome extends HomeProvider {
  int summaryFetches = 0;

  @override
  Future<void> fetchpackerSummary() async {
    summaryFetches++;
  }

  /// What a driver's check-out is refused with; null lets it through.
  AppException? driverCheckoutError;
  int driverCheckouts = 0;

  @override
  Future<bool> driverCheckout() async {
    driverCheckouts++;
    final error = driverCheckoutError;
    if (error != null) throw error;
    return true;
  }

  /// Every online-status change the app asked the server for.
  final onlineUpdates = <bool>[];

  @override
  Future<bool> updatepackerStatus(bool status, BuildContext context,
      {bool showErrorDialog = true}) async {
    onlineUpdates.add(status);
    return true;
  }

  void setOnline(bool value) {
    isOnline = value;
    notifyListeners();
  }

  void setSummary(PackerSummary value) {
    packerSummary = value;
    notifyListeners();
  }

  /// A packer summary came back carrying a `shift` block.
  void setShift(ShiftSessionState value) {
    summaryShift = value;
    notifyListeners();
  }

  /// Orders assigned to this packer changed.
  void setOrders(List<OrderNotification> value) {
    latestOrder = value;
    notifyListeners();
  }
}

/// DriverController without the network: the driver home asks it for the
/// packed transfers as it opens.
class _TestDrivers extends DriverController {
  @override
  void fetchDriverTransfers(BuildContext context, {bool fromBuild = false}) {}
}

/// Home, with the shift complete screen and the check-out scanner above it.
GoRouter _shiftScreenRouter() => GoRouter(initialLocation: '/', routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('home')),
        routes: [
          GoRoute(
            path: NavigationConstants.shiftCompleteScreenRoute,
            builder: (_, __) => const ShiftCompleteScreen(),
          ),
          GoRoute(
            path: NavigationConstants.packerCheckoutScanRoute,
            builder: (_, __) => const Scaffold(body: Text('qr scanner')),
          ),
        ],
      ),
    ]);

Widget _shiftScreenApp(
        HomeProvider home, ShiftClockProvider clock, GoRouter router) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider<HomeProvider>.value(value: home),
        ChangeNotifierProvider<ShiftClockProvider>.value(value: clock),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => MaterialApp.router(routerConfig: router),
      ),
    );

/// OrderProvider without Hive: only the open baskets matter here.
class _TestOrders extends OrderProvider {
  /// Growable, as basketDao.getAll() gives it: resetState() clears it in place.
  void setBaskets(List<Basket> value) {
    baskets = List.of(value);
    notifyListeners();
  }
}

final _dashboards = <State>[];

/// NavigationScreen's shift clock wiring
/// (lib/features/views/navigation/navigation_page.dart).
class _FakeDashboard extends StatefulWidget {
  const _FakeDashboard();

  @override
  State<_FakeDashboard> createState() => _FakeDashboardState();
}

class _FakeDashboardState extends State<_FakeDashboard> {
  ShiftClockProvider? _shiftClock;

  @override
  void initState() {
    super.initState();
    _dashboards.add(this);
    final home = Provider.of<HomeProvider>(context, listen: false);
    final shiftClock = Provider.of<ShiftClockProvider>(context, listen: false);
    _shiftClock = shiftClock;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) shiftClock.start(home, owner: this);
    });
  }

  @override
  void dispose() {
    _shiftClock?.stop(owner: this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Text('dashboard'));
}

/// The server, for DioClient: answers by path, so its error branches run as
/// they do in the app. Anything unanswered is a 404.
class _FakeServer implements HttpClientAdapter {
  final _answers = <String, (int, Object?)>{};

  /// Every request made, as "METHOD /path".
  final calls = <String>[];

  /// What was sent with the last request to each path, as DioClient wrote it.
  final bodies = <String, Object?>{};

  void answer(String url, int status, Object? body) {
    _answers[Uri.parse(url).path] = (status, body);
  }

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final path = options.uri.path;
    calls.add('${options.method} $path');
    bodies[path] = options.data;
    final (status, body) = _answers[path] ?? (404, {'detail': 'Not found.'});
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// The app's login screen, and a dashboard that shows whose it is, behind a
/// router DioClient drives as it does the app's (AppRouter.router).
GoRouter _loginRouter({String location = '/login'}) =>
    AppRouter.router = GoRouter(initialLocation: location, routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('splash')),
        routes: [
          GoRoute(
            path: NavigationConstants.loginRoute,
            builder: (_, __) => const LoginScreen(),
          ),
          GoRoute(
            path: NavigationConstants.dashboardRoute,
            builder: (context, __) => Scaffold(
                body: Text('dashboard of '
                    '${Provider.of<HomeProvider>(context, listen: false).user.role.name}')),
          ),
        ],
      ),
    ]);

Widget _loginApp(GoRouter router, {HomeProvider? home}) =>
    ChangeNotifierProvider<HomeProvider>.value(
      value: home ?? _TestHome(),
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => MaterialApp.router(routerConfig: router),
      ),
    );

/// Fills the login form and taps Login, then lets the answer come in. Frames,
/// not settle: the loader spins until it does.
Future<void> _signIn(
    WidgetTester tester, String username, String password) async {
  await tester.enterText(find.byType(TextFormField).at(0), username);
  await tester.enterText(find.byType(TextFormField).at(1), password);
  final login = find.widgetWithText(GeneralElevatedButton, 'Login');
  await tester.ensureVisible(login);
  await tester.tap(login);
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// One DioClient request from a widget test, pumping frames while it runs:
/// it only finishes as the test's clock moves. Returns what it failed with,
/// or null when it went through.
Future<Object?> _request(WidgetTester tester, RequestType type, String url,
    {dynamic body}) async {
  Object? error;
  var done = false;
  DioClient().request(requestType: type, url: url, body: body).then<void>(
      (_) => done = true, onError: (Object e) {
    error = e;
    done = true;
  });
  for (var i = 0; i < 50 && !done; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(done, isTrue, reason: 'the request never finished');
  return error;
}
