import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/cleanliness/models/cleanliness_item.dart';
import 'package:packer/features/views/cleanliness/repo/cleanliness_repo.dart';
import 'package:packer/utils/async_state.dart';

/// Each item gets its own countdown window (seconds), started by tapping it —
/// the length comes from the report's `cleanliness_time`. The countdown keeps
/// running while the camera is open — if it hits zero the capture screen
/// closes itself and the item is reported unavailable.
const int kCleanlinessSeconds = CleanlinessReport.defaultCleanlinessTime;

enum CleanlinessResult { uploaded, unavailable }

class CleanlinessProvider with ChangeNotifier {
  AsyncState<CleanlinessReport> reportState = AsyncState.idle();
  final Map<int, CleanlinessResult> results = {};

  /// Item currently under countdown. Null means no run in progress, which is
  /// also the signal for the capture screen to close itself.
  CleanlinessItem? activeItem;

  /// Window length for the item currently running, from the report's
  /// `cleanliness_time` (falls back to [kCleanlinessSeconds] if not loaded).
  int itemSeconds = kCleanlinessSeconds;
  int secondsLeft = kCleanlinessSeconds;
  bool busy = false;

  /// Set when the upload call fails. The capture screen shows this in a
  /// bottom sheet and only leaves once [acknowledgeUploadError] runs — the
  /// item stays pending either way (tapping it again starts a fresh window).
  String? uploadError;

  Timer? _timer;

  Future<void> getReport() async {
    reportState = AsyncState.loading();
    notifyListeners();
    try {
      reportState = AsyncState.success(await CleanlinessRepo.getReport());
    } catch (e) {
      reportState = AsyncState.error(e.toString());
    }
    notifyListeners();
  }

  /// Tapping an item starts its window.
  void startItem(CleanlinessItem item) {
    _timer?.cancel();
    activeItem = item;
    itemSeconds = reportState.data?.cleanlinessTime ?? kCleanlinessSeconds;
    secondsLeft = itemSeconds;
    busy = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsLeft <= 1) {
        t.cancel();
        secondsLeft = 0;
        _expire();
      } else {
        secondsLeft--;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  /// Backed out of the capture screen — no API call, item stays pending.
  void cancelItem() {
    _timer?.cancel();
    _timer = null;
    activeItem = null;
    busy = false;
    uploadError = null;
    notifyListeners();
  }

  /// Window closed with no photo: drop the capture screen right away, then
  /// report the item unavailable. Failure here just toasts — the screen is
  /// already gone by the time this call happens, there's nothing to show it on.
  Future<void> _expire() async {
    final item = activeItem;
    if (item == null) return;
    activeItem = null;
    notifyListeners();
    showToast('Time up — ${item.name} marked unavailable');
    try {
      await CleanlinessRepo.markUnavailable(item.itemId);
      results[item.itemId] = CleanlinessResult.unavailable;
    } catch (e) {
      showToast(e.toString());
    }
    _reload();
  }

  /// Photo taken inside the window. Ignored if the window already closed.
  /// Countdown stays cancelled (paused) for the whole call.
  Future<void> uploadPhoto(XFile file) async {
    final item = activeItem;
    if (item == null) return;
    _timer?.cancel();
    busy = true;
    notifyListeners();
    try {
      await CleanlinessRepo.uploadImage(item.itemId, file);
      results[item.itemId] = CleanlinessResult.uploaded;
      busy = false;
      activeItem = null;
      notifyListeners();
      _reload();
    } catch (e) {
      // Stay on activeItem — the capture screen shows uploadError and waits
      // for acknowledgeUploadError() before leaving.
      busy = false;
      uploadError = e.toString();
      notifyListeners();
    }
  }

  /// The packer tapped OK on the upload-error sheet — now the capture screen
  /// can close. Item is left pending; tapping it again starts a fresh window.
  void acknowledgeUploadError() {
    uploadError = null;
    activeItem = null;
    notifyListeners();
    _reload();
  }

  void _reload() {
    // Deferred: the notifyListeners() just above triggers the capture
    // screen's pop (via addPostFrameCallback there). Reloading synchronously
    // here would fire more notifyListeners() calls into that same pop
    // transition and throw "setState() called when widget tree was locked"
    // — so this waits for that frame to finish first.
    SchedulerBinding.instance.addPostFrameCallback((_) => getReport());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
