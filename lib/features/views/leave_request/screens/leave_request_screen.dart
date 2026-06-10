import 'package:flutter/material.dart';
import 'package:packer/features/views/leave_request/models/leave_request_model.dart';
import 'package:packer/features/views/leave_request/providers/leave_request_provider.dart';
import 'package:packer/features/views/leave_request/widgets/add_leave_request.dart';
import 'package:provider/provider.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  @override
  initState() {
    super.initState();
    // fetch leave request status
    Future.microtask(() =>
        Provider.of<LeaveRequestProvider>(context, listen: false)
            .getLeaveRequest());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Leave'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => AddLeaveRequest.show(context),
          ),
        ],
      ),
      body: Consumer<LeaveRequestProvider>(
        builder: (context, provider, _) {
          return provider.leaveState.when(
            idle: () => const SizedBox.shrink(),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Something went wrong',
                        style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 8),
                    Text(e, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => provider.getLeaveRequest(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    )
                  ],
                ),
              ),
            ),
            success: (data) {
              if (data.results.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.beach_access,
                            size: 56, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('No leave requests yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => AddLeaveRequest.show(context),
                          child: const Text('Request Leave'),
                        )
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => provider.getLeaveRequest(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: data.results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final leaveRequest = data.results[index];
                    final status = (leaveRequest.status ?? '').toLowerCase();
                    Color statusColor;
                    if (status.contains('approved')) {
                      statusColor = Colors.green;
                    } else if (status.contains('rejected')) {
                      statusColor = Colors.red;
                    } else {
                      statusColor = Colors.orange;
                    }

                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                      child: ListTile(
                        onTap: () => showDetail(context, leaveRequest),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        title: Text(
                          leaveRequest.reason ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'From ${leaveRequest.startDate} to ${leaveRequest.endDate}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            leaveRequest.status ?? '',
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<dynamic> showDetail(BuildContext context, LeaveRequest leaveRequest) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                leaveRequest.reason ?? '',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text('From ${leaveRequest.startDate} to ${leaveRequest.endDate}'),
              const SizedBox(height: 8),
              Text('Status: ${leaveRequest.status ?? ''}'),
            ],
          ),
        ),
      ),
    );
  }
}
