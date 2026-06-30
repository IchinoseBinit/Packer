import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/fruits_vegs/models/can_be_eaten_enum.dart';
import 'package:packer/features/views/fruits_vegs/models/ripeness_category_enum.dart';
import 'package:packer/features/views/fruits_vegs/models/ripeness_score.dart';
import 'package:packer/features/views/fruits_vegs/providers/fruits_vegs_provider.dart';
import 'package:packer/features/views/low_stock/model/product_model.dart';
import 'package:packer/features/views/order/widgets/ask_confirmation.dart';
import 'package:provider/provider.dart';

class RateRipenessWidget extends StatefulWidget {
  const RateRipenessWidget({
    super.key,
    required this.productModel,
    required this.unit,
  });

  final ProductModel productModel;
  final Units unit;

  @override
  State<RateRipenessWidget> createState() => _RateRipenessWidgetState();
}

class _RateRipenessWidgetState extends State<RateRipenessWidget> {
  static const Color _scaffoldBg = Color(0xffF5F6F8);
  static const Color _cardBg = Colors.white;
  static const Color _ink = Color(0xff1A1C1E);
  static const Color _muted = Color(0xff7A7F87);
  static const Color _line = Color(0xffE8EAED);

  static const Color _green = Color(0xff2E9E5B);
  static const Color _greenBg = Color(0xffE9F7EF);
  static const Color _red = Color(0xffE0354B);
  static const Color _redBg = Color(0xffFDEAED);
  static const Color _amber = Color(0xffB5851A);
  static const Color _amberBg = Color(0xffFBF1DC);

  RipenessCategoryEnum? _assessment;
  RipenessScore? _score;
  final List<CanBeEatenEnum?> _canBeEaten = List.filled(5, null);

