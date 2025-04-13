import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkeep/flutter_callkeep.dart';
import 'package:is_lock_screen2/is_lock_screen2.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/secure_storage_constants.dart';
import 'package:packer/controllers/services/secure_storage_helper.dart';
import 'package:packer/utils/notification_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

@pragma('vm:entry-point')
void setupCallKeep() async {
  final config = CallKeepConfig(
    appName: 'Dropit',
    acceptText: 'Check',
    callBackText: 'Check',
    android: CallKeepAndroidConfig(
      logo: "launcher_icon",
      showMissedCallNotification: false,
      showCallBackAction: false,
      ringtoneFileName: 'res_ringtone',
      accentColor: '#E3436F',
      backgroundUrl: 'assets/images/logo_image.png',
      incomingCallNotificationChannelName: 'Incoming Calls',
    ),
    ios: CallKeepIosConfig(
      iconName: 'CallKitLogo',
      handleType: CallKitHandleType.generic,
      isVideoSupported: true,
      maximumCallGroups: 2,
      maximumCallsPerCallGroup: 1,
      audioSessionActive: true,
      audioSessionPreferredSampleRate: 44100.0,
      audioSessionPreferredIOBufferDuration: 0.005,
      supportsDTMF: true,
      supportsHolding: true,
      supportsGrouping: false,
      supportsUngrouping: false,
      ringtoneFileName: 'system_ringtone_default',
    ),
    headers: <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
  );
  CallKeep.instance.configure(config);
}

@pragma('vm:entry-point')
void handleIncomingCall( RemoteMessage message, bool isBackground) async {
  bool ringtone = true;
  AwesomeNotifications awesomeNotification =
      await NotificationUtils.changeNotification();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final tokenKey = await SecureStorageHelper()
      .readKey(key: SecureStorageConstants.accessTokenKey);
  if (tokenKey == null) return;
  int randomed =
      int.tryParse(message.data['displayId'] ?? "") ?? Random().nextInt(100000);
  await awesomeNotification.cancel(randomed);

  // bool fullScreen = message.data['title'] == "Order Request";
  // bool isMissed = message.data['title'] == "Order Missed";
  // bool isRejected = message.data['title'] == "Order Rejected";

  // bool fullScreenDelivery = message.data['title'] == "Delivery Request";
  // bool isMissedDelivery = message.data['title'] == "Delivery Missed";
  // bool isRejectedDelivery = message.data['title'] == "Delivery Rejected";

  var fullScreen = true;
  var isMissed = false;
  var isRejected = false;
  var fullScreenDelivery = true;
  var isMissedDelivery = false;
  var isRejectedDelivery = false;

  if (isRejected || isRejectedDelivery) return;
  if (isBackground) {
    await prefs.setBool("background_handler", true);
  }
  if (isMissed || isMissedDelivery) {
    await prefs.setBool("background_handler", false);
  }

  NotificationContent content = NotificationContent(
      id: randomed,
      fullScreenIntent: fullScreen || fullScreenDelivery,
      channelKey: true
          ? 'call_channel'
          : fullScreen || fullScreenDelivery
              ? (ringtone ? 'activity' : "silent_activity")
              : (ringtone ? "alerts" : "silent_alerts"),
      title: message.notification?.title,
      body: message.notification?.body,
      autoDismissible: fullScreen || fullScreenDelivery,
      largeIcon: 'https://dropit.com.np/static/img/logo.jpeg',

      // 'asset://assets/images/balloons-in-sky.jpg',
      notificationLayout: NotificationLayout.Default,
      locked: fullScreen || fullScreenDelivery,
      color: AppColors.primaryColor,
      backgroundColor: AppColors.primaryColor,
      category: NotificationCategory.Call,
      criticalAlert: true,
      displayOnBackground: true,
      displayOnForeground: true,
      wakeUpScreen: true,
      icon: 'resource://drawable/ic_stat_call',
      payload: {
        'fullScreen': fullScreen.toString(),
        'delivery': fullScreenDelivery.toString(),
        'notificationId': message.data["order"] ?? '1234567890',
        ...message.data,
        'screen': 'call',
        'orderId' :  message.data["order_id"] ?? '',
      });

  List<NotificationActionButton>? buttons = fullScreen || fullScreenDelivery
      ? [
          NotificationActionButton(
            key: 'Accept',
            label: 'Accept',
            actionType: ActionType.Default,
            color: AppColors.primaryColor,
            
          ),
         
        ]
      : null;
  try {
    
    final notificationStatus = await awesomeNotification.createNotification(
        content: content, actionButtons: buttons);

    if (isBackground) {
      final isLocked = (await isLockScreen() ?? false);
      if (isLocked) {
        await CallKeep.instance.displayIncomingCall(
          CallEvent(
            uuid: const Uuid().v4(),
            handle: 'Caller',
            hasVideo: false,
            extra: message.data,
          ),
        );
      }
    }
  } catch (ex) {
    print(ex);
  }

  
}

// void listenToActionStream(BuildContext context) {
//   AwesomeNotifications().actionStream.listen((receivedNotification) {
//     if (receivedNotification.buttonKeyPressed == 'ACCEPT') {
//       Navigator.of(context).push(
//         MaterialPageRoute(builder: (context) => BucketScanScreen()),
//       );
//     }
    
//     // You can also check the payload if needed
//     if (receivedNotification.payload?['navigation'] == 'true') {
//       // Additional navigation logic
//     }
//   });
// }

void onCallAccepted(BuildContext context, String callUUID) {
  // Navigate to call screen when answered
  print("Call Accepted: $callUUID");
} // Future<void> setEventHandler() async {
//   CallKeep.instance.handler = CallEventHandler(
//     onCallIncoming: (event) {
//       print('call incoming: ${event.toMap()}');
//       if (!CallKeep.instance.isIncomingCallDisplayed) {
//         showAdaptiveDialog(
//             context: AppRouter.context,
//             builder: (context) {
//               return AlertDialog(
//                 title: Text("Incoming Call"),
//                 content: Text("Incoming call from ${event.callerName}"),
//                 actions: [
//                   TextButton(
//                     onPressed: () {
//                       Navigator.pop(context);
//                       // getCallbackFunction()
//                     },
//                     child: Text("Accept"),
//                   ),
//                 ],
//               );
//             });
//       }
//     },
//     onCallStarted: (event) {
//       print('call started: ${event.toMap()}');
//     },
//     onCallEnded: (event) {
//       print('call ended: ${event.toMap()}');
//     },
//     onCallAccepted: (event) {
//       print('call answered: ${event.toMap()}');
//       // NavigationService.instance
//       //     .pushNamedIfNotCurrent(AppRoute.callingPage, args: event.toMap());
//     },
//     onCallDeclined: (event) async {
//       print('call declined: ${event.toMap()}');
//     },
//   );
// }
