import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/controllers/services/validation_mixin.dart';
import 'package:url_launcher/url_launcher.dart';

callNumber(String number) async {
  if (ValidationMixin().validateMobileNumber(number) == null) {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: number,
    );
    await launchUrl(launchUri);
  } else {
    showToast("Not a valid number");
  }
}
