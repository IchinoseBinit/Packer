import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/constants/secure_storage_constants.dart';
import 'package:packer/controllers/api/app_exception.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/secure_storage_helper.dart';
import 'package:packer/features/views/audit_product/models/audit_status_enum.dart';
import 'package:packer/features/views/auth/model/order_notification.dart';
import 'package:packer/features/views/auth/model/packer_summary.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/shift_clock/models/shift_session.dart';
import 'package:packer/features/views/shift_clock/providers/shift_clock_provider.dart';
import 'package:packer/features/views/shift_clock/screens/shift_complete_screen.dart';
import 'package:packer/features/views/shift_clock/utils/shift_clock_logic.dart';

ShiftTime at(String iso) => ShiftTime.tryParse(iso)!;

/// Phone clock when the fixture "arrived" (18:10 Kathmandu).
final received = DateTime.utc(2026, 9, 15, 12, 25);

Map<String, dynamic> openSession([Map<String, dynamic> changes = const {}]) => {
      'has_session': true,
      'enforced': true,
      'poll_seconds': 60,
      'server_time': '2026-09-15T18:10:00+05:45',
      'session_id': 7,
      'status': 'awaiting_extension',
      'role': 'packer',
      'started_at': '2026-09-15T06:00:00+05:45',
      'regular_hours': 12.0,
      'regular_limit_at': '2026-09-15T18:00:00+05:45',
      'hard_limit_at': '2026-09-15T19:00:00+05:45',
      'seconds_to_regular_limit': -600,
      'seconds_to_hard_limit': 3000,
      'shift_complete': true,
      'locked': false,
      'show_dialog': true,
      'can_take_work': false,
      'can_request': true,
      'note': '',
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
      expect(state.status, ShiftStatus.awaitingExtension);
      expect(state.regularHours, 12.0);
      expect(state.showDialog, isTrue);
      expect(state.canRequest, isFalse);
      expect(state.roster?.otAllowed, isTrue);
      expect(state.roster?.otPayType, ShiftPay.overtime);
      expect(state.roster?.otMaxHours, 2.0);
      expect(state.pendingRequest?.id, 31);
      expect(state.pendingRequest?.requestedUntil, at('2026-09-15T20:00:00+05:45'));
      expect(state.pendingRequest?.approvedPay, isNull);
      expect(state.lastDecision?.status, ShiftRequestStatus.rejected);
      expect(state.lastDecision?.reviewNote, 'Enough packers tonight');
      expect(isShiftClockVisible(state), isTrue);
    });

    test('missing keys, nulls and wrong types fall back to showing nothing', () {
      final empty = ShiftSessionState.fromJson(const {});
      expect(empty.hasSession, isFalse);
      expect(empty.enforced, isFalse);
      expect(empty.showDialog, isFalse);
      expect(empty.canTakeWork, isTrue);
      expect(empty.pollSeconds, ShiftSessionState.defaultPollSeconds);
      expect(empty.lastSession, isNull);

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
      expect(shiftStatusDetail(active), 'Started 6 AM');

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
      expect(shiftStatusDetail(extended), 'Approved at overtime pay');

      final over = parse(openSession());
      expect(shiftStatusLine(over, now: received), 'Shift over');
      expect(shiftStatusDetail(over), 'Tap to ask for more time or check out');
      expect(
          shiftStatusDetail(parse(openSession({'pending_request': request()}))),
          'Waiting for support to approve more time');
    });

    test('says what to finish first while work is in hand', () {
      final over = parse(openSession());
      expect(shiftStatusLine(over, now: received, work: ShiftWorkInHand.order),
          'Shift over · finish this order');
      expect(shiftStatusLine(over, now: received, work: ShiftWorkInHand.basket),
          'Shift over · finish this basket');
      expect(shiftStatusDetail(over, work: ShiftWorkInHand.order),
          'Finish it, then ask for more time or check out');
      // Support already has a request: that is the news, work or not.
      expect(
        shiftStatusDetail(parse(openSession({'pending_request': request()})),
            work: ShiftWorkInHand.order),
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
      expect(graceLine(state, received),
          "You'll be checked out at 7 PM unless support approves more time");
      final later = received.add(const Duration(seconds: 3001));
      expect(graceLine(state, later),
          "Your time is up. You'll be checked out soon unless support approves more time");
      expect(
        graceLine(parse(openSession({'pending_request': request()})), later),
        "Support is looking at your request. You won't be checked out until they decide",
      );
    });

    test('pending, rejected, ended and approved lines', () {
      final state = parse(openSession({'pending_request': request()}));
      expect(pendingRequestLine(state.pendingRequest!, state.serverTime),
          'Waiting for support to approve working until 8 PM at overtime pay');
      expect(rejectedRequestLine, "Support didn't approve your last request");
      expect(
        extensionEndedLine(parse(openSession({
          'last_decision': request({
            'status': 'approved',
            'approved_until': '2026-09-15T20:00:00+05:45',
          }),
        }))),
        'Your extension ended at 8 PM',
      );
      expect(extensionEndedLine(parse(openSession())), isNull);
      expect(extensionApprovedMessage(at('2026-09-15T20:00:00+05:45'), null),
          'Extension approved until 8 PM');
    });

    test('check-out notices', () {
      expect(checkoutNoticeMessage(ShiftEndReason.auto),
          "Your shift has ended and you've been checked out");
      expect(checkoutNoticeMessage(ShiftEndReason.forcedBySupport),
          'Support has checked you out');
    });

    test('form defaults come from the roster', () {
      final roster = parse(openSession()).roster;
      expect(defaultExtensionPay(roster), ShiftPay.overtime);
      expect(defaultExtensionHours(roster), 2);
      expect(defaultExtensionPay(null), ShiftPay.overtime);
      expect(defaultExtensionHours(null), 1);
      expect(
        defaultExtensionPay(const ShiftRoster(
            shift: 'Day', otAllowed: true, otPayType: 'normal', otMaxHours: 6)),
        ShiftPay.normal,
      );
      expect(
        defaultExtensionHours(const ShiftRoster(
            shift: 'Day', otAllowed: true, otPayType: 'normal', otMaxHours: 6)),
        1,
      );
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
      expect(clock.isPolling, isFalse);
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
}

String packerJwt() {
  String encode(Map<String, dynamic> map) =>
      base64Url.encode(utf8.encode(jsonEncode(map))).replaceAll('=', '');
  return '${encode({'alg': 'HS256', 'typ': 'JWT'})}.'
      '${encode({
        'user_id': 5,
        'name': 'Packer',
        'role': 'packer',
        'store_id': 2
      })}.sig';
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

  void setOnline(bool value) {
    isOnline = value;
    notifyListeners();
  }

  void setSummary(PackerSummary value) {
    packerSummary = value;
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
