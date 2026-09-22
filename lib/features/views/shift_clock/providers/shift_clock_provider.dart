import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:packer/constants/app_constants.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/constants/secure_storage_constants.dart';
import 'package:packer/controllers/api/app_exception.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/router.dart';
import 'package:packer/controllers/services/secure_storage_helper.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/auth/model/user.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:packer/features/views/shift_clock/models/shift_session.dart';
import 'package:packer/features/views/shift_clock/repo/shift_clock_repo.dart';
import 'package:packer/features/views/shift_clock/utils/shift_clock_logic.dart';
import 'package:packer/features/views/shift_clock/utils/shift_clock_route_observer.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';

/// The packer's (and the driver's) shift clock.
///
/// Started by the dashboard for packers and drivers: a driver signs in on this
/// app and gets the same clock, with a transfer as their work in hand instead
/// of an order or a basket. It knows when the shift ends without
/// asking: the packer summary carries a `shift` block, the clock keeps it with
/// the phone time it arrived, corrects the phone clock against server_time and
/// runs its own countdown to the shift end and to the grace deadline. A local
/// timer fires at those moments and then asks GET /attendance/session/ once to
/// confirm. It also refreshes on start, on resume, after going online, after a
/// shift push, after sending or cancelling a request and on pull-to-refresh,
/// and keeps a repeating poll only while something is waiting on an answer
/// (see shouldPollShiftClock).
///
/// It opens the shift complete screen while the server says show_dialog - but
/// never while the packer has work in hand: they read "Shift over · finish
/// this order" on the home screen and get the screen once the work is done.
class ShiftClockProvider with ChangeNotifier, WidgetsBindingObserver {
  static const _noticePrefsKey = 'shift_clock_checkout_notice_';

  /// [loadSession] replaces GET /attendance/session/ and [loadDriverTransfers]
  /// the driver's two transfer lists in tests.
  ShiftClockProvider({
    Future<ShiftSessionState> Function()? loadSession,
    Future<int> Function()? loadDriverTransfers,
  })  : _loadSession = loadSession ?? ShiftClockRepo.getSession,
        _loadDriverTransfers =
            loadDriverTransfers ?? ShiftClockRepo.driverTransfersInHand;

  final Future<ShiftSessionState> Function() _loadSession;
  final Future<int> Function() _loadDriverTransfers;

  /// How many transfers the driver held when the clock last asked, together
  /// with the session that says their shift is over. Null while that isn't
  /// known: not asked yet in this stretch of overtime, or the last ask failed
  /// with no screen up (see [_checkTransfers]). Only ever set for a driver.
  int? _transfersInHand;

  /// The session [_transfersInHand] was read for.
  int? _transfersSessionId;

  ShiftSessionState? state;
  bool isSubmitting = false;
  bool isCancelling = false;
  String? requestError;

  HomeProvider? _home;
  OrderProvider? _order;

  /// The dashboards that started the clock and are still alive. The app can
  /// hold more than one (an order call pushes a second dashboard), so the
  /// clock stops only when the last one goes away.
  final Set<Object> _owners = Set.identity();
  bool _started = false;
  bool _disposed = false;
  int _epoch = 0;
  bool _inForeground = true;
  bool _lastOnline = false;
  bool _lastRefreshOk = false;

  /// The work in hand the app believes, which is what the packer is shown.
  ShiftWorkInHand _lastWork = ShiftWorkInHand.none;

  /// Work that has just gone from the order flow and is not believed gone yet
  /// (see [workInHand]); null when nothing is settling.
  ShiftWorkInHand? _clearingWork;
  Timer? _workSettleTimer;

  /// Extra rounds the settle waits while the home screen is still asking for
  /// this packer's orders, so a slow answer never reads as "no work".
  static const _maxWorkSettleRounds = 4;
  int _workSettleRound = 0;

  /// The summary seed already taken; a fetch always makes a new object.
  ShiftSessionState? _lastSeed;

