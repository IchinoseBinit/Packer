import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/fruits_vegs/models/can_be_eaten_enum.dart';
import 'package:packer/features/views/fruits_vegs/providers/fruits_vegs_provider.dart';
import 'package:packer/features/views/low_stock/model/product_model.dart';
import 'package:packer/features/views/order/widgets/ask_confirmation.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:provider/provider.dart';

class CantSayVerificationWidget extends StatefulWidget {
  const CantSayVerificationWidget({
    super.key,
    required this.productModel,
    required this.unit,
  });

  final ProductModel productModel;
  final Units unit;

  @override
  State<CantSayVerificationWidget> createState() =>
      _CantSayVerificationWidgetState();
}

class _CantSayVerificationWidgetState extends State<CantSayVerificationWidget> {
  static const Color _scaffoldBg = Color(0xffF5F6F8);
  static const Color _cardBg = Colors.white;
  static const Color _ink = Color(0xff1A1C1E);
  static const Color _muted = Color(0xff7A7F87);
  static const Color _line = Color(0xffE8EAED);

  List<DayAssessment> _cantSayDays = [];
  late List<CanBeEatenEnum?> _canBeEaten;

  @override
  void initState() {
    super.initState();
    if (widget.unit.days != null) {
      _cantSayDays = widget.unit.days!
          .where((d) => d.canBeEaten == CanBeEatenEnum.cantSay)
          .toList();
    } else {
      _cantSayDays = [];
    }
    _canBeEaten = List.generate(_cantSayDays.length, (_) => null);
  }

  void _submit() async {
    if (_cantSayDays.isNotEmpty && _canBeEaten.contains(null)) {
      showToast("Please provide verification for all required days");
      return;
    }

    final confirmation = await AskConfirmation.show(
      context,
      title: "Are you sure you want to submit this verification?",
    );

    if (!confirmation) {
      return;
    }

    if (!mounted) return;

    context.read<FruitsVegsProvider>().assessCantSayUnit(
          context: context,
          tagId: widget.unit.tag!,
          canBeEaten: _canBeEaten.cast<CanBeEatenEnum>(),
        );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: _muted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: _ink,
          ),
        ),
      ],
    );
  }

  Widget _detailsSection() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Assessment Details",
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: _ink,
            ),
          ),
          SizedBox(height: 12.h),
          _detailRow("Assessment Date", widget.unit.assessmentDate ?? '-'),
          SizedBox(height: 8.h),
          _detailRow("Assessed By", widget.unit.assessedBy ?? '-'),
          SizedBox(height: 8.h),
          _detailRow("Can Be Eaten Today", widget.unit.canBeEatenToday?.name ?? '-'),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _line),
      ),
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: _ink,
            ),
          ),
          SizedBox(height: 16.h),
          child,
        ],
      ),
    );
  }

  Widget _productHeader() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Container(
            width: 76.w,
            height: 76.w,
            decoration: BoxDecoration(
              color: _scaffoldBg,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: _line),
            ),
            clipBehavior: Clip.antiAlias,
            child: CachedNetworkImage(
              imageUrl: widget.productModel.imageUrl,
              memCacheWidth: 200,
              memCacheHeight: 200,
              fit: BoxFit.contain,
              errorWidget: (context, error, stackTrace) => const Center(
                child: Icon(Icons.image_not_supported, color: _muted),
              ),
              placeholder: (context, url) => const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                ),
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.productModel.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ink,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_2_rounded,
                          size: 15.sp, color: AppColors.primaryColor),
                      SizedBox(width: 5.w),
                      Text(
                        widget.unit.tag ?? '-',
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBg,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cant Say Verification',
              style: TextStyle(
                color: _ink,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: 16.h),
            _productHeader(),
            SizedBox(height: 20.h),
            _detailsSection(),
            SizedBox(height: 20.h),
            if (_cantSayDays.isNotEmpty)
              _section(
                title: "Can it be eaten?",
                child: Column(
                  children: List.generate(_cantSayDays.length, (index) {
                    final day = _cantSayDays[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Day ${day.dayNumber} (${day.date})",
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                color: _muted,
                              ),
                            ),
                          ),
                          ...CanBeEatenEnum.values
                              .where((e) => e != CanBeEatenEnum.cantSay)
                              .map((e) {
                            final isSelected = _canBeEaten[index] == e;
                            return Padding(
                              padding: EdgeInsets.only(left: 8.w),
                              child: ChoiceChip(
                                label: Text(e.name),
                                selected: isSelected,
                                onSelected: (val) {
                                  if (val) {
                                    setState(() {
                                      _canBeEaten[index] = e;
                                    });
                                  }
                                },
                                selectedColor: e.name.toLowerCase() == 'yes'
                                    ? const Color(0xffE9F7EF)
                                    : const Color(0xffFDEAED),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? (e.name.toLowerCase() == 'yes'
                                          ? const Color(0xff2E9E5B)
                                          : const Color(0xffE0354B))
                                      : _ink,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                backgroundColor: _scaffoldBg,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  side: BorderSide(
                                    color: isSelected
                                        ? Colors.transparent
                                        : _line,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
        decoration: const BoxDecoration(
          color: _cardBg,
          border: Border(top: BorderSide(color: _line)),
        ),
        child: SafeArea(
          top: false,
          child: GeneralElevatedButton(
            onPressed: _cantSayDays.isEmpty
                ? () {
                    Navigator.pop(context); // Pop Bottom Sheet
                    Navigator.pop(context); // Pop ScanTagScreen
                  }
                : _submit,
            title: _cantSayDays.isEmpty ? 'Go Back' : 'Submit Verification',
          ),
        ),
      ),
    );
  }
}
