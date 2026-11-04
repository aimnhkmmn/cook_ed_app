class PantryItem {
  final String id;
  final String userId;
  final String name;
  final String normalizedName;
  final String category;
  final double quantity;
  final String unit;
  final DateTime? expiryDate;
  final DateTime? createdAt;

  PantryItem({
    required this.id,
    required this.userId,
    required this.name,
    String? normalizedName,
    this.category = 'Other',
    required this.quantity,
    this.unit = 'pcs',
    this.expiryDate,
    this.createdAt,
  }) : normalizedName = normalizedName ?? name.trim().toLowerCase();

  PantryItem copyWith({
    String? id,
    String? userId,
    String? name,
    String? normalizedName,
    String? category,
    double? quantity,
    String? unit,
    DateTime? expiryDate,
    DateTime? createdAt,
  }) {
    return PantryItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'normalized_name': normalizedName,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'expiry_date': expiryDate?.toIso8601String(),
    };
  }

  factory PantryItem.fromMap(Map<String, dynamic> map) {
    return PantryItem(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      normalizedName: map['normalized_name']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Other',
      quantity: (map['quantity'] is num) ? (map['quantity'] as num).toDouble() : 0.0,
      unit: map['unit']?.toString() ?? 'pcs',
      expiryDate: map['expiry_date'] != null ? DateTime.tryParse(map['expiry_date'].toString()) : null,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
    );
  }
}
