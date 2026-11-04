class ReceiptScannedItem {
  final String name;
  double quantity;
  String unit;
  String category;
  double? estimatedPrice;
  bool isSelected;

  ReceiptScannedItem({
    required this.name,
    required this.quantity,
    this.unit = 'pcs',
    this.category = 'Other',
    this.estimatedPrice,
    this.isSelected = true,
  });

  factory ReceiptScannedItem.fromMap(Map<String, dynamic> map) {
    return ReceiptScannedItem(
      name: map['name']?.toString() ?? '',
      quantity: (map['quantity'] is num) ? (map['quantity'] as num).toDouble() : 1.0,
      unit: map['unit']?.toString() ?? 'pcs',
      category: map['category']?.toString() ?? 'Other',
      estimatedPrice: map['estimated_price'] != null ? (map['estimated_price'] as num).toDouble() : null,
      isSelected: map['selected'] != false,
    );
  }
}
