import 'package:rc_mobile_v2/features/home/domain/models/product_model.dart';

enum OrderStatus {
  pending,
  paid,
  processing,
  shipped,
  delivered,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Menunggu Pembayaran';
      case OrderStatus.paid:
        return 'Dibayar';
      case OrderStatus.processing:
        return 'Diproses';
      case OrderStatus.shipped:
        return 'Dikirim';
      case OrderStatus.delivered:
        return 'Selesai';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
    }
  }
}

enum PaymentMethod {
  qris,
  wallet,
  cod;

  String get displayName {
    switch (this) {
      case PaymentMethod.qris:
        return 'QRIS';
      case PaymentMethod.wallet:
        return 'Dompet Digital RC';
      case PaymentMethod.cod:
        return 'COD (Bayar di Tempat)';
    }
  }
}

class OrderModel {
  final String id;
  final String userId;
  final String userName;
  final String userAddress;
  final String userPhone;
  final List<ProductModel> items;
  final double totalPrice;
  final double shippingCost;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final String? paymentProof;
  final DateTime orderDate;
  final DateTime? paymentDate;
  final DateTime? shippedDate;
  final DateTime? deliveredDate;
  final String? courier;
  final String? courierService;
  final String? estimatedDelivery;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAddress,
    required this.userPhone,
    required this.items,
    required this.totalPrice,
    required this.shippingCost,
    this.status = OrderStatus.pending,
    required this.paymentMethod,
    this.paymentProof,
    required this.orderDate,
    this.paymentDate,
    this.shippedDate,
    this.deliveredDate,
    this.courier,
    this.courierService,
    this.estimatedDelivery,
  });

  OrderModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAddress,
    String? userPhone,
    List<ProductModel>? items,
    double? totalPrice,
    double? shippingCost,
    OrderStatus? status,
    PaymentMethod? paymentMethod,
    String? paymentProof,
    DateTime? orderDate,
    DateTime? paymentDate,
    DateTime? shippedDate,
    DateTime? deliveredDate,
    String? courier,
    String? courierService,
    String? estimatedDelivery,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAddress: userAddress ?? this.userAddress,
      userPhone: userPhone ?? this.userPhone,
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      shippingCost: shippingCost ?? this.shippingCost,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentProof: paymentProof ?? this.paymentProof,
      orderDate: orderDate ?? this.orderDate,
      paymentDate: paymentDate ?? this.paymentDate,
      shippedDate: shippedDate ?? this.shippedDate,
      deliveredDate: deliveredDate ?? this.deliveredDate,
      courier: courier ?? this.courier,
      courierService: courierService ?? this.courierService,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
    );
  }

  String get statusDisplay => status.displayName;

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      userAddress: map['userAddress'] as String,
      userPhone: map['userPhone'] as String,
      items: (map['items'] as List)
          .map((e) => ProductModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      totalPrice: (map['totalPrice'] as num).toDouble(),
      shippingCost: (map['shippingCost'] as num?)?.toDouble() ?? 0,
      status: OrderStatus.values[map['status'] as int? ?? 0],
      paymentMethod: PaymentMethod.values[map['paymentMethod'] as int? ?? 0],
      paymentProof: map['paymentProof'] as String?,
      orderDate: DateTime.parse(map['orderDate'] as String),
      paymentDate: map['paymentDate'] != null
          ? DateTime.parse(map['paymentDate'] as String)
          : null,
      shippedDate: map['shippedDate'] != null
          ? DateTime.parse(map['shippedDate'] as String)
          : null,
      deliveredDate: map['deliveredDate'] != null
          ? DateTime.parse(map['deliveredDate'] as String)
          : null,
      courier: map['courier'] as String?,
      courierService: map['courierService'] as String?,
      estimatedDelivery: map['estimatedDelivery'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAddress': userAddress,
      'userPhone': userPhone,
      'items': items.map((e) => e.toMap()).toList(),
      'totalPrice': totalPrice,
      'shippingCost': shippingCost,
      'status': status.index,
      'paymentMethod': paymentMethod.index,
      'paymentProof': paymentProof,
      'orderDate': orderDate.toIso8601String(),
      'paymentDate': paymentDate?.toIso8601String(),
      'shippedDate': shippedDate?.toIso8601String(),
      'deliveredDate': deliveredDate?.toIso8601String(),
      'courier': courier,
      'courierService': courierService,
      'estimatedDelivery': estimatedDelivery,
    };
  }
}
