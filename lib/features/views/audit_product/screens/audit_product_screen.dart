import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/features/views/audit_product/models/audi_type_enum.dart';
import 'package:packer/features/views/audit_product/providers/stock_audit_provider.dart';
import 'package:packer/features/views/audit_product/widgets/audit_product_list.dart';
import 'package:packer/features/views/stock_verification/model/store_model.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:packer/utils/confirm_dialog.dart';
import 'package:provider/provider.dart';

class AuditProductScreen extends StatefulWidget {
  const AuditProductScreen({super.key, this.preselectedStore});

  final Store? preselectedStore;

  @override
  State<AuditProductScreen> createState() => _AuditProductScreenState();
}

class _AuditProductScreenState extends State<AuditProductScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  String? _auditType;
  bool? _isCompleted;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() {
    return context.read<StockAuditProvider>().loadStockAudit(
          auditType: _auditType,
          isCompleted: _isCompleted,
          search: _searchController.text,
        );
  }

  /// Tap a chip → set/clear filter, then reload from API.
  Future<void> _onAuditTypeSelected(String? value) {
    setState(() => _auditType = value);
    return _load();
  }

  /// Called when leaving the screen while every product is audited.
  /// Confirms first, then marks the audit complete and pops.
  Future<void> _completeAndPop() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Complete audit',
      message: 'All products are audited. Mark this audit as complete?',
      confirmText: 'Complete',
      cancelText: 'Cancel',
    );
    if (confirmed != true) return;
    if (!mounted) return;

    await context.read<StockAuditProvider>().completeAudit(context);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StockAuditProvider>();
    final needsComplete =
        provider.allProductsDone && !provider.isAuditCompleted;

    return PopScope(
      // intercept the back gesture only while a completion is pending
      canPop: !needsComplete,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _completeAndPop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Stock Audit'),
          centerTitle: false,
          actions: [
            _AuditProgressAction(
              completed: provider.completedProducts,
              expected: provider.expectedProducts,
              showComplete: needsComplete,
              onComplete: _completeAndPop,
            ),
          ],
        ),
        bottomNavigationBar: needsComplete
            ? Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: GeneralElevatedButton(
                  onPressed: _completeAndPop,
                  title: 'Complete Audit',
                ),
              )
            : null,
        body: Column(
          children: [
            _AuditTypeChips(
              selected: _auditType,
              onSelected: _onAuditTypeSelected,
            ),
            Expanded(
              child: AuditProductList(onRefresh: _load),
            ),
          ],
        ),
      ),
    );
  }
}

/// AppBar action: shows `completed/expected` progress and, once everything is
/// audited, a "Complete" button that finalises the audit.
class _AuditProgressAction extends StatelessWidget {
  const _AuditProgressAction({
    required this.completed,
    required this.expected,
    required this.showComplete,
    required this.onComplete,
  });

  final int? completed;
  final int? expected;
  final bool showComplete;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    if (expected == null) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${completed ?? 0}/$expected',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (showComplete)
          TextButton(
            onPressed: onComplete,
            child: const Text('Complete'),
          )
        else
          SizedBox(width: 12.w),
      ],
    );
  }
}

/// Horizontal, single-select audit-type filter chips ("All" clears the filter).
class _AuditTypeChips extends StatelessWidget {
  const _AuditTypeChips({required this.selected, required this.onSelected});

  /// Currently active [AuditType.value], or null for "All".
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        children: [
          _chip(label: 'All', value: null),
          for (final type in AuditType.values)
            _chip(label: type.name, value: type.value),
        ],
      ),
    );
  }

  Widget _chip({required String label, required String? value}) {
    final isSelected = selected == value;
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        // re-tapping the active chip clears back to "All"
        onSelected: (_) => onSelected(isSelected ? null : value),
      ),
    );
  }
}
