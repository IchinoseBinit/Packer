import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/enum/environment_config.dart';
import 'package:packer/features/views/widgets/custom_url.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';

class UpdateUrlWidget extends StatefulWidget {
  const UpdateUrlWidget({super.key});

  @override
  State<UpdateUrlWidget> createState() => _UpdateUrlWidgetState();
}

class _UpdateUrlWidgetState extends State<UpdateUrlWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
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
                const Text("Enter your Baseurl"),
                const SizedBox(height: 10),
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: "Base URL",
                    border: OutlineInputBorder(),
                  ),
                  style: TextStyle(fontSize: 10.sp),
                ),
                SizedBox(height: 40.h),
                GeneralElevatedButton(
                  onPressed: () async {
                    await CustomUrlManager.setCustomUrl(_controller.text);
                    await AppUrls
                        .init(); // Refresh the in-memory URL after saving

                    Navigator.pop(context);
                    setState(() {});
                  },
                  title: 'Save',
                ),
              ],
            ),
          ),
        );
      },
    );
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
