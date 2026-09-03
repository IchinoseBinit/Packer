import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:packer/features/views/grn_expiry/models/carton_intake_claim.dart';
import 'package:packer/features/views/grn_expiry/repo/grn_expiry_repo.dart';

/// One carton intake: claim from QR, then upload product photos.
///
/// First photo is the product. If it shows both MRP and expiry
/// ([firstHasBoth] == true) it is sent as both fields; otherwise a second
/// expiry-only photo is required.
class GrnExpiryProvider with ChangeNotifier {
  CartonIntakeClaim? claim;
  XFile? mrpPhoto;
  XFile? expiryPhoto;
  bool? firstHasBoth;
  bool busy = false;

  /// Throws AppException on used/expired/bad secret, not staff, not carton QR.
  Future<void> claimQr(String secret) async {
    claim = null;
    mrpPhoto = null;
    expiryPhoto = null;
    firstHasBoth = null;
    busy = true;
    notifyListeners();
    try {
      claim = await GrnExpiryRepo.claim(secret);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// Retaking the first photo invalidates the answer and the second photo.
  void setMrpPhoto(XFile f) {
    mrpPhoto = f;
    firstHasBoth = null;
    expiryPhoto = null;
    notifyListeners();
  }

  void setFirstHasBoth(bool v) {
    firstHasBoth = v;
    if (v) expiryPhoto = null;
    notifyListeners();
  }

  void setExpiryPhoto(XFile f) {
    expiryPhoto = f;
    notifyListeners();
  }

  /// Null when the form is complete, else the message to show.
  String? validate() {
    if (mrpPhoto == null) return 'Take a photo of the product';
    if (firstHasBoth == null) {
      return 'Confirm whether the photo shows MRP and expiry date';
    }
    if (firstHasBoth == false && expiryPhoto == null) {
      return 'Take a photo of the expiry date';
    }
    return null;
  }

  /// Throws on API failure so the caller can show it.
  Future<void> submit() async {
    busy = true;
    notifyListeners();
    try {
      await GrnExpiryRepo.uploadPhotos(
        grnItemId: claim!.grnItemId,
        sessionId: claim!.sessionId,
        mrpPhoto: mrpPhoto,
        expiryPhoto: firstHasBoth == true ? mrpPhoto : expiryPhoto,
      );
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
