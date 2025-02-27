import 'package:flutter/material.dart';
import 'package:packer/controllers/extensions/num_extension.dart';

class AmountDisplay extends StatelessWidget {
  const AmountDisplay({super.key, required this.title, required this.value});
  final String title;
  final num value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: "$title: ",
        style: Theme.of(context).textTheme.bodyMedium,
        children: [
          TextSpan(
            text: "Rs. ${value.toIntStringConversion()}",
            style: Theme.of(context).textTheme.bodyLarge,
          )
        ],
      ),
    );
  }
}
