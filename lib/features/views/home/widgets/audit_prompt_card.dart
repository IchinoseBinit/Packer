import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:packer/constants/app_colors.dart';
import 'package:packer/features/views/audit_product/models/audit_status_enum.dart';
import 'package:packer/features/views/audit_product/utils/start_stock_audit.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';

/// Card shown on the home screen while a stock audit is pending.
///
/// Visible only when [packerSummary.auditStatus] is [AuditStatusEnum.notCreated]
/// or [AuditStatusEnum.ongoing]; hidden once completed (or null). Tapping starts
/// a not-created audit (confirm + backend call) or resumes an ongoing one.
class AuditPromptCard extends StatelessWidget {
  const AuditPromptCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(builder: (_, provider, __) {
      final status = provider.packerSummary?.auditStatus;

      if (status == null) {
        return const SizedBox.shrink();
      }

      final isOngoing = status == AuditStatusEnum.ongoing;

      // only prompt while an audit is pending
      if (status != AuditStatusEnum.notCreated && !isOngoing) {
        return const SizedBox.shrink();
      }

      final radius = BorderRadius.circular(12);
      return Padding(
        padding: EdgeInsets.only(bottom: 16.h),
        child: Material(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: () => startStockAudit(context),
            child: Padding(
              padding: EdgeInsets.all(14.w),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.primaryColor,
                    size: 24.w,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stock Audit',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          isOngoing
                              ? 'In progress — tap to continue'
                              : 'Pending — tap to start',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12.sp,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.primaryColor,
                    size: 14.w,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
