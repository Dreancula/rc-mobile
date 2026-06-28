class CartItemModel {
  final String id;
  final String productId;
  final String name;
  final double price;
  final String imageUrl;
  final String selectedSize;
  int quantity;
  final double weight;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.selectedSize,
    this.quantity = 1,
    this.weight = 200,
  });

  double get totalPrice => price * quantity;
  double get totalWeight => weight * quantity;

  CartItemModel copyWith({
    String? id,
    String? productId,
    String? name,
    double? price,
    String? imageUrl,
    String? selectedSize,
    int? quantity,
    double? weight,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      selectedSize: selectedSize ?? this.selectedSize,
      quantity: quantity ?? this.quantity,
      weight: weight ?? this.weight,
    );
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      id: map['id'] as String,
      productId: map['productId'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      imageUrl: map['imageUrl'] as String,
      selectedSize: map['selectedSize'] as String,
      quantity: map['quantity'] as int? ?? 1,
      weight: (map['weight'] as num?)?.toDouble() ?? 200,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'selectedSize': selectedSize,
      'quantity': quantity,
      'weight': weight,
    };
  }
}

class CartSummaryModel {
  final List<CartItemModel> items;
  final double subtotal;
  final double shippingCost;
  final double total;

  const CartSummaryModel({
    required this.items,
    required this.subtotal,
    required this.shippingCost,
    required this.total,
  });

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  double get totalWeight =>
      items.fold(0.0, (sum, item) => sum + item.totalWeight);
}
