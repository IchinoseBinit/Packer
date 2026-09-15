import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/constants/secure_storage_constants.dart';
import 'package:packer/controllers/api/error_handler.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/secure_storage_helper.dart';
import 'package:packer/features/views/auth/model/user.dart';
import 'package:packer/features/views/auth/provider/auth_provider.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/order/widgets/ask_confirmation.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';

/// Logout used by the profile screen and the shift complete screen.
///
/// Packers who checked in must check out first by scanning the warehouse QR
/// (the backend refuses while a stock audit is owed); then the app goes
/// offline and logs out. Completes when the logout has finished or stopped.
Future<void> logoutWithCheckout(BuildContext context) async {
  final isConfirmed = await AskConfirmation.show(
    context,
    title: 'Do you want to logout?',
  );

  if (isConfirmed != true) {
    return;
  }

  final isOnline = await SecureStorageHelper().readKey(
    key: SecureStorageConstants.isOnlineKey,
  );
  if (!context.mounted) return;

  // Packers must checkout (scan warehouse QR)
  // before logout.
  final role = Provider.of<HomeProvider>(context, listen: false).user.role;
  if ((role == UserRole.packer) && isOnline == true.toString()) {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Checkout Required'),
        content: const Text('You need to checkout before logout. '
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
    final checkedOut = await navigate(
      context,
      route: NavigationConstants.packerCheckoutScanRoute,
    );

    // Abort logout if checkout was not completed.
    if (checkedOut != true) {
      return;
    }
    if (!context.mounted) return;
  }

  showLoading(context);
  await Provider.of<HomeProvider>(context, listen: false)
      .updatepackerStatus(false, context, showErrorDialog: false);

  final value = await AuthController().logout();
  if (!context.mounted) return;
  removeLoading(context);
  Provider.of<HomeProvider>(context, listen: false).resetUser();
  if (value is bool) {
    navigateAndRemoveAll(context, route: NavigationConstants.loginRoute);
  } else {
    ErrorHandler.alertDialog(
        context, "Something went wrong. Please try again later", () {
      navigatePop(context);
    });
  }
}
