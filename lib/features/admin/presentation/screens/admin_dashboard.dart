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

  double _getTotalLoss() {
    return _db.getTotalLossFromComplaints();
  }

  @override
  Widget build(BuildContext context) {
    final orders = _db.getOrders();
    final delivered = orders.where((o) => o.status == OrderStatus.delivered).toList();
    final now = DateTime.now();

    final totalRevenue = delivered.fold<double>(0, (s, o) => s + o.totalPrice);
    final totalLoss = _getTotalLoss();
    final totalSavings = totalRevenue - totalLoss;
    final totalOrders = orders.length;

    final todayStr = '${now.year}-${now.month}-${now.day}';
    final todayRevenue = delivered.where((o) {
      final d = o.deliveredDate;
      return d != null && '${d.year}-${d.month}-${d.day}' == todayStr;
    }).fold<double>(0, (s, o) => s + o.totalPrice);

    final avgDaily = delivered.length > 0 ? (totalRevenue / 30) : 0.0;

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
              const Text('Analitik Keuangan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.pitchBlack, letterSpacing: -0.3)),
            ],
          ),
          const SizedBox(height: 20),
          // Financial Summary Row 1
          Row(
            children: [
              Expanded(child: _StatCard(
                title: 'Total Pendapatan',
                value: 'Rp ${_f(totalRevenue)}',
                icon: Icons.trending_up_rounded,
                gradient: const LinearGradient(colors: [Color(0xFF2D2D2D), Color(0xFF0A0A0A)]),
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                title: 'Total Kerugian',
                value: 'Rp ${_f(totalLoss)}',
                icon: Icons.trending_down_rounded,
                gradient: const LinearGradient(colors: [Color(0xFF8B0000), Color(0xFF5C0000)]),
              )),
            ],
          ),
          const SizedBox(height: 12),
          // Financial Summary Row 2
          Row(
            children: [
              Expanded(child: _StatCard(
                title: 'Tabungan Bersih',
                value: 'Rp ${_f(totalSavings > 0 ? totalSavings : 0)}',
                icon: Icons.savings_rounded,
                gradient: totalSavings >= 0
                    ? const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF0D3B0F)])
                    : const LinearGradient(colors: [Color(0xFFC62828), Color(0xFF8B0000)]),
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                title: 'Hari Ini',
                value: 'Rp ${_f(todayRevenue)}',
                icon: Icons.today_rounded,
                gradient: const LinearGradient(colors: [Color(0xFF333333), Color(0xFF1A1A1A)]),
              )),
            ],
          ),
          const SizedBox(height: 12),
          // Stats Row
          Row(
            children: [
              Expanded(child: _StatCard(
                title: 'Total Transaksi',
                value: '$totalOrders',
                icon: Icons.receipt_long_rounded,
                gradient: const LinearGradient(colors: [Color(0xFF3D3D3D), Color(0xFF1A1A1A)]),
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                title: 'Rata-rata Harian',
                value: 'Rp ${_f(avgDaily)}',
                icon: Icons.bar_chart_rounded,
                gradient: const LinearGradient(colors: [Color(0xFF2D2D2D), Color(0xFF0A0A0A)]),
              )),
            ],
          ),
          const SizedBox(height: 24),
          _ChartCard(
            title: 'Tren Pendapatan 7 Hari',
            icon: Icons.show_chart_rounded,
            height: 220,
            child: _buildRevenueChart(delivered),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ChartCard(
                  title: 'Per Kategori',
                  icon: Icons.bar_chart_rounded,
                  height: 220,
                  child: _buildCategoryChart(delivered),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ChartCard(
                  title: 'Metode Bayar',
                  icon: Icons.pie_chart_rounded,
                  height: 220,
                  child: _buildPaymentChart(orders),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildRecentTransactions(orders),
          const SizedBox(height: 32),
        ],
      ),
    ),
    );
  }

  Widget _buildRevenueChart(List<OrderModel> delivered) {
    final days = List.generate(7, (i) {
      final d = DateTime.now().subtract(Duration(days: 6 - i));
      return d;
    });

    final spots = days.map((day) {
      final total = delivered.where((o) {
        final dd = o.deliveredDate;
        return dd != null && dd.day == day.day && dd.month == day.month && dd.year == day.year;
      }).fold<double>(0, (s, o) => s + o.totalPrice);
      return FlSpot(day.day.toDouble(), total);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 500000.0,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.borderGrey.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) {
              return Text('${(value / 1000).toInt()}k', style: const TextStyle(fontSize: 10, color: AppColors.softGrey));
            }),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
              return Text('${value.toInt()}', style: const TextStyle(fontSize: 10, color: AppColors.softGrey));
            }),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.pitchBlack,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true, getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
              radius: 4,
              color: AppColors.pureWhite,
              strokeWidth: 2.5,
              strokeColor: AppColors.pitchBlack,
            )),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.pitchBlack.withValues(alpha: 0.15), AppColors.pitchBlack.withValues(alpha: 0.0)],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              return LineTooltipItem('Rp ${_f(spot.y)}', const TextStyle(color: AppColors.pureWhite, fontSize: 12, fontWeight: FontWeight.w600));
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChart(List<OrderModel> delivered) {
    final catMap = <String, double>{};
    for (final order in delivered) {
      for (final item in order.items) {
        catMap[item.category] = (catMap[item.category] ?? 0) + (item.price);
      }
    }
    if (catMap.isEmpty) {
      return const Center(child: Text('Belum ada data', style: TextStyle(fontSize: 12, color: AppColors.softGrey)));
    }
    final entries = catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = entries.first.value;

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxVal / 4,
          getDrawingHorizontalLine: (value) => FlLine(color: AppColors.borderGrey.withValues(alpha: 0.3), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= entries.length) return const SizedBox();
                final name = entries[idx].key;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(name.length > 5 ? '${name.substring(0, 5)}..' : name, style: const TextStyle(fontSize: 8, color: AppColors.softGrey)),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: entries.asMap().entries.map((e) {
          return BarChartGroupData(x: e.key, barRods: [
            BarChartRodData(toY: e.value.value, color: AppColors.pitchBlack, width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
          ]);
        }).toList(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem('Rp ${_f(rod.toY)}', const TextStyle(color: AppColors.pureWhite, fontSize: 11, fontWeight: FontWeight.w600));
            },
          ),
        ),
      ),
    );
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
            child: Center(child: Text('#${order.id.substring(order.id.length - 4)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.softGrey))),
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

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Gradient gradient;
  const _StatCard({required this.title, required this.value, required this.icon, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.pitchBlack.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.pureWhite.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.pureWhite, size: 20),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.pureWhite, letterSpacing: -0.3)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: AppColors.pureWhite.withValues(alpha: 0.7))),
        ],
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