  /// Repeating poll, only while something is waiting on an answer.
  Timer? _pollTimer;

  /// One-shot wake-up at the shift end or the grace deadline.
  Timer? _deadlineTimer;
  Future<void>? _inFlight;
  bool _refreshAgain = false;

  VoidCallback? _closeScreen;
  bool _openingScreen = false;

  /// The approval this packer has already read and gone back to work from.
  ///
  /// Kept per person on the device, because the page has to survive the app
  /// being killed: the push that tells them support said yes is tapped from
  /// the tray, and it has to land on the page that says until when. Read once
  /// at start and written when they press Back to work.
  int? _approvalRead;
  bool _approvalReadLoaded = false;

  UserRole? get _role {
    try {
      return _home?.user.role;
    } catch (_) {
      return null;
    }
  }

  bool get isPacker => _role == UserRole.packer;

  /// A driver: the clock runs for them too, but nothing packer-only (the
  /// order flow's baskets, the stock audit) is theirs.
  bool get isDriver => _role == UserRole.driver;

  /// The roles this app runs the clock for; everyone else sees nothing.
  bool get _runsClock => isPacker || isDriver;

  /// The session to show on this packer's or driver's screens, or null for
  /// nothing.
  ShiftSessionState? get visibleSession {
    final current = state;
    if (!_started || !_runsClock || !isShiftClockVisible(current)) return null;
    return current;
  }

  /// The shift complete screen should be up: the clock itself says so and the
  /// packer or driver has nothing in hand. For a driver "nothing" has to be a
  /// count the app actually read in this stretch of overtime: transfers it
  /// could not see may be there.
  bool get wantsScreen => canShowShiftCompleteScreen(
        state: visibleSession,
        work: workInHand,
        workKnown: !isDriver || _transfersInHand != null,
      );

  /// The screen is up to tell them their extension was approved: until when,
  /// and the check-out they now make themselves.
  ///
  /// Not "was the screen open when it landed": they may have been in the tray
  /// tapping the push, or have killed the app entirely. It is up until they
  /// have read this particular approval and said so.
  bool get showsApproval {
    final session = visibleSession;
    if (session == null || session.status != ShiftStatus.extended) return false;
    // Already working it: this shift IS the extension, so there is nothing
    // left to act on and a screen here would shut them in.
    if (session.isExtensionShift) return false;
    final approvalId = _approvalId(session);
    return approvalId != null &&
        _approvalReadLoaded &&
        approvalId != _approvalRead;
  }

  /// The id of the approval running this extension, or null when there is none
  /// to show - an extension nobody in this app asked for, or an older backend.
  int? _approvalId(ShiftSessionState session) {
    final decision = session.lastDecision;
    if (decision == null ||
        decision.status != ShiftRequestStatus.approved ||
        decision.approvedUntil == null) {
      return null;
    }
    return decision.id;
  }

