import '../../domain/models/product_model.dart';

/// Dummy Data for Products and Banners
class HomeDummyData {
  HomeDummyData._();

  /// List of Product Categories
  static const List<String> categories = [
    'All',
    'T-Shirt',
    'Shirt',
    'Pants',
    'Jacket',
    'Accessories',
  ];

  /// List of Banner/Promo Data
  static const List<BannerModel> banners = [
    BannerModel(
      id: '1',
      title: 'Summer Collection 2026',
      subtitle: 'Tampil stylish di musim panas',
      imageUrl: 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=800&q=80',
      discount: 'UP TO 50%',
    ),
    BannerModel(
      id: '2',
      title: 'New Arrivals',
      subtitle: 'Koleksi terbaru sudah tiba',
      imageUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800&q=80',
      discount: 'NEW',
    ),
    BannerModel(
      id: '3',
      title: 'Casual Friday',
      subtitle: 'Siap untuk weekend look',
      imageUrl: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=800&q=80',
      discount: '30% OFF',
    ),
  ];

  /// List of Product Data
  static const List<ProductModel> products = [
    ProductModel(
      id: '1',
      name: 'Essential Cotton T-Shirt',
      price: 189000,
      rating: 4.8,
      reviewCount: 234,
      imageUrl: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400&q=80',
      category: 'T-Shirt',
    ),
    ProductModel(
      id: '2',
      name: 'Minimalist Polo Shirt',
      price: 259000,
      rating: 4.6,
      reviewCount: 156,
      imageUrl: 'https://images.unsplash.com/photo-1625910513413-5fc4e5e40687?w=400&q=80',
      category: 'Shirt',
    ),
    ProductModel(
      id: '3',
      name: 'Slim Fit Denim Jeans',
      price: 389000,
      rating: 4.9,
      reviewCount: 412,
      imageUrl: 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=400&q=80',
      category: 'Pants',
    ),
    ProductModel(
      id: '4',
      name: 'Urban Bomber Jacket',
      price: 599000,
      rating: 4.7,
      reviewCount: 89,
      imageUrl: 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=400&q=80',
      category: 'Jacket',
    ),
    ProductModel(
      id: '5',
      name: 'Premium Casual Sneakers',
      price: 459000,
      rating: 4.5,
      reviewCount: 278,
      imageUrl: 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400&q=80',
      category: 'Accessories',
    ),
    ProductModel(
      id: '6',
      name: 'Basic Crew Neck Sweater',
      price: 329000,
      rating: 4.4,
      reviewCount: 167,
      imageUrl: 'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=400&q=80',
      category: 'Shirt',
    ),
    ProductModel(
      id: '7',
      name: 'Classic Chinos Pants',
      price: 349000,
      rating: 4.6,
      reviewCount: 203,
      imageUrl: 'https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=400&q=80',
      category: 'Pants',
    ),
    ProductModel(
      id: '8',
      name: 'Graphic Print Tee',
      price: 219000,
      rating: 4.3,
      reviewCount: 145,
      imageUrl: 'https://images.unsplash.com/photo-1503341504253-dff4815485f1?w=400&q=80',
      category: 'T-Shirt',
    ),
    ProductModel(
      id: '9',
      name: 'Leather Belt Premium',
      price: 179000,
      rating: 4.8,
      reviewCount: 321,
      imageUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400&q=80',
      category: 'Accessories',
    ),
    ProductModel(
      id: '10',
      name: 'Oversized Hoodie',
      price: 429000,
      rating: 4.7,
      reviewCount: 198,
      imageUrl: 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=400&q=80',
      category: 'Jacket',
    ),
    ProductModel(
      id: '11',
      name: 'Linen Button-Up Shirt',
      price: 299000,
      rating: 4.5,
      reviewCount: 112,
      imageUrl: 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400&q=80',
      category: 'Shirt',
    ),
    ProductModel(
      id: '12',
      name: 'Cargo Shorts',
      price: 249000,
      rating: 4.4,
      reviewCount: 87,
      imageUrl: 'https://images.unsplash.com/photo-1591195853828-11db59a44f6b?w=400&q=80',
      category: 'Pants',
    ),
  ];

  /// Get filtered products by category
  static List<ProductModel> getProductsByCategory(String category) {
    if (category == 'All') {
      return products;
    }
    return products.where((p) => p.category == category).toList();
  }
}
