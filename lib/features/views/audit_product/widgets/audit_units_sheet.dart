import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive/hive.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:packer/features/views/audit_product/models/stock_audit_model.dart';
import 'package:packer/features/views/audit_product/widgets/audit_scan_screen.dart';

/// Bottom sheet: audit product summary (type, expected qty, status) + unit tags.
class AuditUnitsSheet extends StatelessWidget {
  const AuditUnitsSheet({super.key, required this.product});

  final AuditProductModel product;

  static Future<void> open(BuildContext context,
      {required AuditProductModel product}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AuditUnitsSheet(product: product),
    );
  }

  Set<String> _loadSavedTags() {
    if (!Hive.isBoxOpen(HiveConstants.auditScanBox)) return const {};
    final saved = Hive.box(HiveConstants.auditScanBox)
        .get(product.productId.toString());
    if (saved == null) return const {};
    return (saved as List).cast<String>().toSet();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final units = product.units ?? const [];
    final savedTags = _loadSavedTags();
    final scannedCount = savedTags.length;
    final totalCount = units.length;
    final hasProgress = scannedCount > 0;
    final statusColor = product.isCompleted ? Colors.green : Colors.orange;

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
                product.productName,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 6.h,
                children: [
                  if (product.auditType.isNotEmpty)
                    _chip(Icons.fact_check_outlined, product.auditType),
                  _chip(Icons.inventory_2_outlined,
                      'Expected: ${product.expectedQuantity}'),
                  _chip(Icons.qr_code_2, 'Units: $totalCount'),
                  if (hasProgress && !product.isCompleted)
                    _chip(
                      Icons.qr_code_scanner,
                      'Scanned: $scannedCount/$totalCount',
                      color: scannedCount >= totalCount
                          ? Colors.green
                          : Colors.orange,
                    ),
                  _chip(
                    product.isCompleted
                        ? Icons.check_circle
                        : Icons.pending_outlined,
                    product.isCompleted ? 'Completed' : 'Pending',
                    color: statusColor,
                  ),
                ],
              ),
              if (!product.isCompleted) ...[
                SizedBox(height: 14.h),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    onPressed: units.isEmpty
                        ? null
                        : () {
                            final navigator = Navigator.of(context);
                            navigator.pop();
                            navigator.push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    AuditScanScreen(product: product),
                              ),
                            );
                          },
                    icon: Icon(
                        hasProgress ? Icons.play_arrow : Icons.qr_code_scanner),
                    label: Text(hasProgress
                        ? 'Resume Scanning ($scannedCount/$totalCount)'
                        : 'Scan Tags'),
                  ),
                ),
              ],
              SizedBox(height: 12.h),
              Flexible(
                child: units.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.h),
                        child: const Center(child: Text('No units')),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: units.length,
                        separatorBuilder: (_, __) => SizedBox(height: 6.h),
                        itemBuilder: (context, index) {
                          final tag = units[index].tag ?? '';
                          final isScanned =
                              savedTags.contains(tag) || product.isCompleted;
                          return Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 10.h),
                            decoration: BoxDecoration(
                              color: isScanned
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(10.r),
                              border: isScanned
                                  ? Border.all(
                                      color:
                                          Colors.green.withValues(alpha: 0.4),
                                      width: 1)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isScanned
                                      ? Icons.check_circle
                                      : Icons.qr_code_2,
                                  size: 18.r,
                                  color: isScanned ? Colors.green : null,
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Text(tag,
                                      style: TextStyle(fontSize: 13.sp)),
                                ),
                                if (isScanned)
                                  Text(
                                    'Scanned',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                else
                                  Text(
                                    'Remaining',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w500,
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

  Widget _chip(IconData icon, String label, {Color? color}) {
    return Builder(builder: (context) {
      final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15.r, color: c),
          SizedBox(width: 4.w),
          Text(label, style: TextStyle(fontSize: 12.sp, color: c)),
        ],
      );
    });
  }
}
