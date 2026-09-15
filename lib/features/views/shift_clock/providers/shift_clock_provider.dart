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
import 'package:packer/features/views/shift_clock/models/shift_session.dart';
import 'package:packer/features/views/shift_clock/repo/shift_clock_repo.dart';
import 'package:packer/features/views/shift_clock/utils/shift_clock_logic.dart';
import 'package:packer/features/views/shift_clock/utils/shift_clock_route_observer.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';

/// The packer's shift clock (GET /attendance/session/).
///
/// Started by the dashboard for packers. Refreshes on start, on resume, every
/// poll_seconds while in the foreground and online, after going online, after
/// a shift push and after sending or cancelling a request. Opens the shift
/// complete screen while show_dialog is true and announces server check-outs.
class ShiftClockProvider with ChangeNotifier, WidgetsBindingObserver {
  static const _noticePrefsKey = 'shift_clock_checkout_notice_';

  ShiftSessionState? state;
  bool isSubmitting = false;
  bool isCancelling = false;
  String? requestError;

  HomeProvider? _home;
  Object? _owner;
  bool _started = false;
  bool _disposed = false;
  int _epoch = 0;
  bool _inForeground = true;
  bool _lastOnline = false;
  bool _lastRefreshOk = false;
  Timer? _pollTimer;
  Future<void>? _inFlight;
  bool _refreshAgain = false;

  VoidCallback? _closeScreen;
  bool _openingScreen = false;
  String? _snoozedSignature;

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

  /// The shift complete screen should be up (and hasn't been set aside).
  bool get wantsScreen =>
      (visibleSession?.showDialog ?? false) && _snoozedSignature == null;

  bool get isScreenOpen => _closeScreen != null;

  /// Work the packer has to finish before they can be checked out: the
  /// server's note (basket/order in hand, stock audit owed) or orders assigned
  /// to them in the app.
  bool get hasWorkInHand =>
      (state?.note.isNotEmpty ?? false) ||
      (_home?.latestOrder.isNotEmpty ?? false);

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Start for the logged-in user. [owner] is the widget that stops it again.
  Future<void> start(HomeProvider home, {required Object owner}) async {
    if (_started && identical(_home, home)) {
      _owner = owner;
      await refresh();
      return;
    }
    _stop();
    _home = home;
    if (!isPacker) {
      _home = null;
      return;
    }
    _owner = owner;
    _started = true;
    _epoch++;
    _inForeground = true;
    _lastOnline = home.isOnline;
    home.addListener(_onHomeChanged);
    WidgetsBinding.instance.addObserver(this);
    await refresh();
    await _handleLaunchMessage();
  }

  /// Stop when [owner] (the dashboard) goes away: logout or session expiry.
  void stop({required Object owner}) {
    if (!identical(owner, _owner)) return;
    _stop();
  }

  void _stop() {
    if (!_started) return;
    _started = false;
    _epoch++;
    _owner = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _home?.removeListener(_onHomeChanged);
    _home = null;
    WidgetsBinding.instance.removeObserver(this);
    state = null;
    isSubmitting = false;
    isCancelling = false;
    requestError = null;
    _snoozedSignature = null;
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
        refresh();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _inForeground = false;
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  void _onHomeChanged() {
    final online = _home?.isOnline ?? false;
    if (online == _lastOnline) return;
    _lastOnline = online;
    if (online) {
      refresh();
    } else {
      _schedulePoll();
    }
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
    try {
      final next = await ShiftClockRepo.getSession();
      if (epoch != _epoch) return;
      _lastRefreshOk = true;
      await _apply(next);
    } catch (e) {
      if (epoch == _epoch) _lastRefreshOk = false;
      debugPrint('Shift clock refresh failed: $e');
    } finally {
      if (epoch == _epoch) _schedulePoll();
    }
  }

  void _schedulePoll() {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (!_started || !_inForeground || !(_home?.isOnline ?? false)) return;
    final seconds = state?.pollSeconds ?? ShiftSessionState.defaultPollSeconds;
    _pollTimer = Timer(Duration(seconds: seconds), refresh);
  }

  Future<void> _apply(ShiftSessionState next) async {
    final previous = state;
    state = next;
    if (_snoozedSignature != null &&
        (!next.showDialog ||
            shiftSnoozeSignature(next) != _snoozedSignature ||
            !hasWorkInHand)) {
      _snoozedSignature = null;
    }
    notifyListeners();

    if (wantsScreen) {
      _openScreen();
    } else {
      _closeScreen?.call();
    }

    final approvedUntil = approvedUntilOnTransition(previous, next);
    if (approvedUntil != null && isShiftClockVisible(next)) {
      showToast(extensionApprovedMessage(approvedUntil, next.serverTime));
    }

    if (!next.hasSession) await _announceCheckout(next);
  }

  // ---------------------------------------------------------------------------
  // Pushes and the online switch
  // ---------------------------------------------------------------------------

  Future<void> handlePush(Map<String, dynamic> data) async {
    if (!_started) return;
    if (data['type'] == ShiftPushType.limitReached ||
        data['type'] == ShiftPushType.extensionDecided) {
      _snoozedSignature = null;
    }
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
  Future<void> onShiftCompleteRefused() async {
    _snoozedSignature = null;
    await refresh();
  }

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

  /// Home status card tapped.
  void openScreen() {
    _snoozedSignature = null;
    if (wantsScreen) _openScreen();
  }

  /// "Finish my current work first": set the screen aside while work is in
  /// hand and nothing about the shift changes.
  void snoozeForWorkInHand() {
    final current = state;
    if (current == null) return;
    _snoozedSignature = shiftSnoozeSignature(current);
    _closeScreen?.call();
    notifyListeners();
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

  Future<void> _announceCheckout(ShiftSessionState next) async {
    final key = _noticeKey;
    final last = next.lastSession;
    if (key == null || last == null) return;
    final epoch = _epoch;
    final prefs = await SharedPreferences.getInstance();
    if (epoch != _epoch) return;
    if (!isNewCheckoutNotice(next, prefs.getString(key), now: DateTime.now())) {
      return;
    }
    await prefs.setString(key, last.endedAtRaw);
    await _checkedOutByServer(checkoutNoticeMessage(last.endReason));
  }

  Future<void> _rememberNotice(String marker) async {
    final key = _noticeKey;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, marker);
  }

  /// The backend closed the packer's online log: forget the check-in so the
  /// next logout doesn't ask for a check-out scan, show them offline, tell them.
  Future<void> _checkedOutByServer(String message) async {
    _snoozedSignature = null;
    _closeScreen?.call();
    await SecureStorageHelper().remove(key: SecureStorageConstants.isOnlineKey);
    final home = _home;
    if (home != null) await home.markCheckedOutByServer();
    if (!_started) return;
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
