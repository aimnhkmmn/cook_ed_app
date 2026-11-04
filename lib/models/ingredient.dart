class Ingredient {
  final String name;
  final double amount;
  final String unit;
  final String category;

  Ingredient({
    required this.name,
    required this.amount,
    required this.unit,
    this.category = 'Other',
  });

  Ingredient copyWith({
    String? name,
    double? amount,
    String? unit,
    String? category,
  }) {
    return Ingredient(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'unit': unit,
      'category': category,
    };
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      name: map['name']?.toString() ?? '',
      amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : 1.0,
      unit: map['unit']?.toString() ?? 'pcs',
      category: map['category']?.toString() ?? 'Other',
    );
  }
}
