import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/audit_product/utils/start_stock_audit.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:provider/provider.dart';

class TasksListCard extends StatelessWidget {
  const TasksListCard({super.key});

  String _formatType(String? type) {
    if (type == null) return 'Unknown';
    return type.split('_').map((e) {
      if (e.isEmpty) return '';
      return '${e[0].toUpperCase()}${e.substring(1)}';
    }).join(' ');
  }

  String _formatStatus(String? status) {
    if (status == null) return 'Unknown';
    if (status == 'not_created') return 'Not Started';
    return status.split('_').map((e) {
      if (e.isEmpty) return '';
      return '${e[0].toUpperCase()}${e.substring(1)}';
    }).join(' ');
  }

  IconData _taskIcon(String? type) {
    switch (type) {
      case 'stock_audit':
        return Icons.inventory_2_outlined;
      case 'store_cleanliness':
        return Icons.cleaning_services_outlined;
      case 'meter_reading':
        return Icons.speed_outlined;
      case 'fruits_vegetables':
        return Icons.eco_outlined;
      default:
        return Icons.task_alt_outlined;
    }
  }

  Color _accent(String? status) {
    if (status == 'completed') return const Color(0xff2E9E5B);
    if (status == 'rejected') return const Color(0xffE0354B);
    if (status == 'pending') return const Color(0xffE8A317);
    return const Color(0xff9E9E9E);
  }

  IconData _statusIcon(String? status) {
    if (status == 'completed') return Icons.check_circle_rounded;
    if (status == 'rejected') return Icons.cancel_rounded;
    if (status == 'pending') return Icons.access_time_filled_rounded;
    return Icons.radio_button_unchecked_rounded;
  }

  String? _routeForType(String? type) {
    switch (type) {
      case 'stock_audit':
        return NavigationConstants.auditProductScreenRoute;
      case 'store_cleanliness':
        return NavigationConstants.cleanlinessScreenRoute;
      case 'meter_reading':
        return NavigationConstants.meterReadingScreenRoute;
      case 'fruits_vegetables':
        return NavigationConstants.fruitsVegsScreenRoute;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        final tasks = provider.packerSummary?.tasks;
        if (tasks == null || tasks.isEmpty) {
          return const SizedBox.shrink();
        }

        final done = tasks.where((t) => t.status == 'completed').length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                Text(
                  "Tasks",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: done == tasks.length
                        ? const Color(0xffE9F7EF)
                        : const Color(0xffFFF8E1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '$done/${tasks.length}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: done == tasks.length
                          ? const Color(0xff2E9E5B)
                          : const Color(0xffE8A317),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            // ── Compact card ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xffECECEC)),
              ),
              child: Column(
                children: List.generate(tasks.length, (i) {
                  final task = tasks[i];
                  final color = _accent(task.status);
                  final isLast = i == tasks.length - 1;
                  final route = _routeForType(task.type);
                  return Column(
                    children: [
                      InkWell(
                        onTap: route != null
                            ? () async {
                                if (task.status == 'completed') {
                                  Fluttertoast.showToast(
                                    msg: 'Task already done',
                                  );
                                  return;
                                }

                                // Show a toast message
                                if (task.type == 'stock_audit' &&
                                    task.status == 'not_created') {
                                  return await startStockAudit(context);
                                }

                                navigate(context, route: route);
                              }
                            : null,
                        borderRadius: BorderRadius.vertical(
                          top: i == 0 ? Radius.circular(10.r) : Radius.zero,
                          bottom: isLast ? Radius.circular(10.r) : Radius.zero,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 10.h),
                          child: Row(
                            children: [
                              Icon(_taskIcon(task.type),
                                  size: 18.w, color: color),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Text(
                                  _formatType(task.type),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xff1A1C1E),
                                  ),
                                ),
                              ),
                              Icon(_statusIcon(task.status),
                                  size: 16.w, color: color),
                              SizedBox(width: 5.w),
                              Text(
                                _formatStatus(task.status),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                              if (route != null) ...[
                                SizedBox(width: 6.w),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 12.w,
                                  color: const Color(0xffBBBBBB),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: const Color(0xffF2F2F2),
                          indent: 40.w,
                        ),
                    ],
                  );
                }),
              ),
            ),
            SizedBox(height: 16.h),
          ],
        );
      },
    );
  }
}
