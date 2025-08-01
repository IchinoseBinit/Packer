import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/enum/environment_config.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';

class UpdateUrlWidget extends StatefulWidget {
  const UpdateUrlWidget({super.key});

  @override
  State<UpdateUrlWidget> createState() => _UpdateUrlWidgetState();
}

class _UpdateUrlWidgetState extends State<UpdateUrlWidget> {
  final TextEditingController _middleController = TextEditingController();

  final String _prefix = "http://192.168.80.";
  final String _suffix = ":8000";

  @override
  void dispose() {
    _middleController.dispose();
    super.dispose();
  }

  void _openBottomSheet() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Enter Base URL Segment"),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(_prefix, style: TextStyle(fontSize: 10.sp)),
                    Expanded(
                      child: TextField(
                        controller: _middleController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'X.X',
                          border: OutlineInputBorder(),
                        ),
                        style: TextStyle(fontSize: 10.sp),
                      ),
                    ),
                    Text(_suffix, style: TextStyle(fontSize: 10.sp)),
                  ],
                ),
                SizedBox(height: 40.h),
                GeneralElevatedButton(
                  onPressed: () {
                    if (_middleController.text.isNotEmpty) {
                      final fullUrl =
                          "$_prefix${_middleController.text.trim()}$_suffix";
                      DioClient().updateBaseUrl(fullUrl);
                      AppUrls.setBaseUrl(fullUrl);
                    }
                    Navigator.pop(context);
                    setState(() {
                      _middleController.clear();
                    });
                  },
                  title: 'Save',
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      setState(() {
        _middleController.clear();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return EnvironmentConfig.type == EnvironmentType.staging
        ? ElevatedButton(
            onPressed: _openBottomSheet,
            child: const Text("Update Base URL"),
          )
        : const SizedBox.shrink();
  }
}
