import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/features/views/cleanliness/models/cleanliness_item.dart';
import 'package:packer/features/views/cleanliness/providers/cleanliness_provider.dart';
import 'package:packer/features/views/cleanliness/widgets/cleanliness_capture_screen.dart';
import 'package:provider/provider.dart';

class CleanlinessScreen extends StatefulWidget {
  const CleanlinessScreen({super.key});

  @override
  State<CleanlinessScreen> createState() => _CleanlinessScreenState();
}

class _CleanlinessScreenState extends State<CleanlinessScreen> {
  late final CleanlinessProvider _provider =
      context.read<CleanlinessProvider>();

  @override
  void initState() {
    super.initState();
    Future.microtask(_provider.getReport);
  }

  @override
  void dispose() {
    _provider.cancelItem(); // kills any countdown left running
    super.dispose();
  }

  /// Tapping an item starts its own 15s window and opens the camera. The
  /// countdown runs inside the capture screen and closes it on expiry.
  void _openItem(CleanlinessItem item) {
    _provider.startItem(item);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CleanlinessCaptureScreen(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CleanlinessProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Cleanliness')),
          body: provider.reportState.when(
            idle: () => const SizedBox.shrink(),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e) => _errorView(e, provider),
            success: (report) => report.all.isEmpty
                ? _emptyView(provider)
                : _listView(report, provider),
          ),
        );
      },
    );
  }

  Widget _errorView(String error, CleanlinessProvider provider) => Center(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48.r, color: Colors.grey),
              SizedBox(height: 12.h),
              Text(error, textAlign: TextAlign.center),
              SizedBox(height: 12.h),
              ElevatedButton.icon(
                onPressed: provider.getReport,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );

  Widget _emptyView(CleanlinessProvider provider) => RefreshIndicator(
        onRefresh: provider.getReport,
        child: ListView(
          children: [
            SizedBox(height: .3.sh),
            const Center(child: Text('No cleanliness items today')),
          ],
        ),
      );

  Widget _thumb(CleanlinessItem item) {
    if (item.isRack || item.imageUrl == null) {
      return Container(
        height: 48.r,
        width: 48.r,
        color: Colors.grey.shade200,
        child: Icon(item.isRack ? Icons.shelves : Icons.inventory_2,
            color: Colors.grey),
      );
    }
    return CachedNetworkImage(
      imageUrl: item.imageUrl!,
      height: 48.r,
      width: 48.r,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.inventory_2, color: Colors.grey),
      ),
    );
  }

  Widget _listView(CleanlinessReport report, CleanlinessProvider provider) {
    final items = report.all;
    final pending = report.pending.length;
    return RefreshIndicator(
      onRefresh: provider.getReport,
      child: ListView.separated(
        padding: EdgeInsets.all(12.r),
        itemCount: items.length + 1,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
              child: Text(
                pending == 0
                    ? 'All items completed'
                    : 'Tap an item to photograph it — '
                        '${report.cleanlinessTime}s per item ($pending left)',
                style: TextStyle(fontSize: 13.sp, color: Colors.grey),
              ),
            );
          }
          final item = items[i - 1];
          final done = provider.results[item.itemId] ??
              (item.isCompleted ? CleanlinessResult.uploaded : null);
          return ListTile(
            enabled: !item.isCompleted && !provider.busy,
            onTap: item.isCompleted ? null : () => _openItem(item),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: _thumb(item),
            ),
            title: Text(item.name),
            subtitle: Text(item.isRack ? 'Rack' : item.rackName),
            trailing: done != null
                ? Icon(
                    done == CleanlinessResult.uploaded
                        ? Icons.check_circle
                        : Icons.remove_circle_outline,
                    color: done == CleanlinessResult.uploaded
                        ? Colors.green
                        : Colors.grey,
                  )
                : Icon(Icons.camera_alt, color: Colors.grey.shade600),
          );
        },
      ),
    );
  }
}
