import 'package:flutter/material.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/constants/secure_storage_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/secure_storage_helper.dart';
import 'package:packer/features/views/auth/model/user.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';

class CustomSwitch extends StatefulWidget {
  final double width;
  final double height;
  final bool fromWareHouse;
  final Function()? onPressed;

  const CustomSwitch({
    super.key,
    this.width = 115,
    this.height = 40,
    this.fromWareHouse = false,
    this.onPressed,
  });

  @override
  CustomSwitchState createState() => CustomSwitchState();
}

class CustomSwitchState extends State<CustomSwitch> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(builder: (_, value, __) {
      return AbsorbPointer(
        absorbing: _isProcessing,
        child: GestureDetector(
          onTap: () async {
            setState(() => _isProcessing = true);

            // scan

            // Packers must checkout (scan warehouse QR)
            // before logout.
            final isOnline = await SecureStorageHelper().readKey(
              key: SecureStorageConstants.isOnlineKey,
            );

            final needOnline = (value.user.role == UserRole.packer) &&
                isOnline != true.toString();

            //
            if (needOnline) {
              await showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Check-in Required'),
                  content:
                      const Text('You need to check in before getting login. '
                          'Scan the warehouse QR to continue.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );

              if (!context.mounted) return;

              final checkedOut = await navigate(context,
                  route: NavigationConstants.packerCheckoutScanRoute,
                  extra: {
                    "forOnlineStatus": true,
                  });

              // Abort logout if checkout was not completed.
              if (checkedOut != true) {
                if (mounted) setState(() => _isProcessing = false);
                return;
              }
              if (!context.mounted) return;

              await SecureStorageHelper().write(
                key: SecureStorageConstants.isOnlineKey,
                value: true.toString(),
              );
            }

            //
            showLoading(context);

            await value.toggleOnlineStatus(
              context,
              isFromWarehouse: widget.fromWareHouse,
              onPressed: widget.onPressed,
            );
            removeLoading(context);

            if (mounted) setState(() => _isProcessing = false);
          },
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.height / 2),
              color: value.isOnline ? Colors.green : Colors.grey,
            ),
            child: Stack(
              children: [
                Align(
                  alignment: value.isOnline
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      value.isOnline ? 'ONLINE' : 'OFFLINE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                AnimatedAlign(
                  alignment: value.isOnline
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: Container(
                    width: widget.height - 4,
                    height: widget.height - 4,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
