import 'package:flutter/material.dart';
import 'package:packer/features/views/vendor/models/vendor_model.dart';

class VendorCardWidget extends StatelessWidget {
  const VendorCardWidget({
    super.key,
    required this.vendor,
    required this.onTap,
  });

  final Vendors vendor;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Card(
        color: colorScheme.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              vendor.name.isNotEmpty ? vendor.name[0].toUpperCase() : "?",
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          title: Text(
            vendor.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            vendor.company,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
