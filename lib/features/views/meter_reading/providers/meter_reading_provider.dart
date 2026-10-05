import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:packer/features/views/meter_reading/repo/meter_reading_repo.dart';

/// One electricity meter reading: the photo of the meter and the units shown
/// on it. Both are required by the API.
class MeterReadingProvider with ChangeNotifier {
  XFile? image;
  bool busy = false;

  void setImage(XFile file) {
    image = file;
    notifyListeners();
  }

  /// Clears the form so the next visit starts empty.
  void reset() {
    image = null;
    busy = false;
  }

  /// Throws on API failure so the caller can show it.
  Future<void> submit(String units) async {
    busy = true;
    notifyListeners();
    try {
      await MeterReadingRepo.submit(
        readingUnits: units.trim(),
        image: image!,
      );
      image = null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
