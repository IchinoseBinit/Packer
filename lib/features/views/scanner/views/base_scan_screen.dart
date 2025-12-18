import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:provider/provider.dart';

abstract class BaseScanScreen extends StatefulWidget {
  final String scanTitle;
  final bool showFlash;
  final bool showBackButton;
  final bool fromCall;
  final FloatingActionButtonLocation floatingActionButtonLocation;

  const BaseScanScreen({
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
  State<BaseScanScreen> createState() => _BaseScanScreenState();

  Future<void> onCodeDetected(
      BuildContext context, String code, MobileScannerController controller);
  void onDispose(MobileScannerController controller);

  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller);
}

class _BaseScanScreenState extends State<BaseScanScreen> {
  MobileScannerController? controller;
  bool _flash = false;
  bool hasScanned = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal, // fastest
      detectionTimeoutMs: 250, // throttle detection
      facing: CameraFacing.back,
      returnImage: false, //  avoid heavy image transfer
      torchEnabled: false,
      formats: [
        BarcodeFormat.qrCode,
      ], // Limit to only for QR code
      autoStart: true,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // if already started
      controller?.stop();
      await Future.delayed(const Duration(milliseconds: 300));

      controller?.start();

      widget.onScreenCreated(context);

      controller?.addListener(_onControllerChanged);
    });
  }

  void _onControllerChanged() {
    // if start then has Scanned false
    if (controller!.value.isRunning) {
      hasScanned = false;
    }
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
    widget.onDispose(controller!);
    controller?.stop();
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.sizeOf(context).center(Offset.zero),
      width: MediaQuery.sizeOf(context).width * 0.7,
      height: MediaQuery.sizeOf(context).width * 0.7,
    );

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          controller?.stop();
        } else {
          controller?.stop();
          ShowAlertDialog(
            body: Text("Are you sure you want to exit?"),
            needCancel: true,
            okFunc: () {
              // final navigator = Navigator.of(context);
              // var stack = navigator.widget.pages.map((p) => p.name).toList();

              // if (stack.last == NavigationConstants.productScanScreenRoute) {
              //   removeLoading(context);
              //   stack = navigator.widget.pages.map((p) => p.name).toList();
              //   log("Current Navigation Stack: $stack");
              //   navigatePop(context);
              //   stack = navigator.widget.pages.map((p) => p.name).toList();
              //   log("Current Navigation Stack: $stack");
              //   navigatePop(context);
              // }

              navigatePop(context);
              if (widget.fromCall) {
                navigateReplacement(context,
                    route: NavigationConstants.dashboardRoute);
              } else {
                navigatePop(context);
              }
            },
            cancelFunc: () {
              controller?.start();
              navigatePop(context);
            },
          ).showAlertDialog(context);
        }
      },
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        floatingActionButton: widget.buildFloatingButton(context, controller!),
        floatingActionButtonLocation: widget.floatingActionButtonLocation,
        body: Stack(
          children: [
            MobileScanner(
              fit: BoxFit.cover,
              scanWindow: scanWindow,
              controller: controller,
              errorBuilder: (context, error, child) =>
                  ScannerErrorWidget(error: error),
              onDetect: (barcodes) async {
                final code = barcodes.barcodes.first.rawValue ?? '';
                if (hasScanned) return;
                hasScanned = true;
                await widget.onCodeDetected(context, code, controller!);
              },
            ),
            _buildScanWindow(scanWindow),
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
                    controller?.stop();
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
                        controller?.start();
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
        await controller?.toggleTorch();
        setState(() => _flash = !_flash);
      },
      icon:
          Icon(_flash ? Icons.flash_off : Icons.flash_on, color: Colors.white),
    );
  }

  Widget _buildScanWindow(Rect scanWindow) {
    return ValueListenableBuilder(
      valueListenable: controller!,
      builder: (context, value, child) {
        if (!value.isInitialized ||
            !value.isRunning ||
            value.error != null ||
            value.size.isEmpty) {
          return const SizedBox();
        }
        return CustomPaint(painter: ScannerOverlay(scanWindow));
      },
    );
  }
}

class ScannerOverlay extends CustomPainter {
  final Rect scanWindow;

  ScannerOverlay(this.scanWindow);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.largest);
    final cutoutPath = Path()..addRect(scanWindow);
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;
    canvas.drawPath(
        Path.combine(PathOperation.difference, backgroundPath, cutoutPath),
        backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ScannerErrorWidget extends StatelessWidget {
  final MobileScannerException error;

  const ScannerErrorWidget({super.key, required this.error});

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
    }

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.white),
            Text(errorMessage, style: const TextStyle(color: Colors.white)),
            Text(error.errorDetails?.message ?? '',
                style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
