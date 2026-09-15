import 'package:flutter/material.dart';

/// Tracks the top route of the app navigator.
///
/// The shift clock waits while a dialog or sheet is on top before it pushes
/// its screen or notice: `removeLoading` pops whatever route is on top, so a
/// screen pushed over a loader would be closed by that loader's owner.
class ShiftClockRouteObserver extends NavigatorObserver {
  final ValueNotifier<Route<dynamic>?> top = ValueNotifier(null);

  bool get popupOnTop => top.value is PopupRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    top.value = route;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (top.value == route) top.value = previousRoute;
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (top.value == route) top.value = previousRoute;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (top.value == oldRoute) top.value = newRoute;
  }

  @override
  void didChangeTop(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute) {
    top.value = topRoute;
  }
}

final shiftClockRouteObserver = ShiftClockRouteObserver();
