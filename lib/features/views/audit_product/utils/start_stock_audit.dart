import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/error_handler.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/audit_product/models/audit_status_enum.dart';
import 'package:packer/features/views/audit_product/repos/stock_audit_repo.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/order/widgets/ask_confirmation.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';

/// Opens the stock audit screen based on [packerSummary.auditStatus].
///
/// - [AuditStatusEnum.notCreated]: confirm, start the audit on the backend,
///   refresh the summary, then open the audit screen.
/// - any other status (ongoing / completed): the audit already exists, so it
///   navigates straight there without calling the start API.
Future<void> startStockAudit(BuildContext context) async {
  final status = context.read<HomeProvider>().packerSummary?.auditStatus;

  if (status != AuditStatusEnum.notCreated) {
    navigate(context, route: NavigationConstants.auditProductScreenRoute);
    return;
  }

  final isConfirmed = await AskConfirmation.show(
    context,
    title: 'Do you want to start audit?',
  );
  if (isConfirmed != true) return;
  if (!context.mounted) return;

  showLoading(context);
  try {
    await StockAuditRepo.startAudit();
    if (!context.mounted) return;
    await Provider.of<HomeProvider>(context, listen: false)
        .fetchpackerSummary();
    if (!context.mounted) return;
    removeLoading(context);
    navigate(context, route: NavigationConstants.auditProductScreenRoute);
  } catch (e) {
    if (!context.mounted) return;
    removeLoading(context);
    ErrorHandler.alertDialog(context, e, () => navigatePop(context));
  }
}
