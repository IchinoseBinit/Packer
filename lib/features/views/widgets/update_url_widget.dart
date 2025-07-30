import 'package:flutter/material.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/enum/environment_config.dart';
import 'package:packer/features/views/widgets/custom_url.dart';


class UpdateUrlWidget extends StatefulWidget {
  const UpdateUrlWidget({super.key});

  @override
  State<UpdateUrlWidget> createState() => _UpdateUrlWidgetState();
}

class _UpdateUrlWidgetState extends State<UpdateUrlWidget> {
  final TextEditingController _controller = TextEditingController();

  void _openBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter Custom Base URL"),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Base URL",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await CustomUrlManager.setCustomUrl(_controller.text);
                // await AppUrls.init(); // Refresh the URL
                Navigator.pop(context);
                setState(() {}); // Refresh UI if needed
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
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
