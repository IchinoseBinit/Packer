import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_assets.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:packer/controllers/services/secure_storage_helper.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/home/widgets/audit_prompt_card.dart';
import 'package:packer/features/views/home/widgets/order_list_widget.dart';
import 'package:packer/features/views/widgets/custom_switch.dart';
import 'package:packer/features/views/widgets/general_appbar.dart';
import 'package:packer/features/views/widgets/progress_column.dart';
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
            provider.fetchpackerSummary();
            return provider.fetchLatestOrders();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const OrderListWidget(),
                const TodaysProgressWidget(),
                const AuditPromptCard(),
                SizedBox(height: 20.h),
                SizedBox(height: 48.h),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
