// ignore_for_file: avoid_print

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkeep/flutter_callkeep.dart';
import 'package:flutter_callkeep_example/app_router.dart';
import 'package:flutter_callkeep_example/navigation_service.dart';
import 'package:uuid/uuid.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  configureCallkeep();
  displayIncomingCall(const Uuid().v4());
}

void configureCallkeep() {
  final config = CallKeepConfig(
    appName: 'CallKeep',
    acceptText: 'Accept',
    declineText: 'Decline',
    missedCallText: 'Missed call',
    callBackText: 'Call back',
    android: CallKeepAndroidConfig(
      logo: "ic_logo",
      showCallBackAction: true,
      showMissedCallNotification: true,
      ringtoneFileName: 'system_ringtone_default',
      accentColor: '#0955fa',
      backgroundUrl: 'assets/test.png',
      incomingCallNotificationChannelName: 'Incoming Calls',
      missedCallNotificationChannelName: 'Missed Calls',
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

Future<void> displayIncomingCall(String uuid) async {
  final data = CallEvent(
    uuid: uuid,
    callerName: 'Hien Nguyen',
    handle: '0123456789',
    hasVideo: false,
    duration: 30000,
    extra: <String, dynamic>{'userId': '1a2b3c4d'},
  );

  await CallKeep.instance.displayIncomingCall(data);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final Uuid _uuid;
  String? _currentUuid;

  late final FirebaseMessaging _firebaseMessaging;

  @override
  void initState() {
    super.initState();
    _uuid = const Uuid();
    initFirebase();
    WidgetsBinding.instance.addObserver(this);
    //Check call when open app from terminated
    checkAndNavigationCallingPage();
    getDevicePushTokenVoIP();
  }

  Future<CallEvent?> getCurrentCall() async {
    //check current call from pushkit if possible
    var calls = await CallKeep.instance.activeCalls();
    if (calls.isNotEmpty) {
      print('DATA: $calls');
      _currentUuid = calls[0].uuid;
      return calls[0];
    } else {
      _currentUuid = "";
      return null;
    }
  }

  checkAndNavigationCallingPage() async {
    var currentCall = await getCurrentCall();
    print('not answered call ${currentCall?.toMap()}');
    if (currentCall != null) {
      NavigationService.instance.pushNamedIfNotCurrent(
        AppRoute.callingPage,
        args: currentCall.toMap(),
      );
    }
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    print(state);
    if (state == AppLifecycleState.resumed) {
      //Check call when open app from background
      checkAndNavigationCallingPage();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  initFirebase() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      print(e);
    }
    _firebaseMessaging = FirebaseMessaging.instance;
    _firebaseMessaging.requestPermission();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print(
          'Message title: ${message.notification?.title}, body: ${message.notification?.body}, data: ${message.data}');
      _currentUuid = _uuid.v4();
      displayIncomingCall(_currentUuid!);
    });
    _firebaseMessaging.getToken().then((token) {
      print('Device Token FCM: $token');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      onGenerateRoute: AppRoute.generateRoute,
      initialRoute: AppRoute.homePage,
      navigatorKey: NavigationService.instance.navigationKey,
      navigatorObservers: <NavigatorObserver>[
        NavigationService.instance.routeObserver
      ],
    );
  }

  Future<void> getDevicePushTokenVoIP() async {
    var devicePushTokenVoIP = await CallKeep.instance.getDevicePushTokenVoIP();
    print(devicePushTokenVoIP);
  }
}
