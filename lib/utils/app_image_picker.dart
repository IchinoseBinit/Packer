import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

class AppImagePicker {
  static final ImagePicker _picker = ImagePicker();

  static Future<XFile?> pickImage(BuildContext context) async {
    return await showModalBottomSheet<XFile?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),

      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: Wrap(
              children: [
                Text(
                  "Select Image Source to upload",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () async {
                    final file = await _picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 50,
                    );
                    Navigator.pop(context, file);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () async {
                    final file = await _picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 50,
                    );
                    Navigator.pop(context, file);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}
