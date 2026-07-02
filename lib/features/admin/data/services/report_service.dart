import 'package:rc_mobile_v2/core/database/hive_db.dart';
import 'package:rc_mobile_v2/features/home/domain/models/order_model.dart';

class FinancialReport {
  final double totalRevenue;
  final double totalLoss;
  final double totalLossFromComplaints;
  final double totalShippingLoss;
  final double totalVoucherLoss;
  final double totalWalletDiscountLoss;
  final double totalAdminFeeProfit;
  final double netSavings;
  final int totalOrders;
  final int deliveredOrders;
  final double averageOrderValue;
  final double todayRevenue;
  final double qrisRevenue;
  final double walletRevenue;
  final double codRevenue;
  final Map<String, double> revenueByCategory;
  final Map<DateTime, DailySummary> dailySummaries;
  final DateTime startDate;
  final DateTime endDate;

  const FinancialReport({
    required this.totalRevenue,
    required this.totalLoss,
    required this.totalLossFromComplaints,
    required this.totalShippingLoss,
    required this.totalVoucherLoss,
    required this.totalWalletDiscountLoss,
    required this.totalAdminFeeProfit,
    required this.netSavings,
    required this.totalOrders,
    required this.deliveredOrders,
    required this.averageOrderValue,
    required this.todayRevenue,
    required this.qrisRevenue,
    required this.walletRevenue,
    required this.codRevenue,
    required this.revenueByCategory,
    required this.dailySummaries,
    required this.startDate,
    required this.endDate,
  });
}

class DailySummary {
  final DateTime date;
  final double revenue;
  final int orderCount;

  const DailySummary({
    required this.date,
    required this.revenue,
    required this.orderCount,
  });
}

class TransactionReport {
  final List<OrderModel> orders;
  final DateTime startDate;
  final DateTime endDate;
  final int totalOrders;
  final double totalRevenue;

  const TransactionReport({
    required this.orders,
    required this.startDate,
    required this.endDate,
    required this.totalOrders,
    required this.totalRevenue,
  });
}

class ProductReportItem {
  final String productName;
  final String category;
  final double price;
  final int totalSold;
  final double totalRevenue;
  final int stockRemaining;

  const ProductReportItem({
    required this.productName,
    required this.category,
    required this.price,
    required this.totalSold,
    required this.totalRevenue,
    required this.stockRemaining,
  });
}

class ProductReport {
  final List<ProductReportItem> items;
  final int totalProducts;
  final int totalSold;
  final double totalRevenue;

  const ProductReport({
    required this.items,
    required this.totalProducts,
    required this.totalSold,
    required this.totalRevenue,
  });
}

class DailyRecapReport {
  final List<DailySummary> days;
  final double totalRevenue;
  final int totalOrders;
  final double averageDailyRevenue;
  final int year;
  final int month;
  final String monthName;

  const DailyRecapReport({
    required this.days,
    required this.totalRevenue,
    required this.totalOrders,
    required this.averageDailyRevenue,
    required this.year,
    required this.month,
    required this.monthName,
  });
}

class ReportService {
  final HiveDb _db;

  ReportService(this._db);

  static const _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  String get monthName => _monthNames[DateTime.now().month - 1];

