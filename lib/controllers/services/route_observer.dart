import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:packer/controllers/extensions/debug_print_extension.dart';

class GoRouterObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);

    '[GoRouterObserver] PUSHED: ${route.settings.name}, FROM: ${previousRoute?.settings.name}'
        .log();
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);

    '[GoRouterObserver] POPPED: ${route.settings.name}, TO: ${previousRoute?.settings.name}'
        .log();
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);

    '[GoRouterObserver] REMOVED: ${route.settings.name}, FROM: ${previousRoute?.settings.name}'
        .log();
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);

    '[GoRouterObserver] REPLACED: ${oldRoute?.settings.name} -> ${newRoute?.settings.name}'
        .log();
  }

  @override
  void didChangeTop(Route topRoute, Route? previousTopRoute) {
    super.didChangeTop(topRoute, previousTopRoute);

    '[GoRouterObserver] REPLACED: ${previousTopRoute?.settings.name} -> ${topRoute.settings.name}'
        .log();
  }
}
