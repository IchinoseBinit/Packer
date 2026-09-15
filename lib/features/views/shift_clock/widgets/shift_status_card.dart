import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:packer/constants/app_colors.dart';
import 'package:packer/features/views/shift_clock/models/shift_session.dart';
import 'package:packer/features/views/shift_clock/providers/shift_clock_provider.dart';
import 'package:packer/features/views/shift_clock/utils/shift_clock_logic.dart';

/// Home screen shift status: "Shift ends 2 PM", "Extension until 8 PM" or
/// "Shift complete". Hidden unless the packer's shift clock is enforced and a
/// session is open.
class ShiftStatusCard extends StatelessWidget {
  const ShiftStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ShiftClockProvider>(builder: (_, clock, __) {
      final session = clock.visibleSession;
      final title = session == null ? null : shiftStatusLine(session);
      if (session == null || title == null) {
        return const SizedBox.shrink();
      }

      final over = isShiftOver(session);
      final extended = !over && session.status == ShiftStatus.extended;
      final color = over
          ? AppColors.primaryColor
          : extended
              ? AppColors.green700
              : AppColors.blue500;
      final icon = over
          ? Icons.timer_off_outlined
          : extended
              ? Icons.more_time
              : Icons.schedule;
      final canOpen = over && session.showDialog;

      final radius = BorderRadius.circular(12);
      return Padding(
        padding: EdgeInsets.only(bottom: 16.h),
        child: Material(
          color: color.withValues(alpha: 0.08),
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: canOpen ? clock.openScreen : null,
            child: Padding(
              padding: EdgeInsets.all(14.w),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 24.w),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          shiftStatusDetail(session),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12.sp,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (canOpen)
                    Icon(
                      Icons.arrow_forward_ios,
                      color: color,
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
