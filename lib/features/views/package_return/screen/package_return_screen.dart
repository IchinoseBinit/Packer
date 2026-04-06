import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/package_return/provider/package_return_provider.dart';
import 'package:packer/features/views/widgets/general_appbar.dart';
import 'package:provider/provider.dart';

class PackageReturnScreen extends StatefulWidget {
  const PackageReturnScreen({super.key});

  @override
  State<PackageReturnScreen> createState() => _PackageReturnScreenState();
}

class _PackageReturnScreenState extends State<PackageReturnScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PackageReturnProvider>().fetchPackageReturns();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.h),
        child: GeneralAppBar(
          middleWidget: Text("Package Returns"),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<PackageReturnProvider>().fetchPackageReturns();
        },
        child: Consumer<PackageReturnProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null) {
              return Center(child: Text(provider.error!));
            }

            final packageReturn = provider.packageReturnList;

            if (packageReturn == null ||
                packageReturn.data == null ||
                packageReturn.data!.isEmpty) {
              return const Center(child: Text("No package returns found"));
            }

            return ListView.builder(
              padding: EdgeInsets.all(12.w),
              itemCount: packageReturn.data!.length,
              itemBuilder: (context, index) {
                final order = packageReturn.data![index];

                return Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFE0F7FA),
                        Color(0xFFB3E5FC),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Order #${order.orderId}",
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(Icons.inventory_2_outlined, size: 20.sp),
                        ],
                      ),

                      SizedBox(height: 10.h),

                      /// Packages list
                      ListView.builder(
                        itemCount: order.packages?.length ?? 0,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, pkgIndex) {
                          final pkg = order.packages![pkgIndex];

                          return InkWell(
                            onTap: () async {
                              final isRackedScanned = await navigate(
                                context,
                                route: NavigationConstants.scanRackRoute,
                                extra: {"rack": pkg.rack},
                              );

                              if (isRackedScanned == true) {
                                // If rack scanning is successful, navigate to details

                                await Future.delayed(const Duration(
                                    milliseconds:
                                        300)); // slight delay for better UX

                                await navigate(
                                  context,
                                  route: NavigationConstants
                                      .scanPackageReturnRoute,
                                  extra: {
                                    "orderId": order.orderId,
                                    "packageId": pkg.identifier,
                                  },
                                );
                                context
                                    .read<PackageReturnProvider>()
                                    .fetchPackageReturns();
                              } else {
                                // Show error if rack scanning fails
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Rack scanning failed"),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              margin: EdgeInsets.only(bottom: 8.h),
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                children: [
                                  /// ❄️ Icon
                                  Container(
                                    padding: EdgeInsets.all(8.r),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.ac_unit,
                                      size: 16.sp,
                                      color: Colors.blue,
                                    ),
                                  ),

                                  SizedBox(width: 10.w),

                                  /// 📦 Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pkg.identifier ?? "-",
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 2.h),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              pkg.status ?? "-",
                                              style: TextStyle(
                                                fontSize: 11.sp,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Text(
                                              "Rack: ${pkg.rack ?? "-"}",
                                              style: TextStyle(
                                                fontSize: 11.sp,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  /// ➡️ Arrow
                                  Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
