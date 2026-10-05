// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/meter_reading/providers/meter_reading_provider.dart';
import 'package:packer/features/views/meter_reading/widgets/meter_photo_box.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:provider/provider.dart';

/// Photographs the electricity meter and sends the units shown on it.
/// Pops after a successful upload.
class MeterReadingScreen extends StatefulWidget {
  const MeterReadingScreen({super.key});

  @override
  State<MeterReadingScreen> createState() => _MeterReadingScreenState();
}

class _MeterReadingScreenState extends State<MeterReadingScreen> {
  // Resolved here rather than lazily, so dispose() never reaches for an
  // ancestor that is already gone.
  late final MeterReadingProvider _provider;
  final _formKey = GlobalKey<FormState>();
  final _unitsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _provider = context.read<MeterReadingProvider>();
    // Drives the step ticks and the Submit button's enabled state.
    _unitsController.addListener(_onUnitsChanged);
  }

  @override
  void dispose() {
    _unitsController.removeListener(_onUnitsChanged);
    _unitsController.dispose();
    _provider.reset();
    super.dispose();
  }

  void _onUnitsChanged() => setState(() {});

  bool get _hasUnits => _unitsController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_provider.image == null) {
      showToast('Take a photo of the meter reading');
      return;
    }
    showLoading(context, label: 'Uploading...');
    try {
      await _provider.submit(_unitsController.text);
      removeLoading(context);
      showToast('Meter reading submitted');
      navigatePop(context, true);
    } catch (e) {
      removeLoading(context);
      showToast(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeterReadingProvider>();
    final hasPhoto = provider.image != null;
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Meter Reading',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.backgroundColor,
        surfaceTintColor: AppColors.backgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 20.h),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _banner(),
                    SizedBox(height: 20.h),
                    _stepHeader(1, 'Meter photo', done: hasPhoto),
                    SizedBox(height: 10.h),
                    MeterPhotoBox(
                      file: provider.image,
                      onPicked: provider.setImage,
                    ),
                    SizedBox(height: 22.h),
                    _stepHeader(2, 'Current reading', done: _hasUnits),
                    SizedBox(height: 10.h),
                    _readingField(),
                  ],
                ),
              ),
            ),
          ),
          _submitBar(hasPhoto: hasPhoto, busy: provider.busy),
        ],
      ),
    );
  }

  /// Soft header that says what the screen is for in one line.
  Widget _banner() {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.homeScreenTopBgColor.withValues(alpha: .70),
            AppColors.homeScreenTopBgColor.withValues(alpha: .18),
          ],
        ),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Container(
            height: 42.r,
            width: 42.r,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Icon(
              Icons.electric_meter,
              color: AppColors.primaryColor,
              size: 22.r,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Electricity meter',
                  style: TextStyle(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Photograph the meter, then type the units it shows.',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: AppColors.homeScreenDimTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Numbered step that ticks green once that step is filled in.
  Widget _stepHeader(int number, String title, {required bool done}) {
    return Row(
      children: [
        Container(
          height: 22.r,
          width: 22.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? AppColors.green700 : AppColors.primaryColor,
          ),
          child: done
              ? Icon(Icons.check, size: 14.r, color: Colors.white)
              : Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  /// Large numeric entry — the reading is the one value on this screen, so it
  /// gets digit-sized type rather than the standard small field.
  Widget _readingField() {
    return TextFormField(
      controller: _unitsController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        LengthLimitingTextInputFormatter(12),
      ],
      onFieldSubmitted: (_) => _submit(),
      style: TextStyle(
        fontSize: 26.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
      validator: (value) {
        final units = (value ?? '').trim();
        if (units.isEmpty) return 'Please enter the current meter units';
        if (double.tryParse(units) == null) return 'Units must be a number';
        return null;
      },
      decoration: InputDecoration(
        hintText: '0',
        hintStyle: TextStyle(
          fontSize: 26.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          color: Colors.grey.shade400,
        ),
        helperText: 'Enter the number exactly as shown on the meter',
        helperStyle: TextStyle(
          fontSize: 11.sp,
          color: AppColors.homeScreenDimTextColor,
        ),
        suffixIcon: Padding(
          padding: EdgeInsets.only(right: 14.w),
          child: Text(
            'units',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.homeScreenDimTextColor,
            ),
          ),
        ),
        suffixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        filled: true,
        fillColor: AppColors.fillColor,
        enabledBorder: _fieldBorder(AppColors.borderColor),
        focusedBorder: _fieldBorder(AppColors.primaryColor, width: 1.4),
        errorBorder: _fieldBorder(Theme.of(context).colorScheme.error),
        focusedErrorBorder: _fieldBorder(
          Theme.of(context).colorScheme.error,
          width: 1.4,
        ),
      ),
    );
  }

  OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// Pinned footer so Submit stays reachable with the keyboard open.
  Widget _submitBar({required bool hasPhoto, required bool busy}) {
    final ready = hasPhoto && _hasUnits;
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        border: Border(top: BorderSide(color: AppColors.borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 48.h,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: busy ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  ready ? AppColors.primaryColor : Colors.grey.shade400,
              disabledBackgroundColor: Colors.grey.shade400,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            icon: Icon(Icons.cloud_upload_outlined, size: 18.r),
            label: Text(
              'Submit Reading',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
