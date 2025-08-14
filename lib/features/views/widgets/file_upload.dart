import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:packer/utils/compress_file.dart';
import 'package:provider/provider.dart';

Future<void> fileUpload(BuildContext context, int productId) async {
  final orderProvider = Provider.of<OrderProvider>(context, listen: false);
  final List<File> imageFiles = [];
  bool addMore = true;

  // Pick images until user stops
  while (addMore) {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      final compressedFile =
          await FileHelper().compressFile(File(pickedFile.path));
      imageFiles.add(compressedFile);
    } else {
      break;
    }

    // Ask user if they want to take another photo
    addMore = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Add More Photos?"),
            content: const Text("Do you want to capture another photo?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("No"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Yes"),
              ),
            ],
          ),
        ) ??
        false;
  }

  // No image case
  if (imageFiles.isEmpty) {
    showToast("Please upload at least one image");
  }

  if (context.mounted) showLoading(context);

  final textController = TextEditingController();
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Enter code to report damage",
              style: TextStyle(fontSize: 20)),
          const SizedBox(height: 10),
          TextField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: "Product ID",
              border: OutlineInputBorder(),
            ),
          ),
          GeneralElevatedButton(
              title: "Submit",
              onPressed: () async {
                navigatePop(context);
                if (textController.text.trim() == 'Report Damage') {
                  final result = await orderProvider.uploadImages(
                      imageFiles, context, productId.toString());
                  result == true;
                } else {
                  showToast("Enter valid code.");
                }
              })
        ],
      ),
    ),
  );
}
