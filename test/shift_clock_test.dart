import 'package:flutter_test/flutter_test.dart';
import 'package:packer/controllers/api/app_exception.dart';
import 'package:packer/features/views/shift_clock/models/shift_session.dart';
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
    test('active, extended and complete', () {
      final active = parse(openSession({
        'status': 'active',
        'shift_complete': false,
        'show_dialog': false,
        'server_time': '2026-09-15T13:00:00+05:45',
      }));
      expect(shiftStatusLine(active), 'Shift ends 6 PM');
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
      expect(shiftStatusLine(extended), 'Extension until 8 PM');
      expect(shiftStatusDetail(extended), 'Approved at overtime pay');

      final complete = parse(openSession());
      expect(shiftStatusLine(complete), 'Shift complete');
      expect(shiftStatusDetail(complete), 'Tap to ask for more time or check out');
      expect(
          shiftStatusDetail(parse(openSession({'pending_request': request()}))),
          'Waiting for support to approve more time');
    });

    test('hidden when not enforced, no session or not a packer session', () {
      expect(shiftStatusLine(parse(openSession({'enforced': false}))), isNull);
      expect(shiftStatusLine(parse(noSession(null))), isNull);
      expect(shiftStatusLine(parse(openSession({'role': 'rider'}))), isNull);
      expect(shiftStatusLine(parse(openSession({'role': null}))), 'Shift complete');
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

    test('snooze signature changes only when something to see changes', () {
      final base = parse(openSession());
      expect(shiftSnoozeSignature(base), shiftSnoozeSignature(parse(openSession())));
      expect(shiftSnoozeSignature(base),
          isNot(shiftSnoozeSignature(parse(openSession({'note': 'Waiting'})))));
      expect(
          shiftSnoozeSignature(base),
          isNot(shiftSnoozeSignature(parse(openSession({
            'last_decision': request({'status': 'rejected'}),
          })))));
      expect(
          shiftSnoozeSignature(base),
          isNot(shiftSnoozeSignature(parse(openSession({
            'hard_limit_at': '2026-09-15T21:00:00+05:45',
          })))));
    });
  });
}
