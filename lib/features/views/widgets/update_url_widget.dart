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
  String? _selectedUrl;

  final List<String> baseUrlOptions = [
    'http://103.187.8.105:8000',
    'https://Fasto.com.np',
  ];

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
                const Text("Select a Base URL"),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedUrl,
                  items: baseUrlOptions
                      .map((url) => DropdownMenuItem(
                            value: url,
                            child: Text(url, style: TextStyle(fontSize: 10.sp)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedUrl = value;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "Base URL",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 40.h),
                GeneralElevatedButton(
                  onPressed: () async {
                    if (_selectedUrl != null && _selectedUrl!.isNotEmpty) {
                      DioClient().updateBaseUrl(_selectedUrl!);
                      AppUrls.setBaseUrl(_selectedUrl!);
                    }
                    Navigator.pop(context);
                    setState(() {
                      _selectedUrl = null;
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
        _selectedUrl = null; // Reset selection if sheet dismissed
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
