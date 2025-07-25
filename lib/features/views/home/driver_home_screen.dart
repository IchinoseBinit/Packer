import 'package:flutter/material.dart';
import 'package:packer/constants/app_assets.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/profile/driver_profile_screen.dart';
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
