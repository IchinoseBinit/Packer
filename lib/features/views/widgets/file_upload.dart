import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:packer/utils/compress_file.dart';
import 'package:provider/provider.dart';

Future<void> fileUpload(
  BuildContext context,
  int productId,
  int quantity, // new param for quantity
) async {
  final orderProvider = Provider.of<OrderProvider>(context, listen: false);
  final List<File> imageFiles = [];

  // Pick images exactly according to quantity
  for (int i = 0; i < quantity; i++) {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      final compressedFile =
          await FileHelper().compressFile(File(pickedFile.path));
      imageFiles.add(compressedFile);
    } else {
      // If user cancels before finishing required quantity
      showToast("You must capture all $quantity photos.");
      return;
    }
  }

  if (imageFiles.isEmpty) {
    showToast("Please upload at least one image");
    return;
  }

  if (context.mounted) showLoading(context);

  final textController = TextEditingController();
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Enter code to report damage",
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  hintText: "Report Damage",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20.h),
              GeneralElevatedButton(
                title: "Submit",
                onPressed: () async {
                  if (textController.text.trim() != 'Report Damage') {
                    showToast("Enter valid code.");
                    return;
                  }

                  if (imageFiles.isEmpty) {
                    showToast("No images captured to upload.");
                    return;
                  }

                  final result = await orderProvider.uploadImages(
                    imageFiles,
                    context,
                    productId.toString(),
                  );
                  if (result == true) {
                    removeLoading(context);
                    showToast("Images uploaded successfully");
                  } else {
                    showToast("Failed to upload images");
                  }
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
