import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_assets.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:packer/controllers/services/secure_storage_helper.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/home/widgets/order_list_widget.dart';
import 'package:packer/features/views/widgets/custom_switch.dart';
import 'package:packer/features/views/widgets/general_appbar.dart';
import 'package:packer/features/views/widgets/progress_column.dart';
import 'package:packer/features/views/widgets/update_url_widget.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    final provider = Provider.of<HomeProvider>(context, listen: false);

    provider.initialize(context, isFirstTime: true);
    provider.fetchpackerSummary();
    getToken();
    WidgetsBinding.instance.addObserver(this);
  }

  // For test purposes. Must remove this after!!!
  void getToken() async {
    String? token = await SecureStorageHelper.instance.readKey(key: 'tokenKey');
    if (token != null) {
      print('Token: $token');
    } else {
      print('No token found');
    }
  }

  bool refetch = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (refetch && state == AppLifecycleState.resumed) {
      final provider = Provider.of<HomeProvider>(context, listen: false);

      provider.initialize(context, isFirstTime: true);
      provider.fetchpackerSummary();
      refetch = false;
    } else if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      refetch = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HomeProvider>(context, listen: false);
    return Scaffold(
      appBar: GeneralAppBar(
        needLeading: false,
        middleWidget: Consumer<HomeProvider>(builder: (_, value, __) {
          return const CustomSwitch();
        }),
        trailingSvgAsset: AppAssets.bell_icon,
      ),
      body: Padding(
        padding: AppConstants.padding,
        child: RefreshIndicator(
          onRefresh: () {
            provider.initialize(context, isFirstTime: false);
            if (provider.isAvailable) {
              // provider.fetchCreatedOrders();
            }
            return provider.fetchLatestOrders();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const OrderListWidget(),
                // ShiftColumnBox(
                //   startingHour: 6,
                //   startingMin: 30,
                //   endingHour: 2,
                //   endingMin: 30,
                //   remainingTime: 16,
                //   isOnline: provider.isOnline,
                // ),
                // SizedBox(height: 20.h),

                const TodaysProgressWidget(),
                SizedBox(height: 20.h),
                // UpdateUrlWidget(),
                // Container(
                //   padding: EdgeInsets.all(5),
                //   decoration: BoxDecoration(
                //     color: AppColors.fillColor,
                //     borderRadius: BorderRadius.circular(5),
                //   ),
                //   child: Column(
                //     mainAxisAlignment: MainAxisAlignment.center,
                //     children: [
                //       Stack(
                //         children: [
                //           GestureDetector(
                //             onTap: () {
                //               Navigator.push(
                //                 context,
                //                 MaterialPageRoute(
                //                   builder: (context) => MapScreen(
                //                     currentPosition: provider.currentPosition,
                //                     destinationLocation:
                //                         provider.destinationLocation,
                //                     onUpdateDestination:
                //                         provider.updateDestination,
                //                   ),
                //                 ),
                //               );
                //             },
                //             child: SizedBox(
                //               height: 600,
                //               child: GalliMap(
                //                 onMapLoadComplete: (controller) {
                //                   provider
                //                       .onMapLoaded(controller as GalliController);
                //                 },
                //                 onTap: (tapLocation) {
                //                   print('User tapped on map: $tapLocation');
                //                   SocketService().connectAndListen();
                //                   SocketService()
                //                       .sendMessage(tapLocation.toString());
                //                 },
                //                 onMapUpdate: (event) {
                //                   // Handle map update events if needed
                //                 },
                //                 lines: provider.shortestPath != null
                //                     ? [
                //                         GalliLine(
                //                           line: provider.shortestPath!.line,
                //                           borderColor: Colors.red,
                //                           borderStroke: 5,
                //                           lineColor: Colors.red,
                //                           lineStroke: 5,
                //                         ),
                //                       ]
                //                     : [],
                //                 markers: [
                //                   GalliMarker(
                //                     latlng: LatLng(
                //                         provider.currentPosition.latitude,
                //                         provider.currentPosition.longitude),
                //                     markerWidget: Icon(Icons.location_on),
                //                   ),
                //                   GalliMarker(
                //                     latlng: provider.destinationLocation,
                //                     markerWidget: Icon(Icons.location_on,
                //                         color: Colors.red),
                //                   ),
                //                 ],
                //                 controller: controller,
                //               ),
                //             ),
                //           ),
                //           Positioned(
                //             top: 20,
                //             left: 20,
                //             child: IconButton(
                //               icon: provider.isMapFullScreen
                //                   ? const Icon(Icons.fullscreen_exit)
                //                   : const Icon(Icons.fullscreen),
                //               onPressed: () {
                //                 provider.toggleMapFullScreen(context);
                //               },
                //             ),
                //           ),
                //         ],
                //       ),
                //       SizedBox(height: 20.h),
                //     ],
                //   ),
                // ),

                // SizedBox(height: 20.h),

                SizedBox(height: 48.h),
                SizedBox(
                  height: 24.h,
                ),

                // if (stockProvider.lowStockList.isNotEmpty)
                //   GeneralElevatedButton(
                //       title: "Scan the carton",
                //       onPressed: () {
                //         navigate(context,
                //             route: NavigationConstants.qrScanScreenRoute);
                //       }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
