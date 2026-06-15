import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:packer/features/views/fruits_vegs/models/can_be_eaten_enum.dart';
import 'package:packer/features/views/low_stock/model/product_model.dart';

class ShowUnitsInfo {
  /// Show a bottom sheet with list of units and their tags for the given product model
  static Future<Units?> show({
    required BuildContext context,
    required ProductModel productModel,
  }) async {
    // show a bottom sheet with list of units and their tags
    return await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        productModel.productName,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.red),
                    ),
                  ],
                ),
                const Divider(),
                Flexible(
                  child: (productModel.units == null ||
                          productModel.units!.isEmpty)
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text('No units available.'),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: productModel.units!.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final unit = productModel.units![index];
                            // try to read unit name defensively
                            final tagName = unit.tag ?? unit.toString();
                            // collect every non-null detail of the unit
                            final details = <String>[
                              if (unit.stockDate != null)
                                "Stock Date: ${unit.stockDate}",
                              if (unit.ripenessCategory != null)
                                "Ripeness: ${unit.ripenessCategory!.name}",
                              if (unit.ripenessScore != null)
                                "Score: ${unit.ripenessScore!.score}",
                              if (unit.assessedBy != null &&
                                  unit.assessedBy!.isNotEmpty)
                                "Assessed by: ${unit.assessedBy}",
                              if (unit.assessedAt != null)
                                "Assessed at: ${DateFormat('MMM d, yyyy · h:mm a').format(unit.assessedAt!)}",
                            ];

                            return InkWell(
                              onTap: () => Navigator.of(context).pop(unit),
                              child: Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tagName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          ...details.map(
                                            (detail) => Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 4.0),
                                              child: Text(
                                                detail,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (unit.canBeEaten != null &&
                                              unit.canBeEaten!.isNotEmpty)
                                            _buildCanBeEaten(unit.canBeEaten!),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward_ios,
                                        size: 16),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build a "can be eaten" section showing the prediction for the next 5 days.
  /// Each entry maps to a day (Day 1 = today), color-coded by edibility.
  static Widget _buildCanBeEaten(List<CanBeEatenEnum> canBeEaten) {
    Color colorFor(CanBeEatenEnum e) {
      switch (e) {
        case CanBeEatenEnum.yes:
          return Colors.green;
        case CanBeEatenEnum.no:
          return Colors.red;
        case CanBeEatenEnum.cantSay:
          return Colors.orange;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Can be eaten (next 5 days):",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(canBeEaten.length, (i) {
              final value = canBeEaten[i];
              final color = colorFor(value);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  "Day ${i + 1}: ${value.name}",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
