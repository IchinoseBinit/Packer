// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:packer/features/views/packer_transfer/provider/packer_transfer_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:provider/provider.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({
    super.key,
    this.isfromCartItem = false,
    this.productId,
    this.isFromPackerTransfer = false,
    this.checkIdentifier = false,
    this.scanCarton = false,
    this.forBasket = false,
    this.message = "",

  });

  final bool isfromCartItem;
  final int? productId;
  final bool isFromPackerTransfer;
  final bool checkIdentifier;
  final bool scanCarton;
  final bool forBasket;
  final String message;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
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

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isfromCartItem) {
        Provider.of<OrderProvider>(context, listen: false)
            .initScanMessage(widget.productId ?? 0);
      }
    });
  }

  var _flash = false;

  checkQr(String code) {
    controller?.stop();

    log(code, name: "qr code data");

    HapticFeedback.heavyImpact();
    if (widget.scanCarton){
      controller?.start();
      navigatePop(context, code);
      // navigate(context, route: NavigationConstants.scanRackRoute)
      return;
    }

    showLoading(context);

    if (code.contains('topicName')) {
      final data = jsonDecode(code);
      final topicName = data['topicName'];
      try {
        Provider.of<HomeProvider>(context, listen: false)
            .updateAvailability(topicName: topicName);
        removeLoading(context);
        Navigator.pop(context);
        showToast("joined the waiting list");
      } catch (ex) {
        removeLoading(context);
        showToast(ex.toString());
        print(ex.toString());
      }
    } else {
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
    return Scaffold(
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
              if (widget.isfromCartItem) {
                Provider.of<OrderProvider>(context, listen: false).checkItemQr(
                  context,
                  controller,
                  barcodes.barcodes.first.rawValue.toString(),
                );
                return;
              }
              if (widget.isFromPackerTransfer) {
                Provider.of<PackerTransferProvider>(context, listen: false)
                    .checkItemQr(
                        context,
                        controller,
                        barcodes.barcodes.first.rawValue.toString(),
                        widget.productId ?? 0);
                return;
              }
              if (widget.checkIdentifier) {
                Provider.of<PackerTransferProvider>(context, listen: false)
                    .checkIdentifier(
                        context,
                        controller,
                        barcodes.barcodes.first.rawValue.toString());
                return;
              }
              if (widget.forBasket) {
                Provider.of<PackerTransferProvider>(context, listen: false)
                    .checkBasketQr(
                        context,
                        controller,
                        barcodes.barcodes.first.rawValue.toString());
                return;
              }
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
          Consumer<OrderProvider>(
            builder: (context, provider, child) {
              return Visibility(
                visible: widget.isfromCartItem && provider.scanMessage != null,
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
                      provider.scanMessage ?? "",
                      style: TextStyle(
                        color: AppColors.backgroundColor,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Visibility(
            visible: widget.checkIdentifier,
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
                  'Scan the identifier code',
                  style: TextStyle(
                    color: AppColors.backgroundColor,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ),
          ),
          Visibility(
            visible: widget.message.isNotEmpty,
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
                  widget.message,
                  style: TextStyle(
                    color: AppColors.backgroundColor,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ),
          ),
          Consumer<PackerTransferProvider>(
            builder: (context, provider, child) {
              return Visibility(
                visible: widget.isFromPackerTransfer && provider.scanMessage != null,
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
                      provider.scanMessage ?? "",
                      style: TextStyle(
                        color: AppColors.backgroundColor,
                        fontSize: 12.sp,
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

class ScannerOverlay extends CustomPainter {
  ScannerOverlay(this.scanWindow);

  final Rect scanWindow;

  @override
  void paint(Canvas canvas, Size size) {
    // TODO: use `Offset.zero & size` instead of Rect.largest
    // we need to pass the size to the custom paint widget
    final backgroundPath = Path()..addRect(Rect.largest);
    final cutoutPath = Path()..addRect(scanWindow);

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final backgroundWithCutout = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );
    canvas.drawPath(backgroundWithCutout, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class BarcodeOverlay extends CustomPainter {
  BarcodeOverlay({
    required this.barcodeCorners,
    required this.barcodeSize,
    required this.boxFit,
    required this.cameraPreviewSize,
  });

  final List<Offset> barcodeCorners;
  final Size barcodeSize;
  final BoxFit boxFit;
  final Size cameraPreviewSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (barcodeCorners.isEmpty ||
        barcodeSize.isEmpty ||
        cameraPreviewSize.isEmpty) {
      return;
    }

    final adjustedSize = applyBoxFit(boxFit, cameraPreviewSize, size);

    double verticalPadding = size.height - adjustedSize.destination.height;
    double horizontalPadding = size.width - adjustedSize.destination.width;
    if (verticalPadding > 0) {
      verticalPadding = verticalPadding / 2;
    } else {
      verticalPadding = 0;
    }

    if (horizontalPadding > 0) {
      horizontalPadding = horizontalPadding / 2;
    } else {
      horizontalPadding = 0;
    }

    final double ratioWidth;
    final double ratioHeight;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      ratioWidth = barcodeSize.width / adjustedSize.destination.width;
      ratioHeight = barcodeSize.height / adjustedSize.destination.height;
    } else {
      ratioWidth = cameraPreviewSize.width / adjustedSize.destination.width;
      ratioHeight = cameraPreviewSize.height / adjustedSize.destination.height;
    }

    final List<Offset> adjustedOffset = [
      for (final offset in barcodeCorners)
        Offset(
          offset.dx / ratioWidth + horizontalPadding,
          offset.dy / ratioHeight + verticalPadding,
        ),
    ];

    final cutoutPath = Path()..addPolygon(adjustedOffset, true);

    final backgroundPaint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    canvas.drawPath(cutoutPath, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class ScannerErrorWidget extends StatelessWidget {
  const ScannerErrorWidget({super.key, required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    String errorMessage;

    switch (error.errorCode) {
      case MobileScannerErrorCode.controllerUninitialized:
        errorMessage = 'Controller not ready.';
      case MobileScannerErrorCode.permissionDenied:
        errorMessage = 'Permission denied';
      case MobileScannerErrorCode.unsupported:
        errorMessage = 'Scanning is unsupported on this device';
      default:
        errorMessage = 'Generic Error';
        break;
    }

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Icon(Icons.error, color: Colors.white),
            ),
            Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              error.errorDetails?.message ?? '',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
