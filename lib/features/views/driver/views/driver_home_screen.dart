import 'package:flutter/material.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/driver/controller/driver_controller.dart';
import 'package:packer/features/views/driver/widgets/driver_transfer_card.dart';
import 'package:packer/features/views/widgets/custom_switch.dart';
import 'package:packer/features/views/widgets/general_appbar.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:packer/main.dart' as SystemChannels;
import 'package:provider/provider.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final driverController =
          Provider.of<DriverController>(context, listen: false);
      driverController.fetchDriverTransfers(context, fromBuild: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        handleWillPop(context);
      },
      child: Scaffold(
        appBar: GeneralAppBar(
          needLeading: false,
          middleWidget: Consumer<HomeProvider>(builder: (_, value, __) {
            return const CustomSwitch();
          }),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            final driverController =
                Provider.of<DriverController>(context, listen: false);
            driverController.fetchDriverTransfers(context, fromBuild: true);
          },
          child: Consumer<HomeProvider>(
            builder: (context, homeProvider, c) {
              if (!homeProvider.isOnline) {
                return const Center(
                  child: Text("You are offline"),
                );
              }

              return Consumer<DriverController>(
                builder: (context, driverController, child) {
                  if (driverController.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (driverController.driverTransfers.isEmpty) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height *
                            0.8, // Ensures scrollability
                        child: const Center(
                          child: Text("No transfers found"),
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: AppConstants.padding,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: RefreshIndicator(
                      onRefresh: () async {
                        final driverController =
                            Provider.of<DriverController>(context, listen: false);
                        driverController.fetchDriverTransfers(context, fromBuild: true);
                      },
                      child: Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            itemCount: driverController.driverTransfers.length,
                            itemBuilder: (context, index) {
                              return DriverTransferCard(
                                transferItem:
                                    driverController.driverTransfers[index],
                                needGoToStore: false,
                                callback: () {
                                  Provider.of<DriverController>(context,
                                          listen: false)
                                      .onDetails(
                                          context,
                                          driverController
                                              .driverTransfers[index]);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future handleWillPop(BuildContext context) async {
    ShowAlertDialog(
      title: "Exit",
      body: const Text("Do you want to exit the app?"),
      okFunc: () async {
        Navigator.pop(context);
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      },
      needCancel: true,
      cancelFunc: () => Navigator.pop(context),
    ).showAlertDialog(context);
  }
}
