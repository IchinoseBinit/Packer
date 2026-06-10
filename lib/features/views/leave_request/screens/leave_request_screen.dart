import 'package:flutter/material.dart';
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
            error: (e) => Center(child: Text(e)),
            success: (data) => ListView.builder(
              itemCount: data.results.length,
              itemBuilder: (context, index) {
                final leaveRequest = data.results[index];
                return Card(
                  child: ListTile(
                    title: Text(leaveRequest.reason ?? ''),
                    subtitle: Text(
                        'From ${leaveRequest.startDate} to ${leaveRequest.endDate}'),
                    trailing: Text(leaveRequest.status ?? ''),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
