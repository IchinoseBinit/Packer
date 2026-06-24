import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/audit_product/models/stock_audit_model.dart';
import 'package:packer/features/views/audit_product/providers/stock_audit_provider.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/scanner/views/base_scan_screen.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

/// Scan every expected tag of an audited product one by one, then submit.
class AuditScanScreen extends BaseScanScreen {
  final AuditProductModel product;

  const AuditScanScreen({super.key, required this.product})
      : super(
          scanTitle: 'Scan Audit Tags',
          showFlash: true,
          showBackButton: true,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );

  @override
  void onScreenCreated(BuildContext context) {
    context.read<StockAuditProvider>().startScanSession(product);
    _updateMessage(context);
  }

  void _updateMessage(BuildContext context) {
    final p = context.read<StockAuditProvider>();
    Provider.of<ScanMessageProvider>(context, listen: false).setMessage(
      context,
      "Scanned ${p.scannedTags.length}/${p.expectedTags.length}",
    );
  }

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    try {
      await controller.stop();
      final provider = context.read<StockAuditProvider>();
      final result = provider.addScan(code);

      switch (result) {
        case AuditScanResult.invalid:
          HapticFeedback.heavyImpact();
          throw Exception("Tag not part of this audit.");
        case AuditScanResult.duplicate:
          HapticFeedback.mediumImpact();
          _updateMessage(context);
          await controller.start();
          return;
        case AuditScanResult.ok:
          HapticFeedback.lightImpact();
          _updateMessage(context);
          await controller.start();
          return;
      }
    } catch (e) {
      handleInvalidCode(context, controller, code, e.toString());
    }
  }

  void handleInvalidCode(
      BuildContext context, MobileScannerController controller, String code,
      [String? message]) {
    ShowAlertDialog(
      disableBackground: true,
      body: Text(message ?? "Invalid QR ${detectQrMessage(code)}"),
      okFunc: () {
        Navigator.pop(context);
        controller.start();
      },
    ).showAlertDialog(context);
  }

  @override
  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller) {
    return Consumer<StockAuditProvider>(
      builder: (context, provider, _) {
        final scanned = provider.scannedTags.length;
        final total = provider.expectedTags.length;
        final canSubmit = provider.allScanned;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      provider.allScanned
                          ? "All $total tags scanned"
                          : "Scanned $scanned of $total",
                      style: TextStyle(color: Colors.white, fontSize: 13.sp),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Material(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'View tags',
                      onPressed: () => _showTagsSheet(context, controller),
                      icon: Icon(Icons.info_outline,
                          color: Colors.white, size: 20.r),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                  onPressed: canSubmit
                      ? () => _confirmAndSubmit(context, controller, provider)
                      : null,
                  icon: const Icon(Icons.check),
                  label: Text("Submit ($scanned/$total)"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmAndSubmit(
    BuildContext context,
    MobileScannerController controller,
    StockAuditProvider provider,
  ) async {
    await controller.stop();

    ShowAlertDialog(
      title: 'Submit Audit',
      needCancel: true,
      body: Text('Submit ${provider.scannedTags.length} scanned tags?'),
      okFunc: () async {
        Navigator.pop(context); // close dialog
        final ok = await provider.submitAudit(context);
        if (ok) {
          navigatePop(context); // leave scan screen
        } else {
          controller.start();
        }
      },
      cancelFunc: () {
        Navigator.pop(context);
        controller.start();
      },
    ).showAlertDialog(context);
  }

  /// Bottom sheet showing every expected tag with a tick when scanned.
  Future<void> _showTagsSheet(
      BuildContext context, MobileScannerController controller) async {
    await controller.stop();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Consumer<StockAuditProvider>(
        builder: (context, provider, __) {
          final tags = provider.expectedTags;
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
                      'Tags  (${provider.scannedTags.length}/${tags.length})',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 12.h),
                    Flexible(
                      child: tags.isEmpty
                          ? Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.h),
                              child: const Center(child: Text('No tags')),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: tags.length,
                              separatorBuilder: (_, __) =>
                                  SizedBox(height: 6.h),
                              itemBuilder: (context, index) {
                                final tag = tags[index];
                                final scanned = provider.isScanned(tag);
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
                                        color: scanned
                                            ? Colors.green
                                            : Colors.grey,
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
        },
      ),
    );
    await controller.start();
  }

  @override
  void onDispose(MobileScannerController controller) {}
}
