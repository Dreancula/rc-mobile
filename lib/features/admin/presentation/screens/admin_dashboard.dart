import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:rc_mobile_v2/core/database/hive_db.dart';
import 'package:rc_mobile_v2/core/theme/app_colors.dart';
import 'package:rc_mobile_v2/features/home/domain/models/order_model.dart';

class AdminDashboard extends StatefulWidget {
  final HiveDb db;
  const AdminDashboard({super.key, required this.db});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late HiveDb _db;

  @override
  void initState() {
    super.initState();
    _db = widget.db;
  }

  // Get financial data
  double get _productRevenue {
    final delivered = _db.getOrders().where((o) => o.status == OrderStatus.delivered).toList();
    return delivered.fold<double>(0, (s, o) => s + (o.totalPrice - o.shippingCost));
  }

  double get _shippingCollected {
    final delivered = _db.getOrders().where((o) => o.status == OrderStatus.delivered).toList();
    return delivered.fold<double>(0, (s, o) => s + o.shippingCost);
  }

  double get _grossSales {
    final delivered = _db.getOrders().where((o) => o.status == OrderStatus.delivered).toList();
    return delivered.fold<double>(0, (s, o) => s + o.totalPrice);
  }

  double get _totalDiscounts {
    return _db.getTotalLoss();
  }

  double get _complaintLoss => _db.getTotalLossFromComplaints();
  double get _shippingLoss => _db.getTotalShippingLoss();
  double get _voucherLoss => _db.getTotalVoucherLoss();
  double get _walletLoss => _db.getTotalWalletDiscountLoss();
  double get _adminFeeProfit => _db.getTotalAdminFeeProfit();

  double get _netProfit {
    return _productRevenue - _totalDiscounts + _adminFeeProfit;
  }

  int get _totalOrders => _db.getOrders().length;

  double get _avgDailyRevenue {
    final delivered = _db.getOrders().where((o) => o.status == OrderStatus.delivered).toList();
    return delivered.isNotEmpty ? (_productRevenue / 30) : 0.0;
  }

