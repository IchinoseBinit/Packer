import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/extensions/string_extension.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/router.dart';

class NotificationUtils {
  static AwesomeNotifications awesomeNotification = AwesomeNotifications();

  static Future<AwesomeNotifications> changeNotification() async {
    return await initializeLocalNotifications();
  }

  static Future<AwesomeNotifications> initializeLocalNotifications() async {
    awesomeNotification = AwesomeNotifications();
    // await awesomeNotification.initialize(null, [...getNonSilentChannels(), ...getSilentChannels()]);
    await awesomeNotification.initialize(
        'resource://drawable/launcher_icon', [...getNonSilentChannels()],
        debug: true);

    awesomeNotification.setListeners(
        onActionReceivedMethod: onActionReceivedMethod);
    // debugger();

    return awesomeNotification;
  }

  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // debugger();
    debugPrint("ACCEPTED");
    if (receivedAction.buttonKeyPressed == 'Accept') {
      final orderId = receivedAction.payload?['orderId'].toString().toInt();

      // Navigate using GoRouter
      if (AppRouter.router.canPop()) {
        AppRouter.router.pop();
      }

      navigateWithRouter(
        AppRouter.router,
        route: NavigationConstants.basketScanScreenRoute,
        extra: {
          'forOrder': true,
          'fromCall': true,
          'orderId': orderId,
        },
      );
    }
  }

  static List<NotificationChannel> getNonSilentChannels() {
    final channel_3 = NotificationChannel(
      channelKey: 'call_channel',
      channelName: 'Incoming Calls',
      channelDescription: 'Channel for incoming call notifications',
      defaultColor: AppColors.primaryColor,
      ledColor: Colors.white,
      importance: NotificationImportance.Max,
      criticalAlerts: true,
      defaultPrivacy: NotificationPrivacy.Public,
      defaultRingtoneType: DefaultRingtoneType.Ringtone,
      enableVibration: true,
      enableLights: true,
      playSound: true,
      locked: true,
      soundSource: 'resource://raw/res_ringtone',
      icon: 'resource://drawable/ic_stat_call',
    );
    NotificationChannel channel = NotificationChannel(
      channelKey: 'activity',
      channelName: 'activity',
      channelDescription: 'Activity notifications',
      playSound: true,
      onlyAlertOnce: false,
      enableVibration: true,
      locked: true,
      soundSource: 'resource://raw/res_ringtone',
      defaultRingtoneType: DefaultRingtoneType.Ringtone,
      groupAlertBehavior: GroupAlertBehavior.Children,
      importance: NotificationImportance.Max,
      defaultColor: AppColors.primaryColor,
      ledColor: Colors.red,
    );
    NotificationChannel channel4 = NotificationChannel(
      channelKey: 'scheduled_channel',
      channelName: 'scheduled channel',
      channelDescription: 'Scheduled notifications',
      playSound: true,
      onlyAlertOnce: false,
      enableVibration: true,
      locked: true,
      soundSource: 'resource://raw/res_ringtone',
      defaultRingtoneType: DefaultRingtoneType.Ringtone,
      groupAlertBehavior: GroupAlertBehavior.Children,
      importance: NotificationImportance.Max,
      defaultColor: AppColors.primaryColor,
      ledColor: Colors.red,
    );
    NotificationChannel channel2 = NotificationChannel(
        channelKey: 'alerts',
        channelName: 'alerts',
        channelDescription: 'Activity alerts',
        onlyAlertOnce: false,
        enableVibration: true,
        playSound: true,
        defaultRingtoneType: DefaultRingtoneType.Notification,
        groupAlertBehavior: GroupAlertBehavior.Children,
        importance: NotificationImportance.High,
        defaultColor: AppColors.primaryColor,
        ledColor: Colors.red);
    return [channel, channel2, channel_3, channel4];
  }

  static List<NotificationChannel> getSilentChannels() {
    NotificationChannel channel3 = NotificationChannel(
        channelKey: 'silent_activity',
        channelName: 'silent_activity',
        channelDescription: 'Activity notifications',
        playSound: false,
        onlyAlertOnce: false,
        enableVibration: true,
        locked: true,
        soundSource: 'resource://raw/res_ringtone',
        defaultRingtoneType: DefaultRingtoneType.Ringtone,
        groupAlertBehavior: GroupAlertBehavior.Children,
        importance: NotificationImportance.High,
        defaultColor: Colors.red,
        ledColor: Colors.red);
    NotificationChannel channel4 = NotificationChannel(
        channelKey: 'silent_alerts',
        channelName: 'silent_alerts',
        channelDescription: 'Silent Activity alerts',
        onlyAlertOnce: false,
        enableVibration: true,
        playSound: false,
        defaultRingtoneType: DefaultRingtoneType.Notification,
        groupAlertBehavior: GroupAlertBehavior.Children,
        importance: NotificationImportance.High,
        defaultColor: Colors.red,
        ledColor: Colors.red);
    return [channel3, channel4];
  }
}
