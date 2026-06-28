class ProductModel {
  final String id;
  final String name;
  final double price;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final String category;
  final bool isFavorite;
  final bool isActive;
  final String description;
  final List<String> availableSizes;
  final int stock;
  final double weight;

  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
    this.rating = 0,
    this.reviewCount = 0,
    required this.imageUrl,
    required this.category,
    this.isFavorite = false,
    this.isActive = true,
    this.description = '',
    this.availableSizes = const ['S', 'M', 'L', 'XL'],
    this.stock = 0,
    this.weight = 200,
  });

  ProductModel copyWith({
    String? id,
    String? name,
    double? price,
    double? rating,
    int? reviewCount,
    String? imageUrl,
    String? category,
    bool? isFavorite,
    bool? isActive,
    String? description,
    List<String>? availableSizes,
    int? stock,
    double? weight,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      availableSizes: availableSizes ?? this.availableSizes,
      stock: stock ?? this.stock,
      weight: weight ?? this.weight,
    );
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: map['reviewCount'] as int? ?? 0,
      imageUrl: map['imageUrl'] as String,
      category: map['category'] as String,
      isFavorite: map['isFavorite'] as bool? ?? false,
      isActive: map['isActive'] as bool? ?? true,
      description: map['description'] as String? ?? '',
      availableSizes: (map['availableSizes'] as List?)?.cast<String>() ??
          ['S', 'M', 'L', 'XL'],
      stock: map['stock'] as int? ?? 0,
      weight: (map['weight'] as num?)?.toDouble() ?? 200,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'rating': rating,
      'reviewCount': reviewCount,
      'imageUrl': imageUrl,
      'category': category,
      'isFavorite': isFavorite,
      'isActive': isActive,
      'description': description,
      'availableSizes': availableSizes,
      'stock': stock,
      'weight': weight,
    };
  }
}

class BannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String? discount;

  const BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.discount,
  });

  factory BannerModel.fromMap(Map<String, dynamic> map) {
    return BannerModel(
      id: map['id'] as String,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String,
      imageUrl: map['imageUrl'] as String,
      discount: map['discount'] as String?,
    );
  }
}
