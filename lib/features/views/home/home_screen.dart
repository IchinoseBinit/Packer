import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:packer/constants/app_assets.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/secure_storage_helper.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/home/widgets/order_list_widget.dart';
import 'package:packer/features/views/widgets/custom_switch.dart';
import 'package:packer/features/views/widgets/general_appbar.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:packer/features/views/widgets/progress_column.dart';
import 'package:packer/utils/call_keep_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    final provider = Provider.of<HomeProvider>(context, listen: false);
    provider.initialize(isFirstTime: true);
    getToken();
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HomeProvider>(context);
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
            if (provider.isAvailable) {
              provider.fetchCreatedOrders();
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

                if (provider.isOrder)
                  Text(
                    "Go to store",
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                        ),
                  ),
                SizedBox(height: 48.h),

                Consumer<HomeProvider>(builder: (context, val, _) {
                  print("is available ===== ${val.isAvailable}");
                  if ((val.isOnline && !val.isAvailable)) {
                    return GeneralElevatedButton(
                      onPressed: () {
                        navigate(context,
                            route: NavigationConstants.qrScanScreenRoute);
                      },
                      title: "Join the waitlist",
                    );
                  }
                  return const SizedBox.shrink();
                }),

                SizedBox(
                  height: 24.h,
                ),

                GeneralElevatedButton(
                    title: "title",
                    onPressed: () {
                      handleIncomingCall(const RemoteMessage(), false);
                    })
              ],
            ),
          ),
        ),
      ),
    );
  }
}
