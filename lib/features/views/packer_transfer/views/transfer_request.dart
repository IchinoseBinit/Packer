import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/controllers/services/date_formatter.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/packer_transfer/model/transfer_request_model.dart';
import 'package:packer/features/views/packer_transfer/provider/packer_transfer_provider.dart';
import 'package:provider/provider.dart';

class TransferRequestList extends StatefulWidget {
  const TransferRequestList({super.key});

  @override
  State<TransferRequestList> createState() => _TransferRequestListState();
}

class _TransferRequestListState extends State<TransferRequestList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Request List'),
      ),
      body: Consumer<HomeProvider>(builder: (context, provider, child) {
        return FutureBuilder(
            future: Provider.of<PackerTransferProvider>(context, listen: false)
                .fetchInventoryTransferRequestList(context),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }
              final transferRequestList =
                  Provider.of<PackerTransferProvider>(context)
                      .transferRequestList;
              if (transferRequestList.isEmpty) {
                return const Center(
                  child: Text('No transfer items available'),
                );
              }
              return ListView.builder(
                itemCount: transferRequestList.length,
                padding: EdgeInsets.all(16.w),
                primary: false,
                itemBuilder: (context, index) {
                  final data = transferRequestList[index];
                  return TransferRequestCard(
                    callback: () {
                      // Handle item tap
                      Provider.of<PackerTransferProvider>(context,
                              listen: false)
                          .onRequestDetailsTaped(context, data);
                    },
                    transferItem: data,
                    primaryColor: Theme.of(context).primaryColor,
                  );
                },
              );

              // return Center(
              //   child: Text('Transfer List Page'),
              // );
            });
      }),
    );
  }
}

class TransferRequestCard extends StatelessWidget {
  final InventoryTransferRequestModel transferItem;
  final Color primaryColor;
  final VoidCallback? callback;

  const TransferRequestCard({
    super.key,
    required this.transferItem,
    required this.primaryColor,
    this.callback,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: primaryColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: primaryColor,
                  child: const Icon(Icons.near_me, color: Colors.white),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Transfer Request (${transferItem.status})",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        '${transferItem.sourceStore} → ${transferItem.destinationStore}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey[700]),
                      ),
                      Text(
                        'Requested at: ${DateFormatter().formatTimestamp(transferItem.createdAt ?? '')}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (callback != null) ...[
              SizedBox(height: 12.h),
              const Divider(),
              SizedBox(height: 12.h),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () {
                    callback?.call();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    child: Text(
                      'Details',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
