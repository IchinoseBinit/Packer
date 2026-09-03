import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Tappable box: opens the camera, shows [label] until a photo is taken,
/// then the preview. Tap again to retake.
class ImagePickBox extends StatelessWidget {
  const ImagePickBox({
    super.key,
    required this.label,
    required this.file,
    required this.onPicked,
  });

  final String label;
  final XFile? file;
  final ValueChanged<XFile> onPicked;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final res = await ImagePicker().pickImage(
          source: ImageSource.camera,
          imageQuality: 50,
        );
        if (res != null) onPicked(res);
      },
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: file == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_outlined, color: Colors.grey),
                  const SizedBox(height: 6),
                  Text(label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey)),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(file!.path), fit: BoxFit.cover),
              ),
      ),
    );
  }
}
