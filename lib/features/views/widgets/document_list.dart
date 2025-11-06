import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:packer/constants/app_assets.dart';
import 'package:svg_flutter/svg.dart';

class DocumentList extends StatelessWidget {
  final List<String> titles = ["Driving License", "Citizenship Card", "Photos"];
  final List<String> subtitles = [
    "01-07-0145254",
    "02-07-0145254",
    "official ps"
  ];
  final List<String> routes = [
    "/driving_license",
    "/citizenship_card",
    "/select_photos",
  ];
  final void Function()? onTap;

  DocumentList({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300.h,
      child: ListView.builder(
        itemCount: titles.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            margin: EdgeInsets.all(5),
            padding: EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
                border: Border.all(
                  width: 1,
                  color: Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(10)),
            child: InkWell(
              onTap: () {
                context.push(routes[index]);
              },
              child: ListTile(
                leading: SvgPicture.asset(
                  AppAssets.document,
                  width: 55.w,
                  height: 55.h,
                ),
                title: Text(
                  titles[index],
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                subtitle: Text(
                  subtitles[index],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.normal,
                      ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
