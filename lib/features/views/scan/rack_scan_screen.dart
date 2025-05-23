// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/low_stock/provider/stock_provider.dart';
import 'package:packer/features/views/packer_transfer/provider/packer_transfer_provider.dart';
import 'package:packer/features/views/scan/scan_screen.dart';

import 'package:packer/constants/app_colors.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:provider/provider.dart';

class RackScanScreen extends StatefulWidget {
  const RackScanScreen({
    super.key,
    required this.rack,
    required this.productId,
    this.updateRack = false,
    this.cartonProduct = false,
    this.message = "",
  });

  final String rack;
  final int productId;
  final bool updateRack;
  final bool cartonProduct;
  final String message;

  @override
  State<RackScanScreen> createState() => _RackScanScreenState();
}

class _RackScanScreenState extends State<RackScanScreen> {
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.stop();
    } else if (Platform.isIOS) {
      controller?.start();
    }
  }

  MobileScannerController? controller;

  var hasScanned = false;
  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
    controller?.start();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (widget.isfromCartItem) {
    //     Provider.of<OrderProvider>(context, listen: false)
    //         .initScanMessage(widget.productId ?? 0);
    //   }
    // });
  }

  var _flash = false;

  checkQr(String code) async{
    if (hasScanned) {
      return;
    }
    hasScanned = true;
    log(code, name: "qr code data");

    HapticFeedback.heavyImpact();

    if (widget.cartonProduct) {
      Provider.of<StockProvider>(context, listen: false)
          .scanRack(context, controller, code);
          hasScanned = false;
      return;
    }


    // updateRack
    if (widget.updateRack) {
      await Provider.of<PackerTransferProvider>(context, listen: false)
          .updateRack(context, code, widget.productId);
      controller?.stop();
      hasScanned = false;

      return;
    }

    if (code.toLowerCase().contains(widget.rack.toLowerCase())) {
      showLoading(context);
      controller?.stop();

      Provider.of<PackerTransferProvider>(context, listen: false)
          .initScanMessage(widget.productId);
          hasScanned = false;
      navigateReplacement(context,
          route: NavigationConstants.qrScanScreenRoute,
          extra: {
            "forTranfer": true,
            "productId": widget.productId,
          });

      removeLoading(context);
    } else {
      hasScanned = false;
      removeLoading(context);
      ShowAlertDialog(
        body: const Text("Invalid QR"),
        okFunc: () {
          Navigator.pop(context);
          controller?.start();
        },
      ).showAlertDialog(context);
      controller?.start();
    }
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
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          dispose();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // QRView(
            //   key: qrKey,
            //   onQRViewCreated: (qrController) {
            //     cameraController = qrController;
            //     qrController.scannedDataStream.listen((scanData) {
            //       if (scanData.code != null) {
            //         checkQr(scanData.code!);
            //       }
            //     });
            //   },
            //   overlay: QrScannerOverlayShape(
            //     borderColor: AppColors.primaryColor,
            //   ),
            // ),

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
              child: buildFlash(),
              top: 8.h * 6,
              right: 4.w * 3,
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
            // TODO: i want this in center of width
            if (widget.rack.isNotEmpty)
              Positioned(
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
                    'Scan the rack "${widget.rack}" code',
                    style: TextStyle(
                      color: AppColors.backgroundColor,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ),
            if (widget.message.isNotEmpty)
              Positioned(
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
                    widget.message,
                    style: TextStyle(
                      color: AppColors.backgroundColor,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
