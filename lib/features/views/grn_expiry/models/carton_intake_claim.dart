/// Response of `POST /api/carton-intake/claim/`.
class CartonIntakeClaim {
  final String grnItemId;
  final String sessionId;
  final String name;
  final String mrp;
  final String packSize;
  final int remainingUnits;

  const CartonIntakeClaim({
    required this.grnItemId,
    required this.sessionId,
    required this.name,
    required this.mrp,
    required this.packSize,
    required this.remainingUnits,
  });

  factory CartonIntakeClaim.fromJson(Map<String, dynamic> json) {
    final product = (json['product'] as Map?) ?? const {};
    return CartonIntakeClaim(
      grnItemId: json['grn_item_id'].toString(),
      sessionId: json['session_id']?.toString() ?? '',
      name: product['name']?.toString() ?? '',
      mrp: product['mrp']?.toString() ?? '',
      packSize: product['pack_size']?.toString() ?? '',
      remainingUnits: int.tryParse('${product['remaining_units']}') ?? 0,
    );
  }
}
