import '../../../../core/database/hive_db.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../core/services/notification_service.dart';
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
    double actualShippingCost = 0,
    double voucherDiscount = 0,
    double walletDiscount = 0,
    required PaymentMethod paymentMethod,
    String? courier,
    String? courierService,
    String? estimatedDelivery,
  }) async {
    if (cartItems.isEmpty) throw Exception('Keranjang belanja kosong');

    for (final item in cartItems) {
      final product = _db.getProductById(item.productId);
      if (product == null) {
        throw Exception('Produk ${item.name} tidak ditemukan');
      }
      final sizeStock = product.stockForSize(item.selectedSize);
      if (sizeStock < item.quantity) {
        throw Exception('Stok ${item.name} ukuran ${item.selectedSize} tidak mencukupi (tersedia: $sizeStock, diminta: ${item.quantity})');
      }
    }

    final orderId = DateTime.now().millisecondsSinceEpoch.toString();
    final timestamp = orderId + (DateTime.now().microsecondsSinceEpoch % 1000).toString().padLeft(3, '0');

    // Generate order number: RC-001, RC-002, etc.
    final orderCount = _orders.length + 1;
    final orderNumber = 'RC-${orderCount.toString().padLeft(3, '0')}';

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
          images: [cartItem.imageUrl],
          category: cartItem.selectedSize,
        ));
      }
    }

    final order = OrderModel(
      id: timestamp,
      orderNumber: orderNumber,
      userId: userId,
      userName: userName,
      userAddress: userAddress,
      userPhone: userPhone,
      items: items,
      totalPrice: (subtotal + shippingCost - voucherDiscount - walletDiscount).clamp(0, double.infinity),
      shippingCost: shippingCost,
      actualShippingCost: actualShippingCost,
      voucherDiscount: voucherDiscount,
      walletDiscount: walletDiscount,
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

    final notifService = NotificationService();
    await notifService.createNotification(
      title: 'Pesanan Baru',
      body: '$userName memesan ${cartItems.length} produk ($orderNumber) - Rp ${(order.totalPrice).toStringAsFixed(0)}',
      type: NotificationType.newOrder,
      orderId: timestamp,
      recipient: 'admin',
    );

    for (final item in cartItems) {
      final product = _db.getProductById(item.productId);
      if (product != null) {
        final currentSizeStock = product.stockForSize(item.selectedSize);
        final newStockPerSize = Map<String, int>.from(product.stockPerSize);
        newStockPerSize[item.selectedSize] = currentSizeStock - item.quantity;
        final updated = product.copyWith(stockPerSize: newStockPerSize);
        await _db.saveProduct(updated);
      }
    }

    return timestamp;
  }

  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final oldStatus = _orders[index].status;
      if (oldStatus == newStatus) return;
      OrderModel updated = _orders[index].copyWith(status: newStatus);

      if (newStatus == OrderStatus.shipped) {
        updated = updated.copyWith(shippedDate: DateTime.now());
      } else if (newStatus == OrderStatus.delivered) {
        updated = updated.copyWith(deliveredDate: DateTime.now());

        if (oldStatus != OrderStatus.delivered) {
          final points = (updated.totalPrice / 1000).floor();
          if (points > 0) {
            final userEmail = _db.getUserEmailById(updated.userId);
            if (userEmail != null) {
              final currentPoints = _db.getPointsBalanceByEmail(userEmail);
              _db.setPointsBalanceByEmail(userEmail, currentPoints + points);
            }
          }
        }
      } else if (newStatus == OrderStatus.paid) {
        updated = updated.copyWith(paymentDate: DateTime.now());
      }

      if (newStatus == OrderStatus.cancelled && oldStatus != OrderStatus.cancelled) {
        _restoreStock(updated);
      }

      _orders[index] = updated;
      _db.updateOrderStatus(orderId, newStatus);
      _fireStatusNotification(updated, oldStatus, newStatus);
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

        if (oldStatus != OrderStatus.delivered) {
          final points = (updated.totalPrice / 1000).floor();
          if (points > 0) {
            final userEmail = repo._db.getUserEmailById(updated.userId);
            if (userEmail != null) {
              final currentPoints = repo._db.getPointsBalanceByEmail(userEmail);
              repo._db.setPointsBalanceByEmail(userEmail, currentPoints + points);
            }
          }
        }
      } else if (newStatus == OrderStatus.paid) {
        updated = updated.copyWith(paymentDate: DateTime.now());
      }

      if (newStatus == OrderStatus.cancelled && oldStatus != OrderStatus.cancelled) {
        repo._restoreStock(updated);
      }

      repo._orders[index] = updated;
      repo._fireStatusNotification(updated, oldStatus, newStatus);
    }
    await HiveDb.instance.updateOrderStatus(orderId, newStatus);
  }

  static Future<void> syncOrderStatusWithTracking(
    String orderId,
    OrderStatus newStatus, {
    required String trackingNumber,
  }) async {
    final repo = OrderRepository();
    final index = repo._orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final oldStatus = repo._orders[index].status;
      OrderModel updated = repo._orders[index].copyWith(
        status: newStatus,
        trackingNumber: trackingNumber.isNotEmpty ? trackingNumber : null,
      );
      if (newStatus == OrderStatus.shipped) {
        updated = updated.copyWith(shippedDate: DateTime.now());
      } else if (newStatus == OrderStatus.delivered) {
        updated = updated.copyWith(deliveredDate: DateTime.now());

        if (oldStatus != OrderStatus.delivered) {
          final points = (updated.totalPrice / 1000).floor();
          if (points > 0) {
            final userEmail = repo._db.getUserEmailById(updated.userId);
            if (userEmail != null) {
              final currentPoints = repo._db.getPointsBalanceByEmail(userEmail);
              repo._db.setPointsBalanceByEmail(userEmail, currentPoints + points);
            }
          }
        }
      } else if (newStatus == OrderStatus.paid) {
        updated = updated.copyWith(paymentDate: DateTime.now());
      }

      if (newStatus == OrderStatus.cancelled && oldStatus != OrderStatus.cancelled) {
        repo._restoreStock(updated);
      }

      repo._orders[index] = updated;
      repo._fireStatusNotification(updated, oldStatus, newStatus);
    }
    await HiveDb.instance.updateOrderStatus(orderId, newStatus);
    if (trackingNumber.isNotEmpty) {
      await HiveDb.instance.updateOrderTracking(orderId, trackingNumber);
    }
  }

  void _fireStatusNotification(OrderModel order, OrderStatus oldStatus, OrderStatus newStatus) {
    final notifService = NotificationService();
    String title;
    String body;
    NotificationType type;
    String recipient;

    switch (newStatus) {
      case OrderStatus.paid:
        title = 'Pembayaran Dikonfirmasi';
        body = 'Pesanan ${order.orderNumber} telah dikonfirmasi pembayarannya';
        type = NotificationType.paymentConfirmed;
        recipient = 'user';
      case OrderStatus.processing:
        title = 'Pesanan Diproses';
        body = 'Pesanan ${order.orderNumber} sedang diproses';
        type = NotificationType.orderProcessing;
        recipient = 'user';
      case OrderStatus.shipped:
        title = 'Pesanan Dikirim';
        body = 'Pesanan ${order.orderNumber} sedang dalam pengiriman';
        type = NotificationType.orderShipped;
        recipient = 'user';
      case OrderStatus.delivered:
        title = 'Pesanan Selesai';
        body = '${order.userName} telah menerima pesanan ${order.orderNumber}';
        type = NotificationType.orderDelivered;
        recipient = 'admin';
      case OrderStatus.cancelled:
        title = 'Pesanan Dibatalkan';
        body = '${order.userName} membatalkan pesanan ${order.orderNumber}';
        type = NotificationType.orderCancelled;
        recipient = 'admin';
      default:
        return;
    }

    notifService.createNotification(
      title: title,
      body: body,
      type: type,
      orderId: order.id,
      recipient: recipient,
    ).catchError((_) {});
  }

  void _restoreStock(OrderModel order) {
    final restoreMap = <String, Map<String, int>>{};
    for (final item in order.items) {
      final size = item.category.isNotEmpty ? item.category : 'M';
      restoreMap.putIfAbsent(item.id, () => {});
      restoreMap[item.id]![size] = (restoreMap[item.id]![size] ?? 0) + 1;
    }
    for (final entry in restoreMap.entries) {
      final product = _db.getProductById(entry.key);
      if (product != null) {
        final newStockPerSize = Map<String, int>.from(product.stockPerSize);
        for (final sizeEntry in entry.value.entries) {
          newStockPerSize[sizeEntry.key] = (newStockPerSize[sizeEntry.key] ?? 0) + sizeEntry.value;
        }
        _db.saveProduct(product.copyWith(stockPerSize: newStockPerSize));
      }
    }
  }

  Future<void> confirmPayment(String orderId) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final oldStatus = _orders[index].status;
      _orders[index] = _orders[index].copyWith(
        status: OrderStatus.paid,
        paymentDate: DateTime.now(),
      );
      await _db.updateOrderStatus(orderId, OrderStatus.paid);
      _fireStatusNotification(_orders[index], oldStatus, OrderStatus.paid);
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
