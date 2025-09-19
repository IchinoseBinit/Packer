import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:packer/controllers/extensions/string_extension.dart';

navigate(BuildContext context, {required String route, Object? extra}) async {
  return context.push(route.addSlashInRoute(), extra: extra);
}

navigatePop<T extends Object?>(BuildContext context, [T? result]) {
  // can pop
  if (context.canPop()) return context.pop(result);
}

navigateReplacement(BuildContext context,
    {required String route, Object? extra}) async {
  context.replace(route.addSlashInRoute(), extra: extra);
}

navigateAndRemoveAll(BuildContext context, {required String route}) {
  context.go(route.addSlashInRoute());
}

navigateWithRouter(GoRouter router, {required String route, Object? extra}) {
  router.push(route.addSlashInRoute(), extra: extra);
}

navigateAndRemoveAllWithRouter(GoRouter router,
    {required String route, Object? extra}) {
  router.go(route.addSlashInRoute(), extra: extra);
}

navigateUntil(BuildContext context, {required String destinationRoute}) {
  while ((context.canPop()) &&
      (ModalRoute.of(context)!.settings.name != destinationRoute)) {
    context.pop();
  }
}
