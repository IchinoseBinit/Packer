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
import 'package:packer/features/views/home/widgets/tasks_list_card.dart';
import 'package:packer/features/views/shift_clock/providers/shift_clock_provider.dart';
import 'package:packer/features/views/shift_clock/utils/shift_clock_logic.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';

/// Logout used by the profile screen and the shift complete screen.
///
/// Packers who checked in must check out first by scanning the warehouse QR
/// (the backend refuses while a stock audit is owed); then the app goes
/// offline and logs out. A driver (who reaches this only from the shift
/// complete screen - the driver profile has its own plain logout) checks out
/// without a QR, as they checked in. Completes when the logout has finished
/// or stopped.
Future<void> logoutWithCheckout(BuildContext context) async {
  final homeProvider = Provider.of<HomeProvider>(context, listen: false);
  final tasks = homeProvider.packerSummary?.tasks;
  
  if (tasks != null) {
    final incompleteTasks = tasks.where((t) => t.status != 'completed').toList();
    if (incompleteTasks.isNotEmpty) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const Text(
                'Incomplete Tasks',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  color: Color(0xff1A1C1E),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You must complete all pending tasks before logging out. Tap on a task to view details.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Poppins',
                  color: Color(0xff7A7F87),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              const TasksListCard(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffF01045),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Got it, go back',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }
  }

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

  // Packers must checkout (scan warehouse QR) before logout.
  //
  // Being online is not the test: the shift clock takes them offline at the
  // grace mark and leaves the shift open, so a packer stopped at the blocking
  // screen reads as offline while still being very much checked in. Going by
  // the switch alone, the check-out below was skipped and the plain logout
  // that followed closed nothing - and the next sign-in was handed the same
  // stopped shift straight back, with no way out of it. An open shift is what
  // has to be checked out of, whichever side of the grace mark it is on.
  final role = Provider.of<HomeProvider>(context, listen: false).user.role;
  final onShift = Provider.of<ShiftClockProvider>(context, listen: false)
          .state
          ?.hasSession ??
      false;
  if ((role == UserRole.packer) && (isOnline == true.toString() || onShift)) {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Checkout Required'),
        content: const Text('You need to checkout before logout. '
            'Scan the waitlist QR to continue.'),
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

  // A driver goes online with the switch alone, no store QR, so there is no
  // check-in to read and no QR to scan - but they still have to be checked
  // out: going offline leaves their shift running on the server. Stop here
  // when it is refused over a transfer in hand (loaded for them and not yet
  // received), as a packer's failed QR check-out does. Any other refusal lets
  // the logout go on (driverCheckoutRefusalStops).
  if (role == UserRole.driver) {
    showLoading(context);
    final clock = Provider.of<ShiftClockProvider>(context, listen: false);
    String? refused;
    try {
      final checkedOut = await Provider.of<HomeProvider>(context, listen: false)
          .driverCheckout();
      if (!checkedOut) refused = 'Failed to checkout. Please try again.';
    } catch (ex) {
      // The server words the transfer refusal only in its message, so look
      // at the driver's transfers to tell it from the rest - but only for a
      // refusal: with no answer there is nothing to tell apart.
      final transfers = isCheckoutRefusal(ex) && !isTransferInHandRefusal(ex)
          ? await clock.readDriverTransfers()
          : null;
      if (driverCheckoutRefusalStops(ex, transfersInHand: transfers)) {
        refused = ex.toString();
      }
    }
    if (!context.mounted) return;
    removeLoading(context);
    if (refused != null) {
      await ErrorHandler.alertDialog(context, refused);
      return;
    }
  }

  showLoading(context);
  await Provider.of<HomeProvider>(context, listen: false)
      .updatepackerStatus(false, context, showErrorDialog: false);

  final value = await AuthController().logout();
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
