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
import 'package:packer/features/views/scanner/widgets/tags_status_sheet.dart';
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
      BuildContext context, MobileScannerController controller) {
    return showTagsStatusSheet(
      context: context,
      controller: controller,
      content: (_) => Consumer<StockAuditProvider>(
        builder: (context, provider, __) => TagsStatusSheet(
          expectedTags: provider.expectedTags,
          isScanned: provider.isScanned,
        ),
      ),
    );
  }

  @override
  void onDispose(MobileScannerController controller) async {
    await controller.stop();
    await controller.dispose();
  }
}
