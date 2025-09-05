import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:mobile_scanner/src/mobile_scanner_controller.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/scanner/views/base_scan_screen.dart';
import 'package:packer/features/views/warehouse_carton/provider/warehouse_carton_provider.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';


/// Scanner screen for warehouse carton
/// 
/// it extends BaseScanScreen and implements all the required functions
/// 
/// it has additional parameters to handle different states
/// 
/// forProduct: true if we are in product scan state
/// forRack: true if we are in rack scan state
/// productId: product id for product scan state
/// rack: rack name for rack scan state
/// 
/// if forProduct is false and forRack is false, it means it is called from dashboard
/// and it will scan carton code
/// 
/// if forProduct is true, also need product id,
/// 
/// if forRack is true, rack is not null then we need to check if the scanned code is of rack
/// 
/// if forRack is true, rack is null then we update rack for carton product
class WarehouseCartonScanner extends BaseScanScreen {
  final bool forProduct;
  final bool forRack;
  final int? productId;
  final String? rack;

  WarehouseCartonScanner({
    super.key,
    this.forProduct = false,
    this.forRack = false,
    this.productId = 0,
    this.rack = '',
  }) : super(
          scanTitle: forProduct
              ? 'Product Scanner'
              : forRack
                  ? 'Rack Scanner'
                  : 'Carton Scanner',
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          showBackButton: true,
          showFlash: true,
        );

  bool hasScanned = false;

  @override
  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller) {
    // show info sheet for product tag if state is product scan
    if (forProduct) {
      return FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        onPressed: () async {
          Provider.of<WarehouseCartonProvider>(context, listen: false)
              .showProductSheet(context);
        },
        child: const Icon(Icons.info, color: Colors.white),
      );
    }
    return null;
  }

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    try {
      // if code is already scanned, return
      if (hasScanned) return;
      hasScanned = true;
      // stop scanner and vibrate
      controller.stop();
      HapticFeedback.heavyImpact();

      // scan product code if state is product scan
      if (forProduct) {
        final result =
            await Provider.of<WarehouseCartonProvider>(context, listen: false)
                .scanProductCode(context, productId!, code);
        // if response is success, start scanner and reset hasScanned
        if (result.success) {
          controller.start();
          hasScanned = false;
          // show toast if message is not null
          if (result.message != null) {
            showToast(result.message!);
          }
        } else {
          // if response is not success, start scanner and reset hasScanned
          if (result.message != null) {
            handleInvalidCode(context, controller, code, result.message);
          } else {
            controller.start();
            hasScanned = false;
          }
        }
      } else if (forRack) {
        // scan rack code if state is rack scan
        if (!code.contains("rack")) {
          handleInvalidCode(context, controller, code);
          return;
        }
        // if rack is not empty, check if scanned code contains rack name
        if (rack?.isNotEmpty ?? false) {
          if (!code.contains(rack ?? '')) {
            handleInvalidCode(context, controller, code);
            return;
          }
        }
        final result =
            await Provider.of<WarehouseCartonProvider>(context, listen: false)
                .updateRackForCartonProduct(context, code);

        // if response is success, start scanner and reset hasScanned
        if (result.success) {
          controller.start();
          hasScanned = false;
          // show toast if message is not null
          if (result.message != null) {
            showToast(result.message!);
          }
        } else {
          // if response is not success, start scanner and reset hasScanned
          if (result.message != null) {
            handleInvalidCode(context, controller, code, result.message);
          } else {
            controller.start();
            hasScanned = false;
          }
        }
      } else {
        final result =
            await Provider.of<WarehouseCartonProvider>(context, listen: false)
                .scanCartonCode(context, code);

        // if response is success, start scanner and reset hasScanned
        if (result.success) {
          controller.start();
          hasScanned = false;
          // show toast if message is not null
          if (result.message != null) {
            showToast(result.message!);
          }
        } else {
          // if response is not success, start scanner and reset hasScanned
          if (result.message != null) {
            handleInvalidCode(context, controller, code, result.message);
          } else {
            controller.start();
            hasScanned = false;
          }
        }
      }
    } catch (e) {
      handleInvalidCode(context, controller, code, e.toString());
    }
  }

  @override
  void onDispose(MobileScannerController controller) {
    // TODO: implement onDispose
  }

  // handles invalid code and shows alert dialog after ok button is pressed
  // 
  // it calls start scanner and reset hasScanned
  void handleInvalidCode(
      BuildContext context, MobileScannerController controller, String code,
      [String? message]) {
    ShowAlertDialog(
      disableBackground: true,
      body: Text(message ?? "Invalid QR ${detectQrMessage(code)}"),
      okFunc: () {
        Navigator.pop(context);
        controller.start();
      },
    ).showAlertDialog(context);
    hasScanned = false;
  }

  // sets the message for scanner screen when the screen is created
  @override
  void onScreenCreated(BuildContext context) {
    Provider.of<WarehouseCartonProvider>(context, listen: false)
        .setMessageForScanner(context, forProduct, forRack);
  }
}
