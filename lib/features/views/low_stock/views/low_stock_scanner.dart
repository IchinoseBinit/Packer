// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/low_stock/provider/stock_provider.dart';
import 'package:packer/features/views/scan/scan_screen.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';

class LowStockScanner extends StatefulWidget {
  const LowStockScanner({
    super.key,
    this.forProduct = false,
    this.changeBasket = false,
  });

  final bool forProduct;
  final bool changeBasket;

  @override
  State<LowStockScanner> createState() => _LowStockScannerState();
}

class _LowStockScannerState extends State<LowStockScanner> {
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.stop();
    } else if (Platform.isIOS) {
      controller?.start();
    }
  }

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  MobileScannerController? controller;
  bool hasScanned = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  var _flash = false;

  checkQr(String code) async {
    try {
      if (hasScanned) return;
      hasScanned = true;
      controller?.stop();

      HapticFeedback.heavyImpact();

      if (widget.forProduct) {
        final value = await Provider.of<StockProvider>(context, listen: false)
            .checkItemQr(
          context,
          code,
        );
        if (value && mounted) {
          Navigator.pop(context);
          hasScanned = false;
        } else if (mounted) {
          controller?.start();
          hasScanned = false;
        }
      } else {
        final value = await Provider.of<StockProvider>(context, listen: false)
            .checkBasketQr(context, code);
        if (value.success && mounted) {
          hasScanned = false;

          if (!widget.changeBasket) {
            navigateReplacement(context,
                route: NavigationConstants.trolleyItemScreenRoute);
          } else {
            navigatePop(context);
          }
        } else if (mounted) {
          if (value.message != null) {
            handleInvalidQr(code, message: value.message);
          } else {
            hasScanned = false;
            controller?.start();
          }
        }
      }
    } catch (e) {
      handleInvalidQr(code);
    }
  }

  void handleInvalidQr(String code, {String? message}) {
    // removeLoading(context);
    ShowAlertDialog(
      body: Text("Invalid QR ${message ?? detectQrMessage(code)}"),
      okFunc: () {
        Navigator.pop(context);
        controller?.start();
      },
    ).showAlertDialog(context);
    controller?.start();
    hasScanned = false;
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  buildFlash() {
    return IconButton(
      onPressed: () async {
        await controller?.toggleTorch();
        setState(() {
          _flash = !_flash;
        });
      },
      icon: Column(
        children: [
          Text(
            _flash ? 'Flash on' : 'Flash off',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontSize: 6, color: Colors.white),
          ),
          Icon(
            _flash ? Icons.flash_on : Icons.flash_off,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildScanWindow(Rect scanWindowRect) {
    return ValueListenableBuilder(
      valueListenable: controller!,
      builder: (context, value, child) {
        // Not ready.
        if (!value.isInitialized ||
            !value.isRunning ||
            value.error != null ||
            value.size.isEmpty) {
          return const SizedBox();
        }

        return CustomPaint(
          painter: ScannerOverlay(scanWindowRect),
        );
      },
    );
  }

  Widget _buildBarcodeOverlay() {
    return ValueListenableBuilder(
      valueListenable: controller!,
      builder: (context, value, child) {
        // Not ready.
        if (!value.isInitialized || !value.isRunning || value.error != null) {
          return const SizedBox();
        }

        return StreamBuilder<BarcodeCapture>(
          stream: controller!.barcodes,
          builder: (context, snapshot) {
            final BarcodeCapture? barcodeCapture = snapshot.data;

            // No barcode.
            if (barcodeCapture == null || barcodeCapture.barcodes.isEmpty) {
              return const SizedBox();
            }

            final scannedBarcode = barcodeCapture.barcodes.first;

            // No barcode corners, or size, or no camera preview size.
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
      width: 200,
      height: 200,
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
              final code = barcodes.barcodes.first.rawValue.toString();
              checkQr(code);
            },
          ),
          _buildBarcodeOverlay(),
          _buildScanWindow(scanWindow),
          Positioned(
            child: buildFlash(),
            top: 8.h * 6,
            right: 4.w * 3,
          ),
          Positioned(
            top: 8.h * 6,
            right: 40.w * 3,
            child: Text(
              widget.forProduct ? 'Product Scanner' : 'Basket Scanner',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.backgroundColor),
            ),
          ),
          Positioned(
            top: 8.h * 6,
            left: 4.w * 3,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
            ),
          ),
          Consumer<StockProvider>(
            builder: (context, provider, child) {
              return Visibility(
                visible: widget.forProduct && provider.scanMessage.isNotEmpty,
                child: Positioned(
                  top: 32.h * 6,
                  left: 4.w * 3,
                  right: 4.w * 3,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      provider.scanMessage,
                      style: TextStyle(
                        color: AppColors.backgroundColor,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
