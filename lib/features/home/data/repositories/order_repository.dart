import '../../../../core/database/hive_db.dart';
import '../../domain/models/order_model.dart';
import '../../domain/models/product_model.dart';
import '../../domain/models/cart_model.dart';

class OrderRepository {
  static final OrderRepository _instance = OrderRepository._internal();
  factory OrderRepository() => _instance;
  OrderRepository._internal() {
    _loadFromHive();
  }

  final List<OrderModel> _orders = [];
  final HiveDb _db = HiveDb.instance;

  void _loadFromHive() {
    _orders.clear();
    _orders.addAll(_db.getOrders());
  }

  List<OrderModel> get orders {
    final sorted = List<OrderModel>.from(_orders);
    sorted.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    return sorted;
  }

  List<OrderModel> getUserOrders(String userId) {
    return orders.where((o) => o.userId == userId).toList();
  }

  List<OrderModel> getOrdersByStatus(String status) {
    return orders.where((o) => o.status == _statusFromString(status)).toList();
  }

  OrderModel? getOrderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<String> createOrder({
    required List<CartItemModel> cartItems,
    required double subtotal,
    required double shippingCost,
    required PaymentMethod paymentMethod,
    String? courier,
    String? courierService,
    String? estimatedDelivery,
    double voucherDiscount = 0,
  }) async {
    if (cartItems.isEmpty) throw Exception('Keranjang belanja kosong');

    for (final item in cartItems) {
      final product = _db.getProductById(item.productId);
      if (product == null) {
        throw Exception('Produk ${item.name} tidak ditemukan');
      }
      if (product.stock < item.quantity) {
        throw Exception('Stok ${item.name} tidak mencukupi (tersedia: ${product.stock}, diminta: ${item.quantity})');
      }
    }

    final orderId = DateTime.now().millisecondsSinceEpoch.toString();
    final timestamp = orderId + (DateTime.now().microsecondsSinceEpoch % 1000).toString().padLeft(3, '0');

    final session = _db.getUserSession();
    if (session == null) throw Exception('Sesi login tidak ditemukan');

    final userId = session['id'] as String? ?? '';
    final userName = session['name'] as String? ?? 'User';
    final userEmail = session['email'] as String?;

    String userAddress = '';
    String userPhone = '';

    if (userEmail != null) {
      final raw = _db.usersBox.get(userEmail);
      final userData = raw is Map ? Map<String, dynamic>.from(raw) : null;
      if (userData != null) {
        userAddress = (userData['address'] as String?) ?? '';
        userPhone = (userData['phone'] as String?) ?? '';
      }
    }

    final items = <ProductModel>[];
    for (final cartItem in cartItems) {
      for (int i = 0; i < cartItem.quantity; i++) {
        items.add(ProductModel(
          id: cartItem.productId,
          name: cartItem.name,
          price: cartItem.price,
          imageUrl: cartItem.imageUrl,
          category: '',
        ));
      }
    }

    final order = OrderModel(
      id: timestamp,
      userId: userId,
      userName: userName,
      userAddress: userAddress,
      userPhone: userPhone,
      items: items,
      totalPrice: (subtotal + shippingCost - voucherDiscount).clamp(0, double.infinity),
      shippingCost: shippingCost,
      status: paymentMethod == PaymentMethod.cod
          ? OrderStatus.processing
          : OrderStatus.pending,
      paymentMethod: paymentMethod,
      courier: courier,
      courierService: courierService,
      estimatedDelivery: estimatedDelivery,
      orderDate: DateTime.now(),
    );

    _orders.insert(0, order);
    await _db.saveOrder(order);

    for (final item in cartItems) {
      final product = _db.getProductById(item.productId);
      if (product != null) {
        final updated = product.copyWith(stock: product.stock - item.quantity);
        await _db.saveProduct(updated);
      }
    }

    return timestamp;
  }

  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final oldStatus = _orders[index].status;
      OrderModel updated = _orders[index].copyWith(status: newStatus);

      if (newStatus == OrderStatus.shipped) {
        updated = updated.copyWith(shippedDate: DateTime.now());
      } else if (newStatus == OrderStatus.delivered) {
        updated = updated.copyWith(deliveredDate: DateTime.now());
      } else if (newStatus == OrderStatus.paid) {
        updated = updated.copyWith(paymentDate: DateTime.now());
      }

      if (newStatus == OrderStatus.cancelled && oldStatus != OrderStatus.cancelled) {
        _restoreStock(updated);
      }

      _orders[index] = updated;
      _db.updateOrderStatus(orderId, newStatus);
    }
  }

  static Future<void> syncOrderStatus(String orderId, OrderStatus newStatus) async {
    final repo = OrderRepository();
    final index = repo._orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final oldStatus = repo._orders[index].status;
      OrderModel updated = repo._orders[index].copyWith(status: newStatus);
      if (newStatus == OrderStatus.shipped) {
        updated = updated.copyWith(shippedDate: DateTime.now());
      } else if (newStatus == OrderStatus.delivered) {
        updated = updated.copyWith(deliveredDate: DateTime.now());
      } else if (newStatus == OrderStatus.paid) {
        updated = updated.copyWith(paymentDate: DateTime.now());
      }

      if (newStatus == OrderStatus.cancelled && oldStatus != OrderStatus.cancelled) {
        repo._restoreStock(updated);
      }

      repo._orders[index] = updated;
    }
    await HiveDb.instance.updateOrderStatus(orderId, newStatus);
  }

  void _restoreStock(OrderModel order) {
    for (final item in order.items) {
      final product = _db.getProductById(item.id);
      if (product != null) {
        final restored = product.copyWith(stock: product.stock + 1);
        _db.saveProduct(restored);
      }
    }
  }

  void confirmPayment(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(
        status: OrderStatus.paid,
        paymentDate: DateTime.now(),
      );
      _db.updateOrderStatus(orderId, OrderStatus.paid);
    }
  }

  Map<String, int> getOrderStats() {
    return {
      'total': _orders.length,
      'pending':
          _orders.where((o) => o.status == OrderStatus.pending).length,
      'paid': _orders.where((o) => o.status == OrderStatus.paid).length,
      'processing':
          _orders.where((o) => o.status == OrderStatus.processing).length,
      'shipped':
          _orders.where((o) => o.status == OrderStatus.shipped).length,
      'delivered':
          _orders.where((o) => o.status == OrderStatus.delivered).length,
    };
  }

  OrderStatus _statusFromString(String status) {
    switch (status) {
      case 'pending':
        return OrderStatus.pending;
      case 'paid':
        return OrderStatus.paid;
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      default:
        return OrderStatus.pending;
    }
  }
}
