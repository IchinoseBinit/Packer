import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:packer/constants/app_colors.dart';
import 'package:packer/features/views/shift_clock/models/shift_session.dart';
import 'package:packer/features/views/shift_clock/providers/shift_clock_provider.dart';
import 'package:packer/features/views/shift_clock/utils/shift_clock_logic.dart';

/// Home screen shift status: "Shift ends 6 PM · 2 h 15 m left", "Extension
/// until 8 PM", "Shift over" or, with work in hand, "Shift over · finish this
/// order". Hidden unless the packer's shift clock is enforced and a session is
/// open.
///
/// The countdown ticks locally off the phone clock corrected against the
/// server's; nothing here asks the server anything.
class ShiftStatusCard extends StatefulWidget {
  const ShiftStatusCard({super.key});

  @override
  State<ShiftStatusCard> createState() => _ShiftStatusCardState();
}

class _ShiftStatusCardState extends State<ShiftStatusCard> {
  static const _tick = Duration(seconds: 20);

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Ticks only while a countdown is on screen: a packer with no session, or
  /// one whose shift is already over, has nothing to move.
  void _tickWhile(bool needed) {
    if (needed == (_timer != null)) return;
    if (needed) {
      _timer = Timer.periodic(_tick, (_) {
        if (mounted) setState(() {});
      });
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShiftClockProvider>(builder: (_, clock, __) {
      final now = DateTime.now();
      final session = clock.visibleSession;
      final work = clock.workInHand;
      _tickWhile(shiftStatusLineTicks(session, now));
      final title =
          session == null ? null : shiftStatusLine(session, now: now, work: work);
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
      // Work in hand: nothing to open, the packer finishes it first.
      final canOpen =
          over && session.showDialog && work == ShiftWorkInHand.none;

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
                          shiftStatusDetail(session, now: now, work: work),
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