  // Dialog untuk detail card
  void _showDetailDialog(String title, String subtitle, IconData icon, Color color, List<_DetailItem> items) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: AppColors.pureWhite, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pureWhite,
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.pureWhite.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Detail Items
              ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: item.color ?? AppColors.softGrey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.pitchBlack,
                            ),
                          ),
                          if (item.description != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.description!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.softGrey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      item.value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: item.color ?? AppColors.pitchBlack,
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 12),
              // Info box
              if (items.any((i) => i.description != null)) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.softGrey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '💡 Tekan card di dashboard untuk melihat detail seperti ini',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.softGrey.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pitchBlack,
                    foregroundColor: AppColors.pureWhite,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = _db.getOrders();
    final delivered = orders.where((o) => o.status == OrderStatus.delivered).toList();

    return RefreshIndicator(
      color: AppColors.pitchBlack,
      onRefresh: () async => setState(() {}),
      child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(gradient: AppColors.softBlackGradient, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.analytics_rounded, color: AppColors.pureWhite, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Dashboard Keuangan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.pitchBlack, letterSpacing: -0.3)),
            ],
          ),
          const SizedBox(height: 20),

          // === ROW 1: Revenue & Shipping ===
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Revenue Produk',
                  subtitle: 'Pendapatan dari produk',
                  value: 'Rp ${_f(_productRevenue)}',
                  icon: Icons.trending_up_rounded,
                  gradient: const LinearGradient(colors: [Color(0xFF2D2D2D), Color(0xFF0A0A0A)]),
                  onTap: () => _showDetailDialog(
                    'Revenue Produk',
                    'Pendapatan dari penjualan produk (EXCLUDE ongkir)',
                    Icons.trending_up_rounded,
                    const Color(0xFF2D2D2D),
                    [
                      _DetailItem(
                        title: 'Total Harga Produk',
                        value: 'Rp ${_f(_productRevenue)}',
                        description: 'Total harga produk yang terjual',
                      ),
                      _DetailItem(
                        title: 'Rumus',
                        value: 'Harga - Ongkir',
                        color: AppColors.softGrey,
                      ),
                      _DetailItem(
                        title: 'Kenapa exclude ongkir?',
                        value: '',
                        description: 'Ongkir adalah pass-through ke kurir, bukan revenue kami',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Ongkir',
                  subtitle: 'Pass-through ke kurir',
                  value: 'Rp ${_f(_shippingCollected)}',
                  icon: Icons.local_shipping_rounded,
                  gradient: const LinearGradient(colors: [Color(0xFF5D4037), Color(0xFF3E2723)]),
                  onTap: () => _showDetailDialog(
                    'Ongkir (Pass-through)',
                    'Uang ongkir yang dikumpulkan untuk kurir',
                    Icons.local_shipping_rounded,
                    const Color(0xFF5D4037),
                    [
                      _DetailItem(
                        title: 'Total Ongkir',
                        value: 'Rp ${_f(_shippingCollected)}',
                        description: 'Total ongkir dari semua pesanan selesai',
                      ),
                      _DetailItem(
                        title: 'Status',
                        value: 'Pass-through',
                        color: AppColors.warning,
                      ),
                      _DetailItem(
                        title: 'Penjelasan',
                        value: '',
                        description: 'Uang ongkir bukan revenue kami. Nanti dibayar ke pihak ketiga (kurir). Revenue kami hanya dari produk saja.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // === ROW 2: Gross Sales & Net Profit ===
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Total Penjualan',
                  subtitle: 'Produk + Ongkir',
                  value: 'Rp ${_f(_grossSales)}',
                  icon: Icons.account_balance_wallet_rounded,
                  gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF0D1442)]),
                  onTap: () => _showDetailDialog(
                    'Total Penjualan Kotor',
                    'Total semua uang yang masuk (gross sales)',
                    Icons.account_balance_wallet_rounded,
                    const Color(0xFF1A237E),
                    [
                      _DetailItem(
                        title: 'Gross Sales',
                        value: 'Rp ${_f(_grossSales)}',
                        description: 'Total semua transaksi',
                      ),
                      _DetailItem(
                        title: 'Rumus',
                        value: 'Revenue + Ongkir',
                        color: AppColors.softGrey,
                      ),
                      _DetailItem(
                        title: 'Penjelasan',
                        value: '',
                        description: 'Ini adalah TOTAL uang yang masuk. Tapi belum termasuk diskon/voucher yang dipakai customer.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Keuntungan Bersih',
                  subtitle: 'Profit bersih kami',
                  value: 'Rp ${_f(_netProfit > 0 ? _netProfit : 0)}',
                  icon: Icons.savings_rounded,
                  gradient: _netProfit >= 0
                      ? const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF0D3B0F)])
                      : const LinearGradient(colors: [Color(0xFFC62828), Color(0xFF8B0000)]),
                  onTap: () => _showDetailDialog(
                    'Keuntungan Bersih',
                    'Profit bersih setelah semua potongan',
                    Icons.savings_rounded,
                    _netProfit >= 0 ? const Color(0xFF1B5E20) : const Color(0xFFC62828),
                    [
                      _DetailItem(
                        title: 'Revenue Produk',
                        value: 'Rp ${_f(_productRevenue)}',
                        color: AppColors.success,
                      ),
                      _DetailItem(
                        title: 'Total Diskon/Potongan',
                        value: '- Rp ${_f(_totalDiscounts)}',
                        color: AppColors.error,
                      ),
                      _DetailItem(
                        title: 'Fee Admin',
                        value: '+ Rp ${_f(_adminFeeProfit)}',
                        color: AppColors.info,
                      ),
                      _DetailItem(
                        title: 'Keuntungan Bersih',
                        value: 'Rp ${_f(_netProfit)}',
                        description: 'Revenue - Diskon + Fee Admin',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // === ROW 3: Discounts & Fee Admin ===
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Total Diskon',
                  subtitle: 'Potongan & komplain',
                  value: 'Rp ${_f(_totalDiscounts)}',
                  icon: Icons.discount_rounded,
                  gradient: const LinearGradient(colors: [Color(0xFF8B0000), Color(0xFF5C0000)]),
                  onTap: () => _showDetailDialog(
                    'Total Diskon & Potongan',
                    'Semua bentuk pengurangan revenue',
                    Icons.discount_rounded,
                    const Color(0xFF8B0000),
                    [
                      _DetailItem(
                        title: 'Komplain (Refund 30%)',
                        value: 'Rp ${_f(_complaintLoss)}',
                        description: 'Pengembalian dana 30% dari harga produk karena komplain. Rumus: harga × 0.3',
                        color: AppColors.error,
                      ),
                      _DetailItem(
                        title: 'Ongkir Gratis',
                        value: 'Rp ${_f(_shippingLoss)}',
                        description: 'Selisih ongkir yang dibayar toko (promo gratis ongkir)',
                        color: AppColors.error,
                      ),
                      _DetailItem(
                        title: 'Diskon Voucher',
                        value: 'Rp ${_f(_voucherLoss)}',
                        description: 'Potongan harga dari voucher yang dipakai customer',
                        color: AppColors.error,
                      ),
                      _DetailItem(
                        title: 'Diskon Dompet (2%)',
                        value: 'Rp ${_f(_walletLoss)}',
                        description: 'Diskon 2% dari total belanja yang dibayar dari dompet digital RC',
                        color: AppColors.error,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Fee Admin',
                  subtitle: 'Keuntungan dari top-up',
                  value: 'Rp ${_f(_adminFeeProfit)}',
                  icon: Icons.account_balance_wallet_outlined,
                  gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF0D47A1)]),
                  onTap: () => _showDetailDialog(
                    'Fee Admin',
                    'Keuntungan dari setiap top-up wallet',
                    Icons.account_balance_wallet_outlined,
                    const Color(0xFF1565C0),
                    [
                      _DetailItem(
                        title: 'Total Fee Admin',
                        value: 'Rp ${_f(_adminFeeProfit)}',
                        description: 'Fee admin dari setiap top-up wallet',
                      ),
                      _DetailItem(
                        title: 'Penjelasan',
                        value: '',
                        description: 'Setiap kali user top-up wallet, kami dapat fee admin. Fee ini menambah keuntungan bersih kami.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // === ROW 4: Stats ===
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Total Transaksi',
                  subtitle: 'Semua pesanan',
                  value: '$_totalOrders',
                  icon: Icons.receipt_long_rounded,
                  gradient: const LinearGradient(colors: [Color(0xFF3D3D3D), Color(0xFF1A1A1A)]),
                  onTap: () => _showDetailDialog(
                    'Total Transaksi',
                    'Semua pesanan dalam sistem',
                    Icons.receipt_long_rounded,
                    const Color(0xFF3D3D3D),
                    [
                      _DetailItem(
                        title: 'Total Pesanan',
                        value: '$_totalOrders',
                        description: 'Semua pesanan (semua status)',
                      ),
                      _DetailItem(
                        title: 'Pesanan Selesai',
                        value: '${delivered.length}',
                        description: 'Pesanan yang sudah diterima customer',
                        color: AppColors.success,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Rata-rata Harian',
                  subtitle: 'Revenue / 30 hari',
                  value: 'Rp ${_f(_avgDailyRevenue)}',
                  icon: Icons.bar_chart_rounded,
                  gradient: const LinearGradient(colors: [Color(0xFF2D2D2D), Color(0xFF0A0A0A)]),
                  onTap: () => _showDetailDialog(
                    'Rata-rata Revenue Harian',
                    'Estimasi revenue per hari',
                    Icons.bar_chart_rounded,
                    const Color(0xFF2D2D2D),
                    [
                      _DetailItem(
                        title: 'Revenue Produk',
                        value: 'Rp ${_f(_productRevenue)}',
                      ),
                      _DetailItem(
                        title: 'Jumlah Pesanan Selesai',
                        value: '${delivered.length}',
                      ),
                      _DetailItem(
                        title: 'Rata-rata per Hari',
                        value: 'Rp ${_f(_avgDailyRevenue)}',
                        description: 'Revenue ÷ 30 hari',
                        color: AppColors.pitchBlack,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // === CHART: Revenue Trend 7 Days (Colored) ===
          _TrendChartCard(
            title: 'Tren Revenue 7 Hari',
            icon: Icons.show_chart_rounded,
            trendData: _getTrendData(),
            maxValue: _getMaxTrendValue(),
            trendDays: _getTrendDays(),
          ),
          const SizedBox(height: 16),

          // === CHART: Metode Bayar ===
          _ChartCard(
            title: 'Metode Bayar',
            icon: Icons.pie_chart_rounded,
            height: 220,
            child: _buildPaymentChart(orders),
          ),
          const SizedBox(height: 24),

          // Recent Transactions
          _buildRecentTransactions(orders),
          const SizedBox(height: 32),
        ],
      ),
    ),
    );
  }

  // Helper methods for trend chart
  List<DateTime> _getTrendDays() {
    return List.generate(7, (i) {
      return DateTime.now().subtract(Duration(days: 6 - i));
    });
  }

  Map<int, double> _getTrendData() {
    final days = _getTrendDays();
    final delivered = _db.getOrders().where((o) => o.status == OrderStatus.delivered).toList();
    final Map<int, double> data = {};
    for (int i = 0; i < days.length; i++) {
      final day = days[i];
      final dayRevenue = delivered
          .where((o) {
            final d = o.deliveredDate;
            return d != null && d.day == day.day && d.month == day.month && d.year == day.year;
          })
          .fold<double>(0, (s, o) => s + (o.totalPrice - o.shippingCost));
      data[i] = dayRevenue;
    }
    return data;
  }

  double _getMaxTrendValue() {
    final data = _getTrendData();
    double max = 0;
    for (var v in data.values) {
      if (v > max) max = v;
    }
    return max;
  }

  Widget _buildPaymentChart(List<OrderModel> orders) {
    final qris = orders.where((o) => o.paymentMethod == PaymentMethod.qris).length.toDouble();
    final cod = orders.where((o) => o.paymentMethod == PaymentMethod.cod).length.toDouble();
    if (qris == 0 && cod == 0) {
      return const Center(child: Text('Belum ada data', style: TextStyle(fontSize: 12, color: AppColors.softGrey)));
    }

    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(value: qris, title: 'QRIS', color: AppColors.pitchBlack, radius: 50, titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.pureWhite)),
          PieChartSectionData(value: cod, title: 'COD', color: AppColors.softGrey, radius: 50, titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.pureWhite)),
        ],
        sectionsSpace: 3,
        centerSpaceRadius: 30,
        pieTouchData: PieTouchData(
          touchCallback: (event, pieTouchResponse) {},
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(List<OrderModel> orders) {
    final recent = orders.take(5).toList();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(gradient: AppColors.softBlackGradient, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.receipt_long_rounded, color: AppColors.pureWhite, size: 16),
                ),
                const SizedBox(width: 10),
                const Text('Transaksi Terbaru', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.pitchBlack)),
                const Spacer(),
                Text('${orders.length} total', style: const TextStyle(fontSize: 12, color: AppColors.softGrey)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderGrey),
          ...recent.map((order) => _buildTransactionRow(order)),
          if (orders.length > 5)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text('+ ${orders.length - 5} transaksi lainnya', style: const TextStyle(fontSize: 12, color: AppColors.softGrey)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(OrderModel order) {
    final statusColors = {
      OrderStatus.pending: const Color(0xFFFF9800),
      OrderStatus.paid: const Color(0xFF2196F3),
      OrderStatus.processing: AppColors.pitchBlack,
      OrderStatus.shipped: AppColors.pitchBlack,
      OrderStatus.delivered: const Color(0xFF43A047),
      OrderStatus.cancelled: const Color(0xFFE53935),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderGrey.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.lightGrey, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(order.orderNumber, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.softGrey))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.userName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.pitchBlack)),
                const SizedBox(height: 2),
                Text('${order.items.length} item • ${order.paymentMethod.displayName}', style: const TextStyle(fontSize: 11, color: AppColors.softGrey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rp ${_f(order.totalPrice)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.pitchBlack)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (statusColors[order.status] ?? AppColors.softGrey).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(order.status.displayName, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: statusColors[order.status] ?? AppColors.softGrey)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _f(double n) => n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}

// Helper class for detail items
class _DetailItem {
  final String title;
  final String value;
  final String? description;
  final Color? color;

  _DetailItem({
    required this.title,
    required this.value,
    this.description,
    this.color,
  });
}

class _TrendChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Map<int, double> trendData;
  final double maxValue;
  final List<DateTime> trendDays;

  const _TrendChartCard({
    required this.title,
    required this.icon,
    required this.trendData,
    required this.maxValue,
    required this.trendDays,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppColors.softBlackGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.pureWhite, size: 14),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.pitchBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue > 0 ? maxValue * 1.2 : 100000,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = trendDays[group.x.toInt()];
                      return BarTooltipItem(
                        '${day.day}/${day.month}\nRp ${_fmt(rod.toY)}',
                        const TextStyle(
                          color: AppColors.pureWhite,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= trendDays.length) return const SizedBox();
                        final day = trendDays[idx];
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(fontSize: 10, color: AppColors.softGrey),
                          ),
                        );
                      },
                      reservedSize: 20,
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: trendData.entries.map((entry) {
                  final isHigh = entry.value >= (maxValue * 0.7);
                  final isMedium = entry.value >= (maxValue * 0.3) && entry.value < (maxValue * 0.7);
                  final hasData = entry.value > 0;

                  Color barColor;
                  if (!hasData) {
                    barColor = AppColors.lightGrey;
                  } else if (isHigh) {
                    barColor = const Color(0xFF2E7D32); // Green
                  } else if (isMedium) {
                    barColor = const Color(0xFFF9A825); // Yellow
                  } else {
                    barColor = const Color(0xFFE53935); // Red
                  }

                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value > 0 ? entry.value : 5,
                        color: barColor,
                        width: 24,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: const Color(0xFF2E7D32), label: 'Tinggi'),
              const SizedBox(width: 16),
              _LegendItem(color: const Color(0xFFF9A825), label: 'Sedang'),
              const SizedBox(width: 16),
              _LegendItem(color: const Color(0xFFE53935), label: 'Rendah'),
              const SizedBox(width: 16),
              _LegendItem(color: AppColors.lightGrey, label: 'Kosong'),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double n) => n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.softGrey),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.pitchBlack.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.pureWhite.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: AppColors.pureWhite, size: 20),
                ),
                const Spacer(),
                Icon(Icons.touch_app, color: AppColors.pureWhite.withValues(alpha: 0.5), size: 16),
              ],
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.pureWhite, letterSpacing: -0.3)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, color: AppColors.pureWhite.withValues(alpha: 0.7))),
            Text(subtitle, style: TextStyle(fontSize: 10, color: AppColors.pureWhite.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final double height;
  final Widget child;
  const _ChartCard({required this.title, required this.icon, required this.height, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: AppColors.pitchBlack.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(gradient: AppColors.softBlackGradient, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: AppColors.pureWhite, size: 14),
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.pitchBlack)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(height: height - 60, child: child),
        ],
      ),
    );
  }
}
