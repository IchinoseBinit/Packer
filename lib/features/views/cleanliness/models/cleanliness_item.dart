import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/extensions/string_extension.dart';

/// `GET /staff/store-cleanliness/`
///
/// {
///   "success": true, "report_id": 1, "cleanliness_time": 15,
///   "products": [{item_id, product_id, product_name, product_image,
///                 rack_name, is_completed}],
///   "racks":    [{item_id, rack_id, rack_name, is_completed}]
/// }
class CleanlinessReport {
  final int reportId;

  /// Countdown length (seconds) for each item, set by the backend.
  final int cleanlinessTime;
  final List<CleanlinessItem> products;
  final List<CleanlinessItem> racks;

  static const int defaultCleanlinessTime = 15;

  CleanlinessReport({
    required this.reportId,
    required this.cleanlinessTime,
    required this.products,
    required this.racks,
  });

  factory CleanlinessReport.fromJson(Map<String, dynamic> json) {
    List<CleanlinessItem> parse(String key, bool isRack) =>
        (json[key] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map((e) => CleanlinessItem.fromJson(e, isRack: isRack))
            .toList();

    final time = int.tryParse(json['cleanliness_time'].toString());
    return CleanlinessReport(
      reportId: json['report_id'].toString().toInt(),
      cleanlinessTime:
          time != null && time > 0 ? time : defaultCleanlinessTime,
      products: parse('products', false),
      racks: parse('racks', true),
    );
  }

  /// Products first, then racks — the order they get scanned in.
  List<CleanlinessItem> get all => [...products, ...racks];

  List<CleanlinessItem> get pending =>
      all.where((e) => !e.isCompleted).toList();
}

class CleanlinessItem {
  final int itemId;
  final int refId; // product_id or rack_id
  final String name;
  final String? imageUrl;
  final String rackName;
  final bool isCompleted;
  final bool isRack;

  CleanlinessItem({
    required this.itemId,
    required this.refId,
    required this.name,
    required this.rackName,
    required this.isCompleted,
    required this.isRack,
    this.imageUrl,
  });

  factory CleanlinessItem.fromJson(
    Map<String, dynamic> json, {
    required bool isRack,
  }) {
    final image = json['product_image'].toString().toStringConversion();
    final rackName = json['rack_name'].toString().toStringConversion();
    return CleanlinessItem(
      itemId: json['item_id'].toString().toInt(),
      refId: (isRack ? json['rack_id'] : json['product_id']).toString().toInt(),
      name: isRack
          ? rackName
          : json['product_name'].toString().toStringConversion(),
      rackName: rackName,
      imageUrl: image.isEmpty
          ? null
          : "${AppUrls.imageUrl}$image?w=400&h=400&q=80",
      isCompleted: json['is_completed'].toString().toBool(false),
      isRack: isRack,
    );
  }
}
