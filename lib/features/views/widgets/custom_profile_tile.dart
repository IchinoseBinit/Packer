import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomProfileListTile extends StatelessWidget {
  final String profileImage;
  final String name;
  final String id;
  final String phoneNumber;

  const CustomProfileListTile({
    super.key,
    required this.profileImage,
    required this.name,
    required this.id,
    required this.phoneNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 45.h,
            child: Image.asset(
              profileImage,
            ),
          ),
          SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
                Text(phoneNumber),
                SizedBox(height: 2.0), // Add space between ID and phone number
                Text(
                  'ID: $id',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
