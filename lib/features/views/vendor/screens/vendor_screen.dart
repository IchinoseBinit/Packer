import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/features/views/vendor/widgets/vendor_card_widget.dart';
import 'package:packer/features/views/widgets/general_text_field.dart';
import 'package:provider/provider.dart';
import '../providers/vendor_provider.dart';

class VendorScreen extends StatefulWidget {
  const VendorScreen({super.key});

  @override
  State<VendorScreen> createState() => _VendorScreenState();
}

class _VendorScreenState extends State<VendorScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final provider = Provider.of<VendorProvider>(context, listen: false);
    //  only fetch if already on their
    if (provider.vendorData == null) {
      Provider.of<VendorProvider>(context, listen: false).fetchVendors();
    }

    // Rebuild search field to toggle clear icon
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Provider.of<VendorProvider>(context, listen: false).fetchVendors();
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = Provider.of<VendorProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text("Vendors")),
      body: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          children: [
            // Search Bar with Clear Button
            GeneralTextField(
              controller: _searchController,
              textInputType: TextInputType.text,
              validate: () {
                return null;
              },
              textInputAction: TextInputAction.done,
              onChanged: provider.searchVendors,
              hintText: "Search vendors by name or company...",
            ),

            SizedBox(height: 16.h),

            // Vendor List Section with Pull-to-Refresh
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: colorScheme.primary,
                child: Consumer<VendorProvider>(
                  builder: (context, vendorProvider, _) {
                    switch (vendorProvider.state) {
                      case VendorState.loading:
                        return const Center(child: CircularProgressIndicator());
                      case VendorState.error:
                        return Center(
                          child: Text(
                            'Error: ${vendorProvider.errorMessage}',
                            style: TextStyle(color: colorScheme.error),
                          ),
                        );
                      case VendorState.loaded:
                        final vendors = vendorProvider.filteredVendors;
                        if (vendors.isEmpty) {
                          return const Center(child: Text("No vendors found."));
                        }

                        return ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: vendors.length,
                          separatorBuilder: (_, __) => SizedBox(height: 2.h),
                          itemBuilder: (context, index) {
                            final vendor = vendors[index];
                            return VendorCardWidget(
                              vendor: vendor,
                              onTap: () => Navigator.of(context).pop(vendor),
                            );
                          },
                        );
                      default:
                        return Center(
                          child: Text(
                            "Press refresh to load vendors",
                            style: theme.textTheme.bodyMedium,
                          ),
                        );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