  FinancialReport getFinancialReport({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final orders = _db.getOrders();
    final filtered = orders.where((o) =>
        o.orderDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        o.orderDate.isBefore(endDate.add(const Duration(days: 1)))).toList();

    final delivered = filtered.where((o) => o.status == OrderStatus.delivered).toList();

    final totalRevenue = delivered.fold<double>(0, (s, o) => s + o.totalPrice);
    final totalLossFromComplaints = _db.getTotalLossFromComplaints();
    final totalShippingLoss = _db.getTotalShippingLoss();
    final totalVoucherLoss = _db.getTotalVoucherLoss();
    final totalWalletDiscountLoss = _db.getTotalWalletDiscountLoss();
    final totalLoss = totalLossFromComplaints + totalShippingLoss + totalVoucherLoss + totalWalletDiscountLoss;
    final totalAdminFeeProfit = _db.getTotalAdminFeeProfit();
    final netSavings = totalRevenue - totalLoss + totalAdminFeeProfit;

    final qrisRevenue = delivered.where((o) => o.paymentMethod == PaymentMethod.qris)
        .fold<double>(0, (s, o) => s + o.totalPrice);
    final walletRevenue = delivered.where((o) => o.paymentMethod == PaymentMethod.wallet)
        .fold<double>(0, (s, o) => s + o.totalPrice);
    final codRevenue = delivered.where((o) => o.paymentMethod == PaymentMethod.cod)
        .fold<double>(0, (s, o) => s + o.totalPrice);

    final catMap = <String, double>{};
    for (final order in delivered) {
      for (final item in order.items) {
        catMap[item.category] = (catMap[item.category] ?? 0) + item.price;
      }
    }

    final todayStr = '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
    final todayRevenue = delivered.where((o) {
      final d = o.deliveredDate;
      return d != null && '${d.year}-${d.month}-${d.day}' == todayStr;
    }).fold<double>(0, (s, o) => s + o.totalPrice);

    final days = <DateTime, DailySummary>{};
    for (int i = 0; i < 31; i++) {
      final day = endDate.subtract(Duration(days: i));
      final dayStr = '${day.year}-${day.month}-${day.day}';
      final dayRevenue = delivered.where((o) {
        final d = o.deliveredDate;
        return d != null && '${d.year}-${d.month}-${d.day}' == dayStr;
      }).fold<double>(0, (s, o) => s + o.totalPrice);
      final dayOrders = delivered.where((o) {
        final d = o.deliveredDate;
        return d != null && '${d.year}-${d.month}-${d.day}' == dayStr;
      }).length;
      days[DateTime(day.year, day.month, day.day)] = DailySummary(
        date: DateTime(day.year, day.month, day.day),
        revenue: dayRevenue,
        orderCount: dayOrders,
      );
    }

    final deliveredCount = delivered.length;

    return FinancialReport(
      totalRevenue: totalRevenue,
      totalLoss: totalLoss,
      totalLossFromComplaints: totalLossFromComplaints,
      totalShippingLoss: totalShippingLoss,
      totalVoucherLoss: totalVoucherLoss,
      totalWalletDiscountLoss: totalWalletDiscountLoss,
      totalAdminFeeProfit: totalAdminFeeProfit,
      netSavings: netSavings > 0 ? netSavings : 0,
      totalOrders: filtered.length,
      deliveredOrders: deliveredCount,
      averageOrderValue: deliveredCount > 0 ? totalRevenue / deliveredCount : 0,
      todayRevenue: todayRevenue,
      qrisRevenue: qrisRevenue,
      walletRevenue: walletRevenue,
      codRevenue: codRevenue,
      revenueByCategory: catMap,
      dailySummaries: days,
      startDate: startDate,
      endDate: endDate,
    );
  }

  TransactionReport getTransactionReport({
    required DateTime startDate,
    required DateTime endDate,
    String? statusFilter,
  }) {
    var orders = _db.getOrders();
    orders = orders.where((o) =>
        o.orderDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        o.orderDate.isBefore(endDate.add(const Duration(days: 1)))).toList();

    if (statusFilter != null && statusFilter != 'Semua') {
      final status = _parseStatus(statusFilter);
      orders = orders.where((o) => o.status == status).toList();
    }

    orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

    final totalRevenue = orders.fold<double>(0, (s, o) => s + o.totalPrice);

    return TransactionReport(
      orders: orders,
      startDate: startDate,
      endDate: endDate,
      totalOrders: orders.length,
      totalRevenue: totalRevenue,
    );
  }

  ProductReport getProductReport() {
    final products = _db.getActiveProducts();
    final orders = _db.getOrders().where((o) => o.status == OrderStatus.delivered).toList();

    final productSales = <String, int>{};
    final productRevenue = <String, double>{};

    for (final order in orders) {
      for (final item in order.items) {
        productSales[item.id] = (productSales[item.id] ?? 0) + 1;
        productRevenue[item.id] = (productRevenue[item.id] ?? 0) + item.price;
      }
    }

    final items = products.map((p) {
      return ProductReportItem(
        productName: p.name,
        category: p.category,
        price: p.price,
        totalSold: productSales[p.id] ?? 0,
        totalRevenue: productRevenue[p.id] ?? 0,
        stockRemaining: p.stock,
      );
    }).toList();

    items.sort((a, b) => b.totalSold.compareTo(a.totalSold));

    final totalSold = items.fold<int>(0, (s, i) => s + i.totalSold);
    final totalRevenue = items.fold<double>(0, (s, i) => s + i.totalRevenue);

    return ProductReport(
      items: items,
      totalProducts: items.length,
      totalSold: totalSold,
      totalRevenue: totalRevenue,
    );
  }

  DailyRecapReport getDailyRecapReport(int year, int month) {
    final orders = _db.getOrders().where((o) => o.status == OrderStatus.delivered).toList();
    final daysInMonth = DateTime(year, month + 1, 0).day;

    final days = <DailySummary>[];
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final dayStr = '${date.year}-${date.month}-${date.day}';
      final dayRevenue = orders.where((o) {
        final d = o.deliveredDate;
        return d != null && '${d.year}-${d.month}-${d.day}' == dayStr;
      }).fold<double>(0, (s, o) => s + o.totalPrice);
      final dayOrders = orders.where((o) {
        final d = o.deliveredDate;
        return d != null && '${d.year}-${d.month}-${d.day}' == dayStr;
      }).length;

      days.add(DailySummary(
        date: date,
        revenue: dayRevenue,
        orderCount: dayOrders,
      ));
    }

    final totalRevenue = days.fold<double>(0, (s, d) => s + d.revenue);
    final totalOrders = days.fold<int>(0, (s, d) => s + d.orderCount);

    return DailyRecapReport(
      days: days,
      totalRevenue: totalRevenue,
      totalOrders: totalOrders,
      averageDailyRevenue: daysInMonth > 0 ? totalRevenue / daysInMonth : 0,
      year: year,
      month: month,
      monthName: _monthNames[month - 1],
    );
  }

  OrderStatus _parseStatus(String s) {
    switch (s) {
      case 'Pending': return OrderStatus.pending;
      case 'Dibayar': return OrderStatus.paid;
      case 'Diproses': return OrderStatus.processing;
      case 'Dikirim': return OrderStatus.shipped;
      case 'Selesai': return OrderStatus.delivered;
      case 'Dibatalkan': return OrderStatus.cancelled;
      default: return OrderStatus.pending;
    }
  }
}