  /// They read the approval and went back to work. Remembered on the device,
  /// so closing the app does not put the page back in front of them.
  Future<void> dismissApproval() async {
    final session = visibleSession;
    final approvalId = session == null ? null : _approvalId(session);
    if (approvalId == null) return;
    _approvalRead = approvalId;
    notifyListeners();
    _syncScreen();
    final key = _approvalKey;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, approvalId);
  }

  String? get _approvalKey {
    try {
      final id = _home?.user.id;
      return id == null ? null : 'shift_clock_approval_read_$id';
    } catch (_) {
      return null;
    }
  }

  /// Reads the last approval they went back to work from, once per start.
  Future<void> _loadApprovalRead() async {
    if (_approvalReadLoaded) return;
    final key = _approvalKey;
    if (key == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _approvalRead = prefs.getInt(key);
    } catch (_) {
      _approvalRead = null;
    }
    _approvalReadLoaded = true;
    notifyListeners();
    _syncScreen();
  }

  bool get isScreenOpen => _closeScreen != null;

  /// A look at the clock is in flight, so the button that asked says so.
  bool get isRefreshing => _inFlight != null;

  /// Work the packer has to finish before they can be checked out: an order
  /// assigned to them, a basket session they are still packing, or the
  /// server's note saying it is waiting for one. A driver's is a transfer
  /// assigned to them that is packed or on the road (see [_load]). While there
  /// is any, the blocking screen stays away and the home status line says so
  /// instead.
  ///
  /// Work going away is believed only once it has held for
  /// [shiftWorkSettleDelay] (and, while the home screen is still asking for
  /// the packer's orders, a little longer): pull to refresh empties the
  /// assigned orders before it asks for them again, and the blocking screen
  /// must not jump up over a packer who still has the order in hand. Work
  /// landing in their hands is believed at once.
  ShiftWorkInHand get workInHand {
    final work = _workInHandNow;
    if (work != ShiftWorkInHand.none) return work;
    return _clearingWork ?? ShiftWorkInHand.none;
  }

  /// What the order flow (or, for a driver, the last look at their
  /// transfers) says this instant, before the settle above.
  ShiftWorkInHand get _workInHandNow {
    final note = state?.note ?? '';
    if (isDriver) {
      // Never the order flow: a driver is not dispatched orders or baskets,
      // and "finish this order" would send them looking for one.
      return driverWorkInHand(transfers: _transfersInHand, note: note);
    }
    return shiftWorkInHand(
      assignedOrder: _home?.latestOrder.isNotEmpty ?? false,
      openBasket: _order?.baskets.isNotEmpty ?? false,
      note: note,
    );
  }

  bool get hasWorkInHand => workInHand != ShiftWorkInHand.none;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Start for the logged-in user. [owner] is a dashboard; the clock keeps
  /// running until every owner has called [stop]. [order] is the order flow,
  /// for the basket session a packer may still have open; a driver's clock
  /// leaves it alone.
  Future<void> start(HomeProvider home,
      {required Object owner, OrderProvider? order}) async {
    if (_started && identical(_home, home)) {
      _owners.add(owner);
      _attachOrder(order);
      await refresh();
      return;
    }
    _stop();
    _home = home;
    if (!_runsClock) {
      _home = null;
      return;
    }
    _owners.add(owner);
    _started = true;
    _epoch++;
    _approvalReadLoaded = false;
    _approvalRead = null;
    _inForeground = true;
    _lastOnline = home.isOnline;
    home.addListener(_onHomeChanged);
    _attachOrder(order);
    WidgetsBinding.instance.addObserver(this);
    // The summary fetched at login already knows when this shift ends.
    _takeSeed(confirm: false);
    _lastWork = workInHand;
    // Before the first state lands, so an approval they already read does not
    // put its page back in front of them on every launch.
    await _loadApprovalRead();
    await refresh();
    await _handleLaunchMessage();
  }

  void _attachOrder(OrderProvider? order) {
    // Baskets are a packer's. A driver's clock must neither read them as work
    // in hand nor empty them on the way out (see _stop).
    if (order == null || identical(_order, order) || !isPacker) return;
    _order?.removeListener(_onWorkChanged);
    _order = order;
    order.addListener(_onWorkChanged);
  }

  /// [owner] (a dashboard) went away. Stops once no dashboard is left:
  /// logout or session expiry.
  void stop({required Object owner}) {
    if (!_owners.remove(owner)) return;
    if (_owners.isEmpty) _stop();
  }

  /// Still running (started by a dashboard that is alive).
  bool get isRunning => _started;

  void _stop() {
    _owners.clear();
    if (!_started) return;
    _started = false;
    _epoch++;
    _cancelTimers();
    _home?.removeListener(_onHomeChanged);
    // The seed belongs to the shift that just ended (logout, or another
    // packer signing in on this phone): the next clock must not start on it.
    _home?.summaryShift = null;
    _home = null;
    _cancelWorkSettle();
    _order?.removeListener(_onWorkChanged);
    // A basket this packer walked away from must not read as work in hand for
    // whoever signs in on this phone next: the order provider outlives them
    // both. Clears the scanned tags and racks with it, nothing on the server.
    _order?.resetState();
    _order = null;
    WidgetsBinding.instance.removeObserver(this);
    state = null;
    isSubmitting = false;
    isCancelling = false;
    requestError = null;
    _lastSeed = null;
    _lastWork = ShiftWorkInHand.none;
    // What one driver held says nothing about whoever signs in next.
    _transfersInHand = null;
    _transfersSessionId = null;
    _openingScreen = false;
    // Called while the dashboard is being disposed; tell listeners afterwards.
    Future.microtask(() {
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_inForeground) {
        _inForeground = true;
        // Timers do not run while the app is away: look at the clock again.
        refresh();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _inForeground = false;
      _cancelTimers();
    }
  }

  void _onHomeChanged() {
    _takeSeed();
    final online = _home?.isOnline ?? false;
    if (online != _lastOnline) {
      _lastOnline = online;
      if (online) {
        refresh();
      } else {
        _scheduleNext();
      }
    }
    _onWorkChanged();
  }

  /// An order was assigned or finished, or a basket session opened or closed:
  /// the status line changes and the blocking screen comes or goes with it.
  void _onWorkChanged() {
    if (!_started) return;
    final work = _workInHandNow;
    if (work == ShiftWorkInHand.none && _lastWork != ShiftWorkInHand.none) {
      // The work looks done. It may only be the home screen emptying its
      // orders before it asks for them again: wait and look once more.
      // Nothing changes for the packer meanwhile.
      if (_workSettleTimer == null) {
        _clearingWork = _lastWork;
        _workSettleRound = 0;
        _workSettleTimer = Timer(shiftWorkSettleDelay, _onWorkSettled);
      }
      return;
    }
    _cancelWorkSettle();
    _applyWork(work);
  }

  /// The wait above is over: believe what the order flow says now, unless the
  /// home screen is still waiting for the answer to its own request.
  void _onWorkSettled() {
    _workSettleTimer = null;
    if (!_started) {
      _clearingWork = null;
      return;
    }
    if ((_home?.isLoading ?? false) && _workSettleRound < _maxWorkSettleRounds) {
      _workSettleRound++;
      _workSettleTimer = Timer(shiftWorkSettleDelay, _onWorkSettled);
      return;
    }
    _clearingWork = null;
    _workSettleRound = 0;
    _applyWork(_workInHandNow);
  }

  void _cancelWorkSettle() {
    _workSettleTimer?.cancel();
    _workSettleTimer = null;
    _clearingWork = null;
    _workSettleRound = 0;
  }

  void _applyWork(ShiftWorkInHand work) {
    if (work == _lastWork) return;
    _lastWork = work;
    _syncScreen();
    notifyListeners();
  }

  /// Put the blocking screen up or take it down, as the clock and the work in
  /// hand now stand.
  void _syncScreen() {
    if (wantsScreen || showsApproval) {
      _openScreen();
    } else {
      _closeScreen?.call();
    }
  }

  // ---------------------------------------------------------------------------
  // The summary's shift block
  // ---------------------------------------------------------------------------

  /// Takes the `shift` block of the last packer summary, if it is new.
  void _takeSeed({bool confirm = true}) {
    final seed = _home?.summaryShift;
    if (seed == null || identical(seed, _lastSeed)) return;
    _lastSeed = seed;
    seedFromSummary(seed, confirm: confirm);
  }

  /// Apply a summary's `shift` block: the shift end and the grace deadline,
  /// which the app counts down to itself. Anything new in it is confirmed with
  /// GET /attendance/session/ before the app acts on it, so a seed can move
  /// the status line but never opens the blocking screen on its own.
  void seedFromSummary(ShiftSessionState seed, {bool confirm = true}) {
    if (!_started || !_runsClock) return;
    final current = state;
    final next = current == null ? seed : current.withSeed(seed);
    state = next;
    _lastWork = workInHand;
    notifyListeners();
    _syncScreen();

    if (confirm && next.fromSummary && next.enforced) {
      refresh();
      return;
    }
    _scheduleNext();
  }

  Future<void> _handleLaunchMessage() async {
    try {
      final message = await FirebaseMessaging.instance.getInitialMessage();
      if (message != null && isShiftClockPush(message.data)) {
        await handlePush(message.data);
      }
    } catch (e) {
      debugPrint('Shift clock launch message: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Refreshing
  // ---------------------------------------------------------------------------

  Future<void> refresh() {
    if (!_started) return Future.value();
    final running = _inFlight;
    if (running != null) {
      _refreshAgain = true;
      return running;
    }
    final future = _load().whenComplete(() {
      _inFlight = null;
      notifyListeners();
      if (_refreshAgain) {
        _refreshAgain = false;
        refresh();
      }
    });
    _inFlight = future;
    notifyListeners();  // so a button that asked for this can say it is asking
    return future;
  }

  Future<void> _load() async {
    final epoch = _epoch;
    final wasOnline = _home?.isOnline ?? false;
    try {
      final next = await _loadSession();
      if (epoch != _epoch) return;
      if (isDriver) {
        await _checkTransfers(next, epoch);
        if (epoch != _epoch) return;
      }
      _lastRefreshOk = true;
      await _apply(next, wasOnline: wasOnline);
    } catch (e) {
      if (epoch == _epoch) _lastRefreshOk = false;
      debugPrint('Shift clock refresh failed: $e');
    } finally {
      if (epoch == _epoch) _scheduleNext();
    }
  }

  /// A driver's work in hand, read in the same refresh as the session [next]
  /// it goes with, so the blocking screen is never put up on an older answer.
  ///
  /// The server's own note ([driverBusyNote]) only comes once the grace
  /// period is over, so the app looks itself - but only while the shift is
  /// over, which is the only time the answer changes anything. The clock
  /// polls then, so a received transfer brings the screen within one poll.
  /// Outside that the count is dropped, and the next stretch of overtime
  /// starts from "not known".
  Future<void> _checkTransfers(ShiftSessionState next, int epoch) async {
    if (!shouldCheckDriverTransfers(next)) {
      _transfersInHand = null;
      _transfersSessionId = null;
      return;
    }
    int? count;
    try {
      count = await _loadDriverTransfers();
    } catch (e) {
      debugPrint('Shift clock driver transfers: $e');
      // Can't tell whether they are carrying stock. That keeps a screen from
      // opening, but it must not take down one already up for this stretch
      // of overtime - along with whatever the driver was typing into the
      // request form - over one blip: keep what the last look found, as a
      // failed read of the session itself leaves the screen alone. A good
      // read that finds a transfer still closes it.
      if (isScreenOpen && _transfersSessionId == next.sessionId) {
        count = _transfersInHand;
      }
    }
    if (epoch != _epoch) return;
    _transfersInHand = count;
    _transfersSessionId = count == null ? null : next.sessionId;
  }

  /// A fresh look at how many transfers this driver holds, or null when it
  /// can't be read. For a refused check-out: only a transfer in hand makes a
  /// refusal worth stopping the logout for (driverCheckoutRefusalStops).
  Future<int?> readDriverTransfers() async {
    try {
      return await _loadDriverTransfers();
    } catch (e) {
      debugPrint('Driver transfers at check-out: $e');
      return null;
    }
  }

  void _cancelTimers() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _deadlineTimer?.cancel();
    _deadlineTimer = null;
  }

  /// A repeating poll while something is waiting on an answer; otherwise one
  /// wake-up at the shift end (and at the grace deadline), which is normally
  /// the only thing the app is waiting for.
  void _scheduleNext() {
    _cancelTimers();
    if (!_started || !_inForeground) return;
    final current = state;
    if (shouldPollShiftClock(screenOpen: isScreenOpen, state: current)) {
      final seconds =
          current?.pollSeconds ?? ShiftSessionState.defaultPollSeconds;
      _pollTimer = Timer(Duration(seconds: seconds), refresh);
      return;
    }
    final wait = shiftWakeUpDelay(current, DateTime.now());
    if (wait != null) _deadlineTimer = Timer(wait, refresh);
  }

  /// True while the clock keeps asking every poll_seconds.
  bool get isPolling => _pollTimer?.isActive ?? false;

  /// True while a one-shot wake-up is set for the shift end or the grace
  /// deadline.
  bool get isWaitingForDeadline => _deadlineTimer?.isActive ?? false;

  /// True while the clock is due to look again, either way.
  bool get isScheduled => isPolling || isWaitingForDeadline;

  /// [wasOnline]: whether the packer was online when [next] was requested
  /// (null when it came back from a request or cancel).
  Future<void> _apply(ShiftSessionState next, {bool? wasOnline}) async {
    final previous = state;
    state = next;
    _lastWork = workInHand;
    notifyListeners();
    _syncScreen();

    final approvedUntil = approvedUntilOnTransition(previous, next);
    if (approvedUntil != null && isShiftClockVisible(next)) {
      showToast(extensionApprovedMessage(
          approvedUntil, next.serverTimeAt(DateTime.now())));
    }

    if (!next.hasSession) {
      await _handleServerCheckout(next, wasOnline: wasOnline);
    }
    _scheduleNext();
  }

  // ---------------------------------------------------------------------------
  // Pushes and the online switch
  // ---------------------------------------------------------------------------

  Future<void> handlePush(Map<String, dynamic> data) async {
    if (!_started) return;
    await refresh();
    if (!_started) return;

    // Couldn't reach the server: still tell the packer they were checked out.
    if (data['type'] == ShiftPushType.autoCheckout && !_lastRefreshOk) {
      final reason = data['by'] == 'support'
          ? ShiftEndReason.forcedBySupport
          : ShiftEndReason.auto;
      await _rememberNotice('push:${DateTime.now().toUtc().toIso8601String()}');
      await _checkedOutByServer(checkoutNoticeMessage(reason));
    }
  }

  /// Going online was refused with 409 shift_complete.
  Future<void> onShiftCompleteRefused() => refresh();

  // ---------------------------------------------------------------------------
  // Extension requests
  // ---------------------------------------------------------------------------

  Future<bool> requestExtension({
    required double hours,
    String reason = '',
  }) async {
    if (isSubmitting) return false;
    isSubmitting = true;
    requestError = null;
    notifyListeners();
    try {
      final next = await ShiftClockRepo.requestExtension(
        hours: hours,
        reason: reason,
      );
      isSubmitting = false;
      await _apply(next);
      showToast('Request sent to support');
      return true;
    } catch (e) {
      isSubmitting = false;
      requestError = e is AppException ? e.message : e.toString();
      notifyListeners();
      refresh();
      return false;
    }
  }

  Future<void> cancelRequest(int requestId) async {
    if (isCancelling) return;
    isCancelling = true;
    notifyListeners();
    try {
      final next = await ShiftClockRepo.cancelRequest(requestId);
      isCancelling = false;
      requestError = null;
      await _apply(next);
      showToast('Request cancelled');
    } catch (e) {
      isCancelling = false;
      notifyListeners();
      showToast(e is AppException ? e.message : e.toString());
      refresh();
    }
  }

  // ---------------------------------------------------------------------------
  // The shift complete screen
  // ---------------------------------------------------------------------------

  void attachScreen(VoidCallback close) {
    _closeScreen = close;
    _openingScreen = false;
  }

  void detachScreen(VoidCallback close) {
    if (_closeScreen == close) _closeScreen = null;
  }

  /// Home status card tapped. A shift only the summary has told us about is
  /// confirmed with the clock first; the screen opens when that comes back.
  /// So is a driver's work, when their transfers could not be read last time.
  void openScreen() {
    if (wantsScreen) {
      _openScreen();
      return;
    }
    final session = visibleSession;
    if (session != null && session.showDialog && !hasWorkInHand) refresh();
  }

  void _openScreen() {
    if (isScreenOpen || _openingScreen) return;
    _openingScreen = true;
    final epoch = _epoch;
    _whenNothingOnTop(() {
      if (epoch != _epoch || isScreenOpen || !(wantsScreen || showsApproval)) {
        _openingScreen = false;
        return;
      }
      navigateWithRouter(
        AppRouter.router,
        route: NavigationConstants.shiftCompleteScreenRoute,
      );
      // The screen clears this when it attaches; don't stay stuck if it never does.
      Timer(const Duration(seconds: 5), () {
        if (!isScreenOpen) _openingScreen = false;
      });
    });
  }

  /// Runs [action] once no dialog, loader or sheet is on top (gives up waiting
  /// after 30 s).
  void _whenNothingOnTop(VoidCallback action, [int attempt = 0]) {
    if (!_started) {
      _openingScreen = false;
      return;
    }
    final blocked = AppConstants.navigatorKey.currentContext == null ||
        shiftClockRouteObserver.popupOnTop;
    if (blocked && attempt < 30) {
      Timer(const Duration(seconds: 1),
          () => _whenNothingOnTop(action, attempt + 1));
      return;
    }
    if (AppConstants.navigatorKey.currentContext == null) {
      _openingScreen = false;
      return;
    }
    action();
  }

  // ---------------------------------------------------------------------------
  // Checked out by the server
  // ---------------------------------------------------------------------------

  String? get _noticeKey {
    try {
      final id = _home?.user.id;
      return id == null ? null : '$_noticePrefsKey$id';
    } catch (_) {
      return null;
    }
  }

  /// An auto or support check-out the app hasn't dealt with: forget the
  /// check-in whenever it happened; tell the packer only if it was recent.
  Future<void> _handleServerCheckout(ShiftSessionState next,
      {bool? wasOnline}) async {
    final key = _noticeKey;
    final last = next.lastSession;
    if (key == null || last == null) return;
    final epoch = _epoch;
    final prefs = await SharedPreferences.getInstance();
    if (epoch != _epoch) return;
    final action = serverCheckoutAction(
      next,
      prefs.getString(key),
      now: DateTime.now(),
      // Offline when this state was requested, online now: the packer checked
      // in meanwhile and this state may be older than that check-in.
      wentOnlineMeanwhile:
          wasOnline == false && (_home?.isOnline ?? false),
    );
    if (action == ServerCheckoutAction.none) return;
    await prefs.setString(key, last.endedAtRaw);
    await _checkedOutByServer(action == ServerCheckoutAction.forgetCheckInAndTell
        ? checkoutNoticeMessage(last.endReason)
        : null);
  }

  Future<void> _rememberNotice(String marker) async {
    final key = _noticeKey;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, marker);
  }

  /// The backend closed the packer's online log: forget the check-in so the
  /// next go-online asks for the store QR check-in again and the next logout
  /// doesn't ask for a check-out scan, show them offline and, when [message]
  /// is given, tell them.
  Future<void> _checkedOutByServer(String? message) async {
    _closeScreen?.call();
    await SecureStorageHelper().remove(key: SecureStorageConstants.isOnlineKey);
    final home = _home;
    if (home != null) await home.markCheckedOutByServer();
    if (!_started || message == null) return;
    _whenNothingOnTop(() {
      final context = AppConstants.navigatorKey.currentContext;
      if (context == null) {
        showToast(message);
        return;
      }
      ShowAlertDialog(
        title: 'Checked out',
        body: Text(message),
        okTitle: 'OK',
        disableBackground: true,
        okFunc: () => Navigator.of(context).pop(),
      ).showAlertDialog(context);
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _stop();
    super.dispose();
  }
}
