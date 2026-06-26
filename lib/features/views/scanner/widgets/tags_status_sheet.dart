import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Bottom sheet content listing every expected tag with a tick when scanned.
///
/// Dumb widget: caller supplies the expected tags and a [isScanned] predicate
/// (usually wrapped in a provider `Consumer` for live updates).
class TagsStatusSheet extends StatelessWidget {
  final List<String> expectedTags;
  final bool Function(String tag) isScanned;
  final String title;

  const TagsStatusSheet({
    super.key,
    required this.expectedTags,
    required this.isScanned,
    this.title = 'Tags',
  });

  @override
  Widget build(BuildContext context) {
    final scannedCount = expectedTags.where(isScanned).length;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 0.8.sh),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$title  ($scannedCount/${expectedTags.length})',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 12.h),
              Flexible(
                child: expectedTags.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.h),
                        child: const Center(child: Text('No tags')),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: expectedTags.length,
                        separatorBuilder: (_, __) => SizedBox(height: 6.h),
                        itemBuilder: (context, index) {
                          final tag = expectedTags[index];
                          final scanned = isScanned(tag);
                          return Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 10.h),
                            decoration: BoxDecoration(
                              color: scanned
                                  ? Colors.green.withValues(alpha: 0.10)
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  scanned
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  size: 18.r,
                                  color: scanned ? Colors.green : Colors.grey,
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      decoration: scanned
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stops the scanner, shows [content] as a modal bottom sheet, then restarts.
Future<void> showTagsStatusSheet({
  required BuildContext context,
  required MobileScannerController controller,
  required WidgetBuilder content,
}) async {
  await controller.stop();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: content,
  );
  await controller.start();
}
