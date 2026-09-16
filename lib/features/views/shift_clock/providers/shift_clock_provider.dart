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

/// The packer's shift clock.
///
/// Started by the dashboard for packers. It knows when the shift ends without
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

  /// [loadSession] replaces GET /attendance/session/ in tests.
  ShiftClockProvider({Future<ShiftSessionState> Function()? loadSession})
      : _loadSession = loadSession ?? ShiftClockRepo.getSession;

  final Future<ShiftSessionState> Function() _loadSession;

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

  bool get isPacker {
    try {
      return _home?.user.role == UserRole.packer;
    } catch (_) {
      return false;
    }
  }

  /// The session to show on this packer's screens, or null for nothing.
  ShiftSessionState? get visibleSession {
    final current = state;
    if (!_started || !isPacker || !isShiftClockVisible(current)) return null;
    return current;
  }

  /// The shift complete screen should be up: the clock itself says so and the
  /// packer has nothing in hand.
  bool get wantsScreen =>
      canShowShiftCompleteScreen(state: visibleSession, work: workInHand);

  bool get isScreenOpen => _closeScreen != null;

  /// Work the packer has to finish before they can be checked out: an order
  /// assigned to them, a basket session they are still packing, or the
  /// server's note saying it is waiting for one. While there is any, the
  /// blocking screen stays away and the home status line says so instead.
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

  /// What the order flow says this instant, before the settle above.
  ShiftWorkInHand get _workInHandNow => shiftWorkInHand(
        assignedOrder: _home?.latestOrder.isNotEmpty ?? false,
        openBasket: _order?.baskets.isNotEmpty ?? false,
        note: state?.note ?? '',
      );

  bool get hasWorkInHand => workInHand != ShiftWorkInHand.none;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Start for the logged-in user. [owner] is a dashboard; the clock keeps
  /// running until every owner has called [stop]. [order] is the order flow,
  /// for the basket session a packer may still have open.
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
    if (!isPacker) {
      _home = null;
      return;
    }
    _owners.add(owner);
    _started = true;
    _epoch++;
    _inForeground = true;
    _lastOnline = home.isOnline;
    home.addListener(_onHomeChanged);
    _attachOrder(order);
    WidgetsBinding.instance.addObserver(this);
    // The summary fetched at login already knows when this shift ends.
    _takeSeed(confirm: false);
    _lastWork = workInHand;
    await refresh();
    await _handleLaunchMessage();
  }

  void _attachOrder(OrderProvider? order) {
    if (order == null || identical(_order, order)) return;
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
    if (wantsScreen) {
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
    if (!_started || !isPacker) return;
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
      if (_refreshAgain) {
        _refreshAgain = false;
        refresh();
      }
    });
    _inFlight = future;
    return future;
  }

  Future<void> _load() async {
    final epoch = _epoch;
    final wasOnline = _home?.isOnline ?? false;
    try {
      final next = await _loadSession();
      if (epoch != _epoch) return;
      _lastRefreshOk = true;
      await _apply(next, wasOnline: wasOnline);
    } catch (e) {
      if (epoch == _epoch) _lastRefreshOk = false;
      debugPrint('Shift clock refresh failed: $e');
    } finally {
      if (epoch == _epoch) _scheduleNext();
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
    required String payType,
    String reason = '',
  }) async {
    if (isSubmitting) return false;
    isSubmitting = true;
    requestError = null;
    notifyListeners();
    try {
      final next = await ShiftClockRepo.requestExtension(
        hours: hours,
        payType: payType,
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
      if (epoch != _epoch || isScreenOpen || !wantsScreen) {
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
