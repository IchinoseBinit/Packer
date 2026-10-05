import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:packer/constants/app_colors.dart';

/// Capture slot for the meter photo: a dashed "tap to capture" target that
/// turns into the preview once a photo is taken, with Retake layered on top.
/// Camera only — an old gallery photo is not a reading of today's meter.
class MeterPhotoBox extends StatelessWidget {
  const MeterPhotoBox({
    super.key,
    required this.file,
    required this.onPicked,
  });

  final XFile? file;
  final ValueChanged<XFile> onPicked;

  Future<void> _capture() async {
    final res = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );
    if (res != null) onPicked(res);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _capture,
      child: file == null ? _empty(context) : _preview(context),
    );
  }

  Widget _empty(BuildContext context) {
    return CustomPaint(
      // Foreground so the dashes sit above the tinted fill below.
      foregroundPainter: _DashedRectPainter(
        color: AppColors.primaryColor.withValues(alpha: .35),
        radius: 14.r,
      ),
      child: Container(
        // A minimum rather than a fixed height: the contents scale off the
        // width factor, so pinning the height overflows on short, wide
        // viewports (landscape, tablets, large system font scale).
        constraints: BoxConstraints(minHeight: 176.h),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: .04),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 54.r,
              width: 54.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor.withValues(alpha: .10),
              ),
              child: Icon(
                Icons.photo_camera_outlined,
                color: AppColors.primaryColor,
                size: 26.r,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Tap to capture meter photo',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Keep every digit sharp and inside the frame',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5.sp,
                color: AppColors.homeScreenDimTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: Stack(
        children: [
          Image.file(
            File(file!.path),
            height: 210.h,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          // Scrim so the white chips below stay readable on a bright meter.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 60.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: .55),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 10.h,
            right: 10.w,
            child: _chip(
              icon: Icons.refresh,
              label: 'Retake',
              background: Colors.white,
              foreground: AppColors.primaryColor,
            ),
          ),
          Positioned(
            left: 10.w,
            bottom: 10.h,
            child: _chip(
              icon: Icons.check_circle,
              label: 'Photo captured',
              background: Colors.white.withValues(alpha: .18),
              foreground: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14.r, color: foreground),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed rounded rectangle, walked in fixed dash/gap steps along the path.
class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double _dash = 7;
  static const double _gap = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(
            distance,
            (distance + _dash).clamp(0.0, metric.length),
          ),
          paint,
        );
        distance += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
