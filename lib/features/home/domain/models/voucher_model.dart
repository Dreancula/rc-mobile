class VoucherModel {
  final String id;
  final String name;
  final double discountPercent;
  final bool isActive;
  final DateTime createdAt;
  final int? pointCost;
  final bool isPointExchange;

  const VoucherModel({
    required this.id,
    required this.name,
    required this.discountPercent,
    this.isActive = true,
    required this.createdAt,
    this.pointCost,
    this.isPointExchange = false,
  });

  VoucherModel copyWith({
    String? id,
    String? name,
    double? discountPercent,
    bool? isActive,
    DateTime? createdAt,
    int? pointCost,
    bool? isPointExchange,
  }) {
    return VoucherModel(
      id: id ?? this.id,
      name: name ?? this.name,
      discountPercent: discountPercent ?? this.discountPercent,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      pointCost: pointCost ?? this.pointCost,
      isPointExchange: isPointExchange ?? this.isPointExchange,
    );
  }

  factory VoucherModel.fromMap(Map<String, dynamic> map) {
    return VoucherModel(
      id: map['id'] as String,
      name: map['name'] as String,
      discountPercent: (map['discountPercent'] as num).toDouble(),
      isActive: map['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(map['createdAt'] as String),
      pointCost: map['pointCost'] as int?,
      isPointExchange: map['isPointExchange'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'discountPercent': discountPercent,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'pointCost': pointCost,
      'isPointExchange': isPointExchange,
    };
  }
}
