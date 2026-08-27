import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/cleanliness/models/cleanliness_item.dart';
import 'package:packer/features/views/cleanliness/providers/cleanliness_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:provider/provider.dart';

/// In-app camera so the countdown keeps running while it is open and the
/// screen can close itself the moment the window expires — a system camera
/// (image_picker) cannot be dismissed from here.
class CleanlinessCaptureScreen extends StatefulWidget {
  const CleanlinessCaptureScreen({super.key, required this.item});

  final CleanlinessItem item;

  @override
  State<CleanlinessCaptureScreen> createState() =>
      _CleanlinessCaptureScreenState();
}

class _CleanlinessCaptureScreenState extends State<CleanlinessCaptureScreen> {
  late final CleanlinessProvider _provider =
      context.read<CleanlinessProvider>();
  CameraController? _controller;
  String? _cameraError;
  bool _shooting = false;
  bool _popped = false;
  bool _loadingShown = false;
  bool _errorShown = false;

  @override
  void initState() {
    super.initState();
    _provider.addListener(_onProviderChanged);
    _initCamera();
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    _controller?.dispose();
    super.dispose();
  }

  /// Reacts to the three things the provider can throw at this screen:
  /// an upload failure (show the error sheet), the busy flag toggling
  /// (loading dialog), or activeItem clearing — on expiry, on a successful
  /// upload, or after the error sheet is acknowledged — which closes the
  /// screen. Only one of these applies per tick, checked in that order.
  void _onProviderChanged() {
    if (!mounted) return;

    final error = _provider.uploadError;
    if (error != null) {
      if (!_errorShown) {
        _errorShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          _dismissLoadingDialog();
          await _showUploadErrorSheet(error);
        });
      }
      return;
    }

    if (_provider.busy) {
      if (!_loadingShown) {
        _loadingShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) showLoading(context, label: 'Uploading...');
        });
      }
      return;
    }
    _dismissLoadingDialog();

    if (_popped || _provider.activeItem != null) return;
    _popped = true;
    _provider.removeListener(_onProviderChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).pop();
      }
    });
  }

  void _dismissLoadingDialog() {
    if (!_loadingShown) return;
    _loadingShown = false;
    if (mounted) removeLoading(context);
  }

  Future<void> _showUploadErrorSheet(String message) async {
    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) => PopScope(
        canPop: false, // OK button only — same rule as the capture screen
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 40.r),
                SizedBox(height: 12.h),
                Text('Upload Failed',
                    style: TextStyle(
                        fontSize: 16.sp, fontWeight: FontWeight.w600)),
                SizedBox(height: 8.h),
                Text(message, textAlign: TextAlign.center),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('OK',
                        style: TextStyle(color: AppColors.backgroundColor)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (mounted) _provider.acknowledgeUploadError();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw 'No camera found on this device';
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (e) {
      if (mounted) setState(() => _cameraError = e.toString());
    }
  }

  Future<void> _shoot() async {
    final controller = _controller;
    if (_shooting || controller == null || !controller.value.isInitialized) {
      return;
    }
    setState(() => _shooting = true);
    try {
      final file = await controller.takePicture();
      await _provider.uploadPhoto(file); // no-op if the window already expired
    } catch (e) {
      if (mounted) setState(() => _cameraError = e.toString());
    }
    if (mounted) setState(() => _shooting = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Only the countdown expiring or a successful upload may close this
      // screen — both call Navigator.pop() directly (bypasses PopScope), so
      // the back button/gesture stays blocked for the whole time it's open.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        showToast('Finish this item before going back');
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Text(widget.item.name, style: TextStyle(fontSize: 15.sp)),
        ),
        body: _cameraError != null
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(24.r),
                  child: Text(
                    _cameraError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
            : _controller == null
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(_controller!),
                      _overlay(),
                    ],
                  ),
      ),
    );
  }

  Widget _overlay() => Consumer<CleanlinessProvider>(
        builder: (context, provider, _) {
          final seconds = provider.secondsLeft;
          return SafeArea(
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(top: 12.h),
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: (seconds <= 5 ? Colors.red : Colors.black)
                        .withValues(alpha: .6),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '$seconds s',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  widget.item.isRack
                      ? 'Rack ${widget.item.rackName}'
                      : 'Rack: ${widget.item.rackName}',
                  style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.only(bottom: 28.h),
                  child: GestureDetector(
                    onTap: provider.busy || _shooting ? null : _shoot,
                    child: Container(
                      height: 72.r,
                      width: 72.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border:
                            Border.all(color: AppColors.primaryColor, width: 4),
                      ),
                      child: Icon(Icons.camera_alt,
                          size: 30.r, color: AppColors.primaryColor),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
}
