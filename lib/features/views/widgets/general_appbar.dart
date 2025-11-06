import 'package:flutter/material.dart';
import 'package:packer/constants/app_assets.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:svg_flutter/svg.dart';

class GeneralAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GeneralAppBar(
      {Key? key,
      this.middleWidget,
      this.trailingSvgAsset,
      this.backgroundColor,
      this.preferredSize = const Size.fromHeight(kToolbarHeight),
      this.leadingOnPressed,
      this.trailingOnPressed,
      this.needLeading = true,
      IconButton? leading})
      : super(key: key);

  @override
  final Size preferredSize;
  final void Function()? trailingOnPressed;
  final Widget? middleWidget;
  final void Function()? leadingOnPressed;
  final String? trailingSvgAsset;
  final Color? backgroundColor;
  final bool needLeading;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      leading: needLeading ? GestureDetector(
        onTap: () {
          // Handle leading icon tap
          navigatePop(context);
        },
        child: IconButton(
          icon: SvgPicture.asset(
            AppAssets.backArrow,
            height: 24.0,
          ),
          onPressed: leadingOnPressed,
        ),
      ) : SizedBox.shrink(),
      title: middleWidget,
      centerTitle: true,
      actions: [
        if (trailingSvgAsset != null)
          GestureDetector(
            onTap: () {
              // Handle trailing icon tap
            },
            child: IconButton(
              icon: SvgPicture.asset(
                trailingSvgAsset!,
                height: 24.0,
                width: 24.0,
                color: Colors.black,
              ),
              onPressed: trailingOnPressed,
            ),
          ),
      ],
    );
  }
}
