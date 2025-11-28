import 'dart:developer' as dev;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkeep/flutter_callkeep.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/firebase_opt/firebase.dart';
import 'package:packer/controllers/services/hive_db/hive_db_service.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/router.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/driver/controller/driver_controller.dart';
import 'package:packer/features/views/damage_products/controller/damage_product_controller.dart';
import 'package:packer/features/views/expiry_product/providers/expired_product_provider.dart';
import 'package:packer/features/views/inventory_transfer_main_store/controller/inventory_transfer_controller.dart';
import 'package:packer/features/views/inventory_transfer_request/provider/inventory_transfer_request_controller.dart';
import 'package:packer/features/views/low_stock/provider/stock_provider.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:packer/features/views/packer_transfer/provider/packer_transfer_provider.dart';
import 'package:packer/features/views/product/provider/product_provider.dart';
import 'package:packer/features/views/profile/provider/order_return_provider.dart';
import 'package:packer/features/views/profile/provider/rack_update_provider.dart';
import 'package:packer/features/views/receive_baskets/controller/receive_basket_controller.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/stock_verification/provider/stock_verification_provider.dart';
import 'package:packer/features/views/vendor/providers/vendor_provider.dart';
import 'package:packer/features/views/widgets/custom_url.dart';
import 'package:packer/firebase_options.dart';
import 'package:packer/utils/call_keep_utils.dart';
import 'package:packer/utils/notification_utils.dart';
import 'package:provider/provider.dart';

import '/theme/theme.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  CustomUrlManager.clearCustomUrl();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  NotificationUtils.initializeLocalNotifications();

  // Lock device orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Request permission for notifications
  try {
    await FirebaseAPI().requestPermission();
  } catch (_) {}
  try {
    await HiveDBService.initHive();
  } catch (_) {}

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    handleIncomingCall(message, false);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    dev.log('A new onMessageOpenedApp event was published!');
    dev.log('Message data: ${message.data}');
  });
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  handleIncomingCall(message, true);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    print(state);
    if (state == AppLifecycleState.resumed) {
      // checkAndNavigationCallingPage();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<CallEvent?> getCurrentCall() async {
    //check current call from pushkit if possible
    var calls = await CallKeep.instance.activeCalls();

    if (calls.isNotEmpty) {
      print('DATA: $calls');
      return calls[0];
    } else {
      return null;
    }
  }
//   AwesomeNotifications().actionStream.listen((receivedAction) {
//   if (receivedAction.buttonKeyPressed == 'ACCEPT_ORDER') {
//     final orderId = receivedAction.payload?['orderId'];
//     if (orderId != null) {
//       _router.go('/order/$orderId');
//     }
//   }
// });

  checkAndNavigationCallingPage() async {
    var currentCall = await getCurrentCall();
    print('not answered call ${currentCall?.toMap()}');
    if (currentCall != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onCallAccepted(context, currentCall.uuid);
        navigateWithRouter(AppRouter.router,
            route: NavigationConstants.orderDetailsRoute,
            extra: currentCall.extra?['order_id']);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    FirebaseMessaging.instance.getToken().then((v) => dev.log(v.toString()));
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => PackerTransferProvider()),
        ChangeNotifierProvider(create: (_) => StockProvider()),
        ChangeNotifierProvider(create: (_) => ScanMessageProvider()),
        ChangeNotifierProvider(create: (_) => StockVerificationProvider()),
        ChangeNotifierProvider(create: (_) => RackUpdateProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderReturnProvider()),
        ChangeNotifierProvider(create: (_) => ExpiredProductProvider()),

        // driver
        ChangeNotifierProvider(create: (_) => DriverController()),
        ChangeNotifierProvider(create: (_) => ReceiveBasketController()),
        ChangeNotifierProvider(create: (_) => DamageProductController()),
        ChangeNotifierProvider(
            create: (_) => InventoryTransferRequestController()),
        // main store
        ChangeNotifierProvider(create: (_) => InventoryTransferController()),
        // vendor
        ChangeNotifierProvider(create: (_) => VendorProvider()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return Builder(builder: (newContext) {
            return SafeArea(
              top: false,
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                title: 'packer',
                themeMode: ThemeMode.light,
                theme: lightTheme(newContext),
                darkTheme: darkTheme(),
                routerConfig: AppRouter().getRoutes(context),
              ),
            );
          });
        },
      ),
    );
  }
}

const platform = MethodChannel('com.np.dropit.packer/call');

void setupNativeCallListeners() {
  platform.setMethodCallHandler((call) async {
    if (call.method == "callAccepted") {
      // 🔥 Call accepted, navigate to call screen
      openCallScreen();
    }
  });
}

void openCallScreen() {
  navigateWithRouter(
    AppRouter.router,
    route: NavigationConstants.orderDetailsRoute,
    // extra: currentCall.extra?['order_id']
  );
}
