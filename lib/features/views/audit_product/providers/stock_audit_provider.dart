import 'package:flutter/material.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/audit_product/models/audit_status_enum.dart';
import 'package:packer/features/views/audit_product/models/stock_audit_model.dart';
import 'package:packer/features/views/audit_product/repos/stock_audit_repo.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/utils/async_state.dart';
import 'package:provider/provider.dart';

/// Outcome of feeding a scanned code into the active audit session.
enum AuditScanResult { ok, duplicate, invalid }

class StockAuditProvider with ChangeNotifier {
  AsyncState<StockAuditPage> state = AsyncState.idle();

  final List<AuditProductModel> _items = [];
  int? _auditId;
  bool _hasNext = false;
  int _nextPage = 1;
  bool _isLoadingMore = false;
  bool _isLoading = false;

  // session-complete flag (set by completeAudit, not part of the page payload)
  bool _auditCompleted = false;

  // active filters (reused by loadMore / refresh)
  int? _storeId;
  String? _auditType;
  bool? _isCompleted;

  // audit types discovered from responses → drives the filter chips
  final Set<String> _seenAuditTypes = {};

  List<AuditProductModel> get items => List.unmodifiable(_items);
  int? get auditId => _auditId;
  bool get hasNext => _hasNext;
  bool get isLoadingMore => _isLoadingMore;

  int? get storeId => _storeId;
  String? get auditType => _auditType;
  bool? get isCompleted => _isCompleted;
  List<String> get auditTypes => _seenAuditTypes.toList()..sort();

  // progress comes straight from the latest page → refresh updates it
  int? get completedProducts => state.data?.completedProducts;
  int? get expectedProducts => state.data?.expectedProducts;
  bool get isAuditCompleted => _auditCompleted;

  /// True once every product in the session has been audited
  /// (completed count exactly matches the expected count).
  bool get allProductsDone =>
      expectedProducts != null &&
      expectedProducts! > 0 &&
      completedProducts == expectedProducts;

  /// Load page 1 with the given filters (replaces the list).
  Future<void> loadStockAudit({
    required BuildContext context,
    String? auditType,
    bool? isCompleted,
    String? search,
  }) async {
    context.read<HomeProvider>().fetchpackerSummary();

    if (_isLoading) return; // ignore concurrent reloads (e.g. double refresh)
    _isLoading = true;

    _storeId = storeId;
    _auditType = auditType;
    _isCompleted = isCompleted;

    _items.clear();
    _nextPage = 1;
    _hasNext = false;
    state = AsyncState.loading();
    notifyListeners();

    try {
      final response = await StockAuditRepo.getStockAudit(
        storeId: _storeId,
        auditType: _auditType,
        isCompleted: _isCompleted,
        page: 1,
      );
      _absorb(response);
      state = AsyncState.success(response);
    } catch (e) {
      state = AsyncState.error(e.toString());
    } finally {
      _isLoading = false;
      _auditCompleted =
          context.read<HomeProvider>().packerSummary?.auditStatus ==
              AuditStatusEnum.completed;
      notifyListeners();
    }
  }

  /// Append the next page (infinite scroll).
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasNext) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await StockAuditRepo.getStockAudit(
        storeId: _storeId,
        auditType: _auditType,
        isCompleted: _isCompleted,
        page: _nextPage,
      );
      _absorb(response);
    } catch (_) {
      // silent — user can scroll again to retry
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void _absorb(StockAuditPage response) {
    _items.addAll(response.products);
    _auditId = response.auditId;
    _hasNext = response.hasNextPage;
    _nextPage = response.page + 1;
    for (final p in response.products) {
      if (p.auditType.isNotEmpty) _seenAuditTypes.add(p.auditType);
    }
  }

  /// Re-fetch page 1 with the current filters (used after a submit).
  Future<void> refresh(BuildContext context) => loadStockAudit(
        context: context,
        auditType: _auditType,
        isCompleted: _isCompleted,
      );

  /// Mark the whole audit session complete. Returns true on success.
  Future<bool> completeAudit(BuildContext context) async {
    final auditId = _auditId;
    if (auditId == null) {
      showToast("Missing audit context");
      return false;
    }
    if (_auditCompleted) return true; // already done — don't re-post

    showLoading(context);
    try {
      await StockAuditRepo.completeAudit(auditId: auditId);
      _auditCompleted = true;
      removeLoading(context);
      await Provider.of<HomeProvider>(context, listen: false)
          .fetchpackerSummary();
      showToast("Audit marked complete");
      notifyListeners();
      return true;
    } catch (e) {
      removeLoading(context);
      showToast("Failed to complete audit: ${e.toString()}");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Scan session (one product at a time)
  // ---------------------------------------------------------------------------
  AuditProductModel? _scanProduct;
  final Set<String> _scannedTags = {};

  AuditProductModel? get scanProduct => _scanProduct;
  Set<String> get scannedTags => Set.unmodifiable(_scannedTags);

  /// Tags the backend expects for the product being scanned.
  List<String> get expectedTags =>
      _scanProduct?.units
          ?.map((u) => u.tag ?? '')
          .where((t) => t.isNotEmpty)
          .toList() ??
      const [];

  bool isExpected(String tag) => expectedTags.contains(tag);
  bool isScanned(String tag) => _scannedTags.contains(tag);
  bool get allScanned =>
      expectedTags.isNotEmpty && _scannedTags.length >= expectedTags.length;

  /// Begin a fresh scan session for [product].
  void startScanSession(AuditProductModel product) {
    _scanProduct = product;
    _scannedTags.clear();
    notifyListeners();
  }

  /// Feed a scanned code into the session.
  AuditScanResult addScan(String tag) {
    final code = tag.trim();
    if (!isExpected(code)) return AuditScanResult.invalid;
    if (!_scannedTags.add(code)) return AuditScanResult.duplicate;
    notifyListeners();
    return AuditScanResult.ok;
  }

  /// POST the scanned tags. Refreshes the list and returns true on success.
  Future<bool> submitAudit(BuildContext context) async {
    final product = _scanProduct;
    final auditId = _auditId;
    if (product == null || auditId == null) {
      showToast("Missing audit context");
      return false;
    }

    showLoading(context);
    try {
      await StockAuditRepo.submitAuditItem(
        auditId: auditId,
        productId: product.productId,
        auditType: product.auditType,
        scannedTags: _scannedTags.toList(),
      );
      removeLoading(context);
      showToast("Audit submitted successfully");
      _scanProduct = null;
      _scannedTags.clear();
      await refresh(context);
      return true;
    } catch (e) {
      removeLoading(context);
      showToast("Failed to submit audit: ${e.toString()}");
      return false;
    }
  }
}
