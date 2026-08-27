import 'package:flutter_test/flutter_test.dart';
import 'package:packer/features/views/cleanliness/models/cleanliness_item.dart';

void main() {
  final json = {
    'success': true,
    'report_id': 1,
    'cleanliness_time': 20,
    'products': [
      {
        'item_id': 1,
        'product_id': 6174,
        'product_name': 'Pringles Cheesy Cheese Chips MRP 300',
        'product_image': '/media/src/images/product_images/aa_IEcxDxk.png',
        'rack_name': 'MAR-3-L-D-4-R',
        'is_completed': false,
      },
      {
        'item_id': 2,
        'product_id': 6037,
        'product_name': 'OKF Mix Berry Smoothie',
        'product_image': null,
        'rack_name': 'Stand-Fridge-4-L',
        'is_completed': true,
      },
    ],
    'racks': [
      {
        'item_id': 6,
        'rack_id': 872,
        'rack_name': 'WAR-E-D-5-R',
        'is_completed': false,
      },
    ],
  };

  test('parses products and racks', () {
    final report = CleanlinessReport.fromJson(json);

    expect(report.reportId, 1);
    expect(report.cleanlinessTime, 20);
    expect(report.products.length, 2);
    expect(report.racks.single.name, 'WAR-E-D-5-R');
    expect(report.racks.single.refId, 872);
    expect(report.racks.single.isRack, isTrue);

    final first = report.products.first;
    expect(first.itemId, 1);
    expect(first.refId, 6174);
    expect(first.rackName, 'MAR-3-L-D-4-R');
    expect(first.imageUrl,
        endsWith('/media/src/images/product_images/aa_IEcxDxk.png?w=400&h=400&q=80'));
    expect(report.products[1].imageUrl, isNull); // null image -> no url
  });

  test('run order is products then pending racks only', () {
    final report = CleanlinessReport.fromJson(json);
    expect(report.all.map((e) => e.itemId), [1, 2, 6]);
    expect(report.pending.map((e) => e.itemId), [1, 6]);
  });

  test('cleanliness_time falls back to the default when missing/invalid', () {
    expect(
      CleanlinessReport.fromJson({...json}..remove('cleanliness_time'))
          .cleanlinessTime,
      CleanlinessReport.defaultCleanlinessTime,
    );
    expect(
      CleanlinessReport.fromJson({...json, 'cleanliness_time': 0})
          .cleanlinessTime,
      CleanlinessReport.defaultCleanlinessTime,
    );
  });
}
