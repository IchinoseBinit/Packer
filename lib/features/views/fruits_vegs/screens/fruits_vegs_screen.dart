import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/features/views/auth/model/user.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/fruits_vegs/providers/fruits_vegs_provider.dart';
import 'package:packer/features/views/fruits_vegs/widgets/fruits_vegs_list.dart';
import 'package:packer/features/views/fruits_vegs/widgets/store_picker_sheet.dart';
import 'package:packer/features/views/stock_verification/model/store_model.dart';
import 'package:provider/provider.dart';

class FruitsVegsScreen extends StatefulWidget {
  final Store? preselectedStore;

  const FruitsVegsScreen({
    super.key,
    this.preselectedStore,
  });

  @override
  State<FruitsVegsScreen> createState() => _FruitsVegsScreenState();
}

class _FruitsVegsScreenState extends State<FruitsVegsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  Store? _selectedStore;

  UserRole get userRole => context.read<HomeProvider>().user.role;

  @override
  void initState() {
    super.initState();
    _selectedStore = widget.preselectedStore;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    // load first tab
    Future.microtask(() => _loadForIndex(_tabController.index));
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    _loadForIndex(_tabController.index);
  }

  void _loadForIndex(int index) async {
    //
    if (_selectedStore == null && userRole == UserRole.productChecker) {
      // if store is not selected and user is product checker, open store picker sheet
      await StorePickerSheet().open(
        context: context,
        selectedStore: _selectedStore,
        onStoreSelected: (store) {
          setState(() => _selectedStore = store);
          // load data for selected store
          _loadForIndex(index);
        },
      );
      return;
    }

    context.read<FruitsVegsProvider>().getFruitsVegsData(
          context,
          checkedProducts: index == 1,
          storeId: _selectedStore?.id,
          date: _selectedDate,
        );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null) return;
    setState(() => _selectedDate = picked);
    _loadForIndex(_tabController.index);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fruits and Vegs'),
        centerTitle: false,
        actions: [
          if (userRole == UserRole.productChecker) ...[
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(
                  '${_selectedDate.month}-${_selectedDate.day}',
                ),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                ),
              ),
            ),
            IconButton(
              tooltip: _selectedStore == null
                  ? 'Select store'
                  : 'Store: ${_selectedStore?.name}',
              onPressed: () async {
                await StorePickerSheet().open(
                  context: context,
                  selectedStore: _selectedStore,
                  onStoreSelected: (store) {
                    setState(() => _selectedStore = store);
                    // reload data for selected store
                    _loadForIndex(_tabController.index);
                  },
                );
              },
              icon: Icon(
                Icons.storefront_outlined,
                color: _selectedStore != null
                    ? AppColors.primaryColor
                    : Colors.grey[600],
              ),
            ),
          ],
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.h),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
            child: Container(
              height: 44.h,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: EdgeInsets.all(4.r),
                isScrollable: false,
                dragStartBehavior: DragStartBehavior.start,
                indicator: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(9.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Theme.of(context).colorScheme.onPrimary,
                unselectedLabelColor:
                    Theme.of(context).colorScheme.onSurfaceVariant,
                labelStyle: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Damaged'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          FruitsVegsList(
            key: const ValueKey('all'),
            checkedProducts: false,
            selectedDate: _selectedDate,
            storeId: _selectedStore?.id,
          ),
          FruitsVegsList(
            key: const ValueKey('checked'),
            checkedProducts: true,
            selectedDate: _selectedDate,
            storeId: _selectedStore?.id,
          ),
        ],
      ),
    );
  }
}
