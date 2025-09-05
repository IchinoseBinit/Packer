import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void showProductTagSheet(BuildContext context,
    {required List<String> remainingTags,
    required List<String> completedTags}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: .8.sh,
    ),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8.h,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (remainingTags.isNotEmpty) ...[
              Text(
                "Remaining Tags",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: remainingTags.length,
                  itemBuilder: (context, index) {
                    return Text(remainingTags[index],
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w400,
                                ));
                  },
                  separatorBuilder: (context, index) {
                    return SizedBox(height: 12.h);
                  },
                ),
              ),
            ],
            if (remainingTags.isNotEmpty && completedTags.isNotEmpty) ...[
              // 8.h
              SizedBox(height: 8.h),
            ],
            if (completedTags.isNotEmpty) ...[
              Text(
                "Completed Tags",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: completedTags.length,
                  itemBuilder: (context, index) {
                    return Text(completedTags[index],
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.green,
                                ));
                  },
                  separatorBuilder: (context, index) {
                    return SizedBox(height: 12.h);
                  },
                ),
              ),
            ],
            
          ],
        ),
      );
    },
  );
}
