import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:packer/constants/app_colors.dart';
import 'package:packer/features/views/shift_clock/models/shift_refusal.dart';
import 'package:packer/features/views/shift_clock/utils/shift_clock_logic.dart';
import 'package:packer/features/views/shift_clock/utils/sign_in_refusal.dart';

/// Why the login screen can't let this packer or driver in: the roster sign-in
/// gate's own sentence ("Your shift starts at 6:00 AM. You can sign in from
/// 5:00 AM."), under a heading and over the shift it is about.
///
/// It stays until the next sign-in attempt. A toast is gone before the time
/// in it has been read, and a person signed out by the clock mid-use lands
/// here with nothing else on screen to say why. Nothing shows while
/// [signInRefusal] is empty - with the gate off, always.
class ShiftRefusalCard extends StatelessWidget {
  const ShiftRefusalCard({super.key, this.margin});

  /// Room around the card, taken only while it shows.
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ShiftRefusal?>(
      valueListenable: signInRefusal,
      builder: (context, refusal, _) {
        if (refusal == null) return const SizedBox.shrink();
        final shiftLine = shiftRefusalShiftLine(refusal);
        final icon = refusal.code == ShiftRefusalCode.shiftNotStarted
            ? Icons.schedule
            : refusal.code == ShiftRefusalCode.shiftOver
                ? Icons.timer_off_outlined
                : Icons.event_busy;

        final card = Semantics(
          // Read out as it appears: it replaces the answer to the tap on Login.
          liveRegion: true,
          container: true,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppColors.primaryColor, size: 24.w),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shiftRefusalTitle(refusal),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        shiftRefusalMessage(refusal),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13.sp,
                          color: Colors.black87,
                        ),
                      ),
                      if (shiftLine != null) ...[
                        SizedBox(height: 6.h),
                        Text(
                          shiftLine,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12.sp,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        final margin = this.margin;
        return margin == null ? card : Padding(padding: margin, child: card);
      },
    );
  }
}
