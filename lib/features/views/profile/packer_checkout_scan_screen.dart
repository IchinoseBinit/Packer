// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/validation_mixin.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/scan/scan_screen.dart'
    show ScannerOverlay, BarcodeOverlay, ScannerErrorWidget;
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:packer/utils/encode_decode_utils.dart';
import 'package:provider/provider.dart';

/// Scan the warehouse QR to checkout. Pops `true` on a successful checkout so
/// the caller (profile logout) can continue with the actual logout.
class PackerCheckoutScanScreen extends StatefulWidget {
  const PackerCheckoutScanScreen({super.key});

  @override
  State<PackerCheckoutScanScreen> createState() =>
      _PackerCheckoutScanScreenState();
}

class _PackerCheckoutScanScreenState extends State<PackerCheckoutScanScreen> {
  MobileScannerController? controller;
  bool hasScanned = false;
  bool _flash = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.stop();
    } else if (Platform.isIOS) {
      controller?.start();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> checkQr(String code) async {
    if (hasScanned) return;
    hasScanned = true;
    controller?.stop();

    HapticFeedback.heavyImpact();

    final decodeCode = customDecode(code);

    if (code.isEmpty) {
      _showInvalid("Invalid QR");
      return;
    }

    // Must be a Fasto waitlist QR.
    if (!decodeCode.contains('fasto-waitlist')) {
      _showInvalid("Invalid QR");
      return;
    }

    final homeProvider = Provider.of<HomeProvider>(context, listen: false);

    // The QR must belong to the store this packer is assigned to.
    final storeId = ValidationMixin().extractStoreIdFromQr(
      decodeCode,
      homeProvider.packerSummary?.storeId ?? -1,
    );
    if (storeId == null) {
      _showInvalid("You are not assigned to this store");
      return;
    }

    // The waitlist token must be valid (correct format and not expired).
    final result = ValidationMixin().validateWaitlistToken(decodeCode);
    if (!result.success) {
      _showInvalid(result.message);
      return;
    }

    // Validated locally; confirm checkout with the backend.
    showLoading(context);
    try {
      final success =
          await homeProvider.packerCheckoutLogout(decodeCode, context);
      removeLoading(context);
      if (success) {
        navigatePop(context, true);
      } else {
        _showInvalid("Failed to checkout. Please try again.");
      }
    } catch (ex) {
      removeLoading(context);
      _showInvalid(ex.toString());
    }
  }

  void _showInvalid(String message) {
    ShowAlertDialog(
      body: Text(message),
      okFunc: () {
        Navigator.pop(context);
        hasScanned = false;
        controller?.start();
      },
    ).showAlertDialog(context);
  }

  Widget _buildFlash() {
    return IconButton(
      onPressed: () async {
        await controller?.toggleTorch();
        setState(() => _flash = !_flash);
      },
      icon: Icon(
        _flash ? Icons.flash_off : Icons.flash_on,
        color: Colors.white,
      ),
    );
  }

  Widget _buildScanWindow(Rect scanWindowRect) {
    return ValueListenableBuilder(
      valueListenable: controller!,
      builder: (context, value, child) {
        if (!value.isInitialized ||
            !value.isRunning ||
            value.error != null ||
            value.size.isEmpty) {
          return const SizedBox();
        }
        return CustomPaint(painter: ScannerOverlay(scanWindowRect));
      },
    );
  }

  Widget _buildBarcodeOverlay() {
    return ValueListenableBuilder(
      valueListenable: controller!,
      builder: (context, value, child) {
        if (!value.isInitialized || !value.isRunning || value.error != null) {
          return const SizedBox();
        }
        return StreamBuilder<BarcodeCapture>(
          stream: controller!.barcodes,
          builder: (context, snapshot) {
            final BarcodeCapture? barcodeCapture = snapshot.data;
            if (barcodeCapture == null || barcodeCapture.barcodes.isEmpty) {
              return const SizedBox();
            }
            final scannedBarcode = barcodeCapture.barcodes.first;
            if (value.size.isEmpty ||
                scannedBarcode.size.isEmpty ||
                scannedBarcode.corners.isEmpty) {
              return const SizedBox();
            }
            return CustomPaint(
              painter: BarcodeOverlay(
                barcodeCorners: scannedBarcode.corners,
                barcodeSize: scannedBarcode.size,
                boxFit: BoxFit.contain,
                cameraPreviewSize: value.size,
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.sizeOf(context).center(Offset.zero),
      width: MediaQuery.sizeOf(context).width * 0.7,
      height: MediaQuery.sizeOf(context).width * 0.7,
    );
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            fit: BoxFit.cover,
            scanWindow: scanWindow,
            controller: controller,
            errorBuilder: (context, error, child) {
              return ScannerErrorWidget(error: error);
            },
            onDetect: (barcodes) {
              checkQr(barcodes.barcodes.first.rawValue.toString());
            },
          ),
          _buildBarcodeOverlay(),
          _buildScanWindow(scanWindow),
          Positioned(
            top: 8.h * 6,
            right: 4.w * 3,
            child: _buildFlash(),
          ),
          Positioned(
            top: 8.h * 6,
            left: 4.w * 3,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          Positioned(
            top: 32.h * 6,
            left: 4.w * 3,
            right: 4.w * 3,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
              alignment: Alignment.center,
              child: Text(
                'Scan to Checkout',
                style: TextStyle(
                  color: AppColors.backgroundColor,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
