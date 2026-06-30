import '../../../../core/database/hive_db.dart';
import '../../domain/models/cart_model.dart';
import '../../domain/models/product_model.dart';

class CartRepository {
  static final CartRepository _instance = CartRepository._internal();
  factory CartRepository() => _instance;
  CartRepository._internal() {
    _loadFromHive();
  }

  final List<CartItemModel> _items = [];
  final HiveDb _db = HiveDb.instance;

  void _loadFromHive() {
    _items.clear();
    _items.addAll(_db.getCartItems());
  }

  List<CartItemModel> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get shippingCost => subtotal >= 500000 ? 0 : 15000;

  double get total => subtotal + shippingCost;

  CartSummaryModel get summary => CartSummaryModel(
        items: _items,
        subtotal: subtotal,
        shippingCost: shippingCost,
        total: total,
      );

  bool get isEmpty => _items.isEmpty;

  void addItem({
    required ProductModel product,
    required String selectedSize,
    int quantity = 1,
  }) {
    final sizeStock = product.stockForSize(selectedSize);
    if (quantity > sizeStock) {
      throw Exception('Stok ${product.name} ukuran $selectedSize tidak mencukupi (tersedia: $sizeStock)');
    }

    final existingIndex = _items.indexWhere(
      (item) =>
          item.productId == product.id &&
          item.selectedSize == selectedSize,
    );

    if (existingIndex != -1) {
      final newQty = _items[existingIndex].quantity + quantity;
      if (newQty > sizeStock) {
        throw Exception('Stok ${product.name} ukuran $selectedSize tidak mencukupi (tersedia: $sizeStock, di keranjang: ${_items[existingIndex].quantity})');
      }
      _items[existingIndex].quantity = newQty;
      _db.saveCartItem(_items[existingIndex]);
    } else {
      final item = CartItemModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: product.id,
        name: product.name,
        price: product.price,
        imageUrl: product.imageUrl,
        selectedSize: selectedSize,
        weight: product.weight,
        quantity: quantity,
      );
      _items.add(item);
      _db.saveCartItem(item);
    }
  }

  void removeItem(String cartItemId) {
    _items.removeWhere((item) => item.id == cartItemId);
    _db.deleteCartItem(cartItemId);
  }

  void updateQuantity(String cartItemId, int newQuantity) {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index != -1) {
      if (newQuantity <= 0) {
        _items.removeAt(index);
        _db.deleteCartItem(cartItemId);
      } else {
        _items[index].quantity = newQuantity;
        _db.saveCartItem(_items[index]);
      }
    }
  }

  void incrementQuantity(String cartItemId) {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index != -1) {
      final product = _db.getProductById(_items[index].productId);
      final maxStock = product?.stockForSize(_items[index].selectedSize) ?? 999;
      if (_items[index].quantity >= maxStock) return;
      _items[index].quantity++;
      _db.saveCartItem(_items[index]);
    }
  }

  void decrementQuantity(String cartItemId) {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index != -1) {
      if (_items[index].quantity <= 1) {
        _items.removeAt(index);
        _db.deleteCartItem(cartItemId);
      } else {
        _items[index].quantity--;
        _db.saveCartItem(_items[index]);
      }
    }
  }

  void clearCart() {
    _items.clear();
    _db.clearCart();
  }

  static String formatPrice(double price) {
    final number = price.round();
    final formatted = number.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'Rp $formatted';
  }
}
