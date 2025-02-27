import 'package:flutter/material.dart';
import 'package:packer/features/views/widgets/document_list.dart';
import 'package:packer/features/views/widgets/general_appbar.dart';
import 'package:packer/constants/app_constants.dart';

class DocumentListScreen extends StatelessWidget {
  const DocumentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void Function()? onTap; // give a function to it
    return Scaffold(
      appBar:
          GeneralAppBar(middleWidget: Text("Documents"), trailingSvgAsset: ""),
      body: Padding(
        padding: AppConstants.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your Linked Documents",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                    fontWeight: FontWeight.normal,
                  ),
            ),
            DocumentList(
              onTap: onTap,
            ),
          ],
        ),
      ),
    );
  }
}
