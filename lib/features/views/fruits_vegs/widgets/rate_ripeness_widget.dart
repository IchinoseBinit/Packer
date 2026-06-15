import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/fruits_vegs/models/can_be_eaten_enum.dart';
import 'package:packer/features/views/fruits_vegs/models/ripeness_category_enum.dart';
import 'package:packer/features/views/fruits_vegs/models/ripeness_score.dart';
import 'package:packer/features/views/fruits_vegs/providers/fruits_vegs_provider.dart';
import 'package:packer/features/views/low_stock/model/product_model.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
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
  RipenessCategoryEnum? _assessment;
  RipenessScore? _score;
  final List<CanBeEatenEnum?> _canBeEaten = List.filled(5, null);

  @override
  Widget build(BuildContext context) {
    final canBeEatenOptions = CanBeEatenEnum.values.take(5).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Rate Ripeness')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //show product name and unit tag with image
              Row(
                children: [
                  CachedNetworkImage(
                    imageUrl: widget.productModel.imageUrl,
                    width: 140.w,
                    memCacheWidth: 100,
                    memCacheHeight: 100,
                    fit: BoxFit.contain,
                    errorWidget: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.image_not_supported),
                    ),
                    placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator.adaptive()),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.productModel.productName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Unit Tag: ${widget.unit.tag}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              Text(
                'Assessment',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: RipenessCategoryEnum.values.map((value) {
                  final selected = _assessment == value;
                  return ChoiceChip(
                    label: Text(value.name),
                    selected: selected,
                    onSelected: (_) => setState(() => _assessment = value),
                  );
                }).toList(),
              ),
              SizedBox(height: 12.h),
              Text(
                ' Ripeness Score',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: RipenessScore.values.asMap().entries.map((entry) {
                  final value = entry.value;
                  final selected = _score == value;
                  return ChoiceChip(
                    label: Text('${entry.key + 1}'),
                    selected: selected,
                    onSelected: (_) => setState(() => _score = value),
                  );
                }).toList(),
              ),
              SizedBox(height: 16.h),

              for (var i = 0; i < 5; i++) ...[
                Text(
                  i == 0
                      ? 'Can be eaten today?'
                      : 'Can be eaten on day ${i + 1}?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: canBeEatenOptions
                      .where((option) =>
                          option != CanBeEatenEnum.cantSay || i != 0)
                      .map((value) {
                    final selected = _canBeEaten[i] == value;
                    return FilterChip(
                      label: Text(value.name),
                      selected: selected,
                      onSelected: (isSelected) {
                        setState(() {
                          _canBeEaten[i] = isSelected ? value : null;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
              SizedBox(height: 8.h),
              //
              GeneralElevatedButton(
                onPressed: () {
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

                  //
                  context.read<FruitsVegsProvider>().assessFruitsVegsUnit(
                        context: context,
                        tagId: widget.unit.tag!,
                        assessment: _assessment!,
                        score: _score!,
                        canBeEaten: _canBeEaten.cast<CanBeEatenEnum>(),
                      );
                  //
                },
                title: "Submit Assessment",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
