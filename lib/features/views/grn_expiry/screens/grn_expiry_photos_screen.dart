// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/grn_expiry/providers/grn_expiry_provider.dart';
import 'package:packer/features/views/grn_expiry/widgets/image_pick_box.dart';
import 'package:packer/features/views/grn_expiry/widgets/photo_check_sheet.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:provider/provider.dart';

/// Photos step for one claimed carton. Pops `true` after a successful
/// upload, nothing on back.
class GrnExpiryPhotosScreen extends StatelessWidget {
  const GrnExpiryPhotosScreen({super.key});

  Future<void> _submit(BuildContext context, GrnExpiryProvider p) async {
    final error = p.validate();
    if (error != null) {
      showToast(error);
      return;
    }
    showLoading(context, label: 'Uploading...');
    try {
      await p.submit();
      removeLoading(context);
      showToast('Photos uploaded');
      navigatePop(context, true);
    } catch (e) {
      removeLoading(context);
      showToast(e.toString());
    }
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<GrnExpiryProvider>();
    final c = p.claim;
    return Scaffold(
      appBar: AppBar(title: const Text('Carton Intake')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c?.name ?? '',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _info('MRP', c?.mrp ?? ''),
            _info('Pack size', c?.packSize ?? ''),
            _info('Remaining units', '${c?.remainingUnits ?? 0}'),
            const SizedBox(height: 16),
            const Text('Take a photo of the product showing MRP and expiry'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ImagePickBox(
                    label: 'Product photo',
                    file: p.mrpPhoto,
                    onPicked: (f) async {
                      p.setMrpPhoto(f);
                      final hasBoth = await PhotoCheckSheet.show(context, f);
                      if (hasBoth != null) p.setFirstHasBoth(hasBoth);
                    },
                  ),
                ),
                if (p.firstHasBoth == false) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ImagePickBox(
                      label: 'Expiry photo',
                      file: p.expiryPhoto,
                      onPicked: p.setExpiryPhoto,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            GeneralElevatedButton(
              height: 44.h,
              title: 'Submit',
              onPressed: () {
                if (!p.busy) _submit(context, p);
              },
            ),
          ],
        ),
      ),
    );
  }
}
