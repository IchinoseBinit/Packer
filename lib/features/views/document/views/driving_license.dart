import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:packer/features/views/widgets/general_appbar.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:packer/constants/app_assets.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:svg_flutter/svg_flutter.dart';

class DrivingLicenseSelection extends StatefulWidget {
  const DrivingLicenseSelection({super.key});

  @override
  State<DrivingLicenseSelection> createState() =>
      _DrivingLicenseSelectionState();
}

class _DrivingLicenseSelectionState extends State<DrivingLicenseSelection> {
  List<String> citizenshipPhotoPaths =
      []; // List to store citizenship photo paths

  Future<void> _pickCitizenshipImage() async {
    final picker = ImagePicker();
    try {
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final appDir = await getTemporaryDirectory();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
        final filePath = '${appDir.path}/$fileName';

        final File imageFile = File(pickedFile.path);
        final savedFile = await imageFile.copy(filePath);
        setState(() {
          citizenshipPhotoPaths.add(savedFile.path);
        });
        print('license image saved: ${savedFile.path}');
      }
    } catch (e) {
      print('Error picking license image: $e');
    }
  }

  void _removeCitizenshipPhoto(int index) {
    setState(() {
      citizenshipPhotoPaths.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(middleWidget: Container(), trailingSvgAsset: ""),
      body: Padding(
        padding: AppConstants.padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              height: 300.h,
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "DRIVING LICENSE",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(
                      height: 5.h,
                    ),
                    if (citizenshipPhotoPaths.isNotEmpty)
                      SizedBox(
                        height: 100.h,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: citizenshipPhotoPaths.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  margin: EdgeInsets.symmetric(horizontal: 8.w),
                                  child: Image.file(
                                      File(citizenshipPhotoPaths[index])),
                                ),
                                Positioned(
                                  top: 5.h,
                                  right: 5.w,
                                  child: CircleAvatar(
                                    backgroundColor:
                                        Colors.grey.withOpacity(0.8),
                                    radius: 12,
                                    child: IconButton(
                                      icon: Icon(Icons.close, size: 16),
                                      color: Colors.white,
                                      onPressed: () {
                                        _removeCitizenshipPhoto(index);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    SizedBox(
                      height: citizenshipPhotoPaths.isNotEmpty ? 10.h : 0,
                    ),
                    InkWell(
                      onTap: () {
                        _pickCitizenshipImage();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        width: 200.w,
                        height: 45.h,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SvgPicture.asset(AppAssets.camera),
                            Text(
                              "License Photo",
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: AppColors.backgroundColor,
                                    fontWeight: FontWeight.normal,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 10.h,
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: citizenshipPhotoPaths.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text('License Photo ${index + 1}'),
                            leading:
                                Image.file(File(citizenshipPhotoPaths[index])),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GeneralElevatedButton(
              title: "Done!",
              isDisabled: citizenshipPhotoPaths.isEmpty,
              onPressed: () async {
                if (citizenshipPhotoPaths.isNotEmpty) {
                  for (final path in citizenshipPhotoPaths) {
                    print('Saved photo: $path');
                  }

                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
