import 'package:flutter/material.dart';
import 'package:packer/features/views/stock_verification/model/store_model.dart';
import 'package:packer/features/views/stock_verification/provider/stock_verification_provider.dart';
import 'package:provider/provider.dart';

class StorePickerSheet {
  //
  Future<void> open({
    required BuildContext context,
    required Function(Store) onStoreSelected,
    required Store? selectedStore,
  }) async {
    final stockProvider =
        Provider.of<StockVerificationProvider>(context, listen: false);
    try {
      await stockProvider.fetchStores();
    } catch (_) {}

    final List<Store> stores =
        ((stockProvider.storeList as List<Store>?) ?? const <Store>[]).toList();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: false,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      builder: (sheetContext) {
        return PopScope(
          canPop: false,
          child: SafeArea(
            child: FractionallySizedBox(
              heightFactor: 0.9,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Select Store',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: stores.isEmpty
                          ? const Center(child: Text('No stores found'))
                          : ListView.separated(
                              itemCount: stores.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final store = stores[index];
                                final storeName = store.name;
                                final selected =
                                    selectedStore?.name == storeName;

                                return Material(
                                  color: selected
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.08)
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceVariant
                                          .withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(14),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () {
                                      onStoreSelected(store);
                                      Navigator.pop(sheetContext);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  storeName.isEmpty
                                                      ? 'Store ${index + 1}'
                                                      : storeName,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  selected
                                                      ? 'Currently selected'
                                                      : 'Tap to select',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.color
                                                        ?.withOpacity(0.7),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(
                                            selected
                                                ? Icons.check_circle
                                                : Icons
                                                    .arrow_forward_ios_rounded,
                                            size: 18,
                                            color: selected
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                : Theme.of(context)
                                                    .iconTheme
                                                    .color,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
