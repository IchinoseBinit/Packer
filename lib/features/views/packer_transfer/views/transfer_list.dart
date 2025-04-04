import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/date_formatter.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/packer_transfer/model/transfer_model.dart';
import 'package:packer/features/views/packer_transfer/provider/packer_transfer_provider.dart';
import 'package:provider/provider.dart';

class TransferList extends StatefulWidget {
  const TransferList({super.key});

  @override
  State<TransferList> createState() => _TransferListState();
}

class _TransferListState extends State<TransferList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer List'),
      ),
      body: Consumer<HomeProvider>(builder: (context, provider, child) {
        Provider.of<PackerTransferProvider>(context, listen: false)
            .setRole(provider.user.role);
        print("user role: ${provider.user.role}");

        return FutureBuilder(
            future: Provider.of<PackerTransferProvider>(context, listen: false)
                .fetchTransferList(context),
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
              final transferList =
                  Provider.of<PackerTransferProvider>(context).transferList;
              if (transferList.isEmpty) {
                return const Center(
                  child: Text('No transfer items available'),
                );
              }
              return ListView.builder(
                itemCount: transferList.length,
                padding: EdgeInsets.all(16.w),
                itemBuilder: (context, index) {
                  final data = transferList[index];
                  return TransferNotificationCard(
                    callback: () {
                      // Handle item tap
                      Provider.of<PackerTransferProvider>(context,
                              listen: false)
                          .onDetailsTaped(context, data);
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

class TransferNotificationCard extends StatelessWidget {
  final TransferModel transferItem;
  final Color primaryColor;
  final VoidCallback? callback;

  const TransferNotificationCard({
    Key? key,
    required this.transferItem,
    required this.primaryColor,
    this.callback,
  }) : super(key: key);

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
                        "Transfer Request",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        'Source: ${transferItem.source} → Destination: ${transferItem.destination}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey[700]),
                      ),
                      Text(
                        'Status: ${transferItem.status}',
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