  @override
  void initState() {
    super.initState();
    // prefill from existing unit assessment if present
    _assessment = widget.unit.ripenessCategory;
    _score = widget.unit.ripenessScore;
    final eaten = widget.unit.canBeEaten;
    if (eaten != null) {
      for (var i = 0; i < eaten.length && i < _canBeEaten.length; i++) {
        _canBeEaten[i] = eaten[i];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rate Ripeness',
              style: TextStyle(
                color: _ink,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            _productHeader(),
            SizedBox(height: 20.h),
            _assessmentSection(),
            SizedBox(height: 20.h),
            _scoreSection(),
            SizedBox(height: 20.h),
            _canBeEatenSection(),
          ],
        ),
      ),
      bottomNavigationBar: _submitBar(context),
    );
  }

  Widget _productHeader() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: _cardDecoration(),
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

  Widget _assessmentSection() {
    return _section(
      title: 'Assessment',
      subtitle: 'How does this unit look overall?',
      child: Row(
        children: RipenessCategoryEnum.values.map((value) {
          final selected = _assessment == value;
          final accent = value == RipenessCategoryEnum.ripe ? _green : _amber;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 10.w),
              child: GestureDetector(
                onTap: () => setState(() => _assessment = value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    color: selected ? accent.withValues(alpha: 0.10) : _cardBg,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: selected ? accent : _line,
                      width: selected ? 1.6 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(value.icon,
                          size: 26.sp, color: selected ? accent : _muted),
                      SizedBox(height: 8.h),
                      Text(
                        value.name,
                        style: TextStyle(
                          color: selected ? accent : _ink,
                          fontSize: 14.sp,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  bool get _isRaw => _assessment == RipenessCategoryEnum.raw;

  String _scoreLabel(int index) {
    const raw = [
      'Extremely Raw\n(धेरै काँचो)',
      'Raw\n(काँचो)',
      'Slightly Raw\n(थोरै काँचो)',
    ];
    const ripe = [
      'Slightly Ripe\n(थोरै पाकेको)',
      'Ripe\n(पाकेको)',
      'Overripe\n(धेरै पाकेको)'
    ];
    return (_isRaw ? raw : ripe)[index];
  }

  Widget _scoreSection() {
    return _section(
      title: _isRaw ? 'Rawness Score' : 'Ripeness Score',
      subtitle: _isRaw
          ? 'Rate how raw it is right now.'
          : 'Rate how ripe it is right now.',
      child: Row(
        children: RipenessScore.values.asMap().entries.map((entry) {
          final value = entry.value;
          final selected = _score == value;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 10.w),
              child: GestureDetector(
                onTap: () => setState(() => _score = value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      EdgeInsets.symmetric(vertical: 14.h, horizontal: 10.w),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primaryColor : _cardBg,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: selected ? AppColors.primaryColor : _line,
                      width: selected ? 1.6 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${entry.key + 1}',
                        style: TextStyle(
                          color: selected ? Colors.white : _ink,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _scoreLabel(entry.key),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.9)
                              : _muted,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _canBeEatenSection() {
    final options = CanBeEatenEnum.values.take(5).toList();

    //

    return _section(
      title: 'Edibility Forecast',
      subtitle: 'Can it be eaten over the next 5 days?',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < 5; i++)
            if (i == 0 ||
                _canBeEaten[i - 1] == CanBeEatenEnum.yes ||
                _canBeEaten[i - 1] == CanBeEatenEnum.cantSay) ...[
              if (i != 0) Divider(height: 22.h, color: _line),
              Text(
                i == 0
                    ? 'Eaten today (आज खान मिल्छ)?'
                    : 'Can be eaten ${dayMapingEng(i)}, (${dayMappingNep(i)} खान मिल्छ)?',
                style: TextStyle(
                  color: _ink,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6.h),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: options
                          .where((o) => o != CanBeEatenEnum.cantSay || i != 0)
                          .map((value) => _eatChip(i, value))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ],
        ],
      ),
    );
  }

  dayMapingEng(int day) {
    switch (day) {
      case 0:
        return "today";
      case 1:
        return "tomorrow";
      case 2:
        return "Day 3";
      case 3:
        return "Day 4";
      case 4:
        return "Day 5";
      default:
        return "Day ${day + 1}";
    }
  }

  dayMappingNep(int day) {
    switch (day) {
      case 0:
        return "आज";
      case 1:
        return "भोलि";
      default:
        return "${day + 1} दिन पछि";
    }
  }

  Widget _eatChip(int day, CanBeEatenEnum value) {
    final selected = _canBeEaten[day] == value;
    late Color fg;
    late Color bg;
    switch (value) {
      case CanBeEatenEnum.yes:
        fg = _green;
        bg = _greenBg;
        break;
      case CanBeEatenEnum.no:
        fg = _red;
        bg = _redBg;
        break;
      case CanBeEatenEnum.cantSay:
        fg = _amber;
        bg = _amberBg;
        break;
    }
    return GestureDetector(
      onTap: () {
        setState(() {
          final newValue = selected ? null : value;
          _canBeEaten[day] = newValue;
          // answer changed -> reset every later day, they re-answer fresh
          for (var j = day + 1; j < _canBeEaten.length; j++) {
            _canBeEaten[j] = null;
          }
          // once it can't be eaten on a day, every later day can't either
          if (newValue == CanBeEatenEnum.no) {
            for (var j = day + 1; j < _canBeEaten.length; j++) {
              _canBeEaten[j] = CanBeEatenEnum.no;
            }
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? bg : _cardBg,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selected ? fg : _line,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check_rounded, size: 14.sp, color: fg),
              SizedBox(width: 4.w),
            ],
            Text(
              value.name,
              style: TextStyle(
                color: selected ? fg : _muted,
                fontSize: 13.sp,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _submitBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      decoration: const BoxDecoration(
        color: _cardBg,
        border: Border(top: BorderSide(color: _line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52.h,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _onSubmit(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            child: Text(
              'Submit Assessment',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onSubmit(BuildContext context) async {
    if (_assessment == null) {
      showToast("Please select an assessment");
      return;
    }
    if (_score == null) {
      showToast("Please select a ripeness score");
      return;
    }
    if (_canBeEaten.isEmpty || _canBeEaten.contains(null)) {
      showToast("Please answer all 'Can be eaten' questions");
      return;
    }

    // ask for confirmation
    final confirmation =
        await AskConfirmation.show(context, title: "Submit this assessment?");

    if (!confirmation) {
      return;
    }

    context.read<FruitsVegsProvider>().assessFruitsVegsUnit(
          context: context,
          tagId: widget.unit.tag!,
          assessment: _assessment!,
          score: _score!,
          canBeEaten: _canBeEaten.cast<CanBeEatenEnum>(),
        );
  }

  Widget _section({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _ink,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            subtitle,
            style: TextStyle(
              color: _muted,
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 14.h),
          child,
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: _cardBg,
      borderRadius: BorderRadius.circular(18.r),
      border: Border.all(color: _line),
      boxShadow: [
        BoxShadow(
          color: const Color(0xff1A1C1E).withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
