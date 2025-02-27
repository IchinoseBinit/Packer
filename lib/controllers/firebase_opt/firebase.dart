import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:packer/features/views/auth/model/order_notification.dart';
import 'package:packer/main.dart';

class FirebaseAPI {
  // Private constructor
  FirebaseAPI._internal();

  // Static instance of the class
  static final FirebaseAPI _instance = FirebaseAPI._internal();

  // Factory constructor to return the static instance
  factory FirebaseAPI() => _instance;

  // Firebase Messaging instance
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Topic name
  var topicName = "";

  // Request permission for notifications
  Future<void> requestPermission() async {
    await _firebaseMessaging.requestPermission();

    final fcmToken = await _firebaseMessaging.getToken();
    print('FcmToken: $fcmToken');

    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
    final perms = [
      NotificationPermission.FullScreenIntent,
      NotificationPermission.CriticalAlert,
      NotificationPermission.OverrideDnD,
      NotificationPermission.PreciseAlarms,
      NotificationPermission.Sound,
      NotificationPermission.Light,
      NotificationPermission.Vibration
    ];
    // Request special full-screen permission (for Samsung, Xiaomi, Oppo, etc.)
    await AwesomeNotifications().shouldShowRationaleToRequest(
        channelKey: 'call_channel', permissions: perms);

    AwesomeNotifications()
        .checkPermissionList(channelKey: 'call_channel', permissions: perms);
  }

  // Display notification using flutter_local_notifications
  Future<void> displayNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'Your Channel Name',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    // final orderId = message.data['order_id'];

    // if (orderId != null) {
    // }

    await flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }

  // Subscribe to a topic for packer status
  Future<void> packerStatus(String topicName) async {
    this.topicName = topicName;
    await _firebaseMessaging.subscribeToTopic(topicName);
  }

  // Unsubscribe from the topic
  Future<void> unsubscribepackerStatus() async {
    await _firebaseMessaging.unsubscribeFromTopic(topicName);
  }

  // Listen to notifications related to packer status
  void listenTopackerStatusNotifications(
      Function(OrderNotification order) onNotificationReceived) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(message.data);
      final order = OrderNotification.fromJson(message.data);
      onNotificationReceived(order);
    });
  }
}
