import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

abstract class QrBaseScanScreen extends StatefulWidget {
  final String scanTitle;
  final bool showFlash;
  final bool showBackButton;
  final bool fromCall;
  final FloatingActionButtonLocation floatingActionButtonLocation;

  const QrBaseScanScreen({
    super.key,
    required this.scanTitle,
    this.showFlash = true,
    this.showBackButton = true,
    this.fromCall = false,
    this.floatingActionButtonLocation =
        FloatingActionButtonLocation.centerFloat,
  });

  // also add onscreen created
  void onScreenCreated(BuildContext context);

  @override
  State<QrBaseScanScreen> createState() => _QrBaseScanScreenState();

  Future<void> onCodeDetected(
      BuildContext context, String code, QRViewController controller);
  void onDispose(QRViewController controller);

  Widget? buildFloatingButton(
      BuildContext context, QRViewController controller);
}

class _QrBaseScanScreenState extends State<QrBaseScanScreen> {
  QRViewController? controller;
  bool _flash = false;
  bool hasScanned = false;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // @override
  // void initState() {
  //   super.initState();

  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     controller?.start();

  //     widget.onScreenCreated(context);

  //     controller?.addListener(_onControllerChanged);
  //   });
  // }

  

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  void dispose() {
    widget.onDispose(controller!);
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    widget.onScreenCreated(context);
    controller.scannedDataStream.listen((scanData) {
      widget.onCodeDetected(context, scanData.code ?? '', controller);
    });
  }

  @override
  Widget build(BuildContext context) {


    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          controller?.pauseCamera();
        } else {
          controller?.pauseCamera();
          ShowAlertDialog(
            body: Text("Are you sure you want to exit?"),
            needCancel: true,
            okFunc: () {
              navigatePop(context);
              if (widget.fromCall) {
                navigateReplacement(context,
                    route: NavigationConstants.dashboardRoute);
              } else {
                navigatePop(context);
              }
            },
            cancelFunc: () {
              controller?.resumeCamera();
              navigatePop(context);
            },
          ).showAlertDialog(context);
        }
      },
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        floatingActionButton: controller != null ? widget.buildFloatingButton(context, controller!) : null,
        floatingActionButtonLocation: widget.floatingActionButtonLocation,
        body: Stack(
          children: [
            // MobileScanner(
            //   fit: BoxFit.cover,
            //   scanWindow: scanWindow,
            //   controller: controller,
            //   errorBuilder: (context, error, child) =>
            //       ScannerErrorWidget(error: error),
            //   onDetect: (barcodes) async {
            //     final code = barcodes.barcodes.first.rawValue ?? '';
            //     if (hasScanned) return;
            //     hasScanned = true;
            //     await widget.onCodeDetected(context, code, controller!);
            //   },
            // ),
            // _buildScanWindow(scanWindow),
            QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
            if (widget.showFlash)
              Positioned(
                top: 8.h * 6,
                right: 4.w * 3,
                child: _buildFlashButton(),
              ),
            Positioned(
              top: 8.h * 8,
              right: 40.w * 3,
              child: Text(
                widget.scanTitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.backgroundColor),
              ),
            ),
            if (widget.showBackButton)
              Positioned(
                top: 8.h * 6,
                left: 4.w * 3,
                child: IconButton(
                  onPressed: () {
                    controller?.stopCamera();
                    ShowAlertDialog(
                      body: Text("Are you sure you want to exit?"),
                      needCancel: true,
                      okFunc: () {
                        navigatePop(context);
                        if (widget.fromCall) {
                          navigateReplacement(context,
                              route: NavigationConstants.dashboardRoute);
                        } else {
                          navigatePop(context);
                        }
                      },
                      cancelFunc: () {
                        controller?.resumeCamera();
                        navigatePop(context);
                      },
                    ).showAlertDialog(context);
                  },
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ),
              ),
            Consumer<ScanMessageProvider>(
              builder: (_, provider, __) {
                if (provider.message.isEmpty) return const SizedBox();
                return Positioned(
                  top: 8.h * 20,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      provider.message,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFlashButton() {
    return IconButton(
      onPressed: () async {
        await controller?.toggleFlash();
        setState(() => _flash = !_flash);
      },
      icon:
          Icon(_flash ? Icons.flash_off : Icons.flash_on, color: Colors.white),
    );
  }

  
}



// class ScannerErrorWidget extends StatelessWidget {
//   final MobileScannerException error;

//   const ScannerErrorWidget({super.key, required this.error});

//   @override
//   Widget build(BuildContext context) {
//     String errorMessage;
//     switch (error.errorCode) {
//       case MobileScannerErrorCode.controllerUninitialized:
//         errorMessage = 'Controller not ready.';
//       case MobileScannerErrorCode.permissionDenied:
//         errorMessage = 'Permission denied';
//       case MobileScannerErrorCode.unsupported:
//         errorMessage = 'Scanning is unsupported on this device';
//       default:
//         errorMessage = 'Generic Error';
//     }

//     return ColoredBox(
//       color: Colors.black,
//       child: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(Icons.error, color: Colors.white),
//             Text(errorMessage, style: const TextStyle(color: Colors.white)),
//             Text(error.errorDetails?.message ?? '',
//                 style: const TextStyle(color: Colors.white)),
//           ],
//         ),
//       ),
//     );
//   }
// }
