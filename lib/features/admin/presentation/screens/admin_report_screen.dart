import 'package:flutter/material.dart';
import 'package:rc_mobile_v2/core/database/hive_db.dart';
import 'package:rc_mobile_v2/core/theme/app_colors.dart';
import 'package:rc_mobile_v2/features/admin/data/services/report_service.dart';
import 'package:rc_mobile_v2/features/admin/data/services/pdf_generator.dart';
import 'package:rc_mobile_v2/features/home/domain/models/order_model.dart';

class AdminReportScreen extends StatefulWidget {
  final HiveDb db;
  const AdminReportScreen({super.key, required this.db});

  @override
  State<AdminReportScreen> createState() => _AdminReportScreenState();
}

class _AdminReportScreenState extends State<AdminReportScreen>
    with SingleTickerProviderStateMixin {
  late final ReportService _service;
  late TabController _tabController;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _statusFilter = 'Semua';

  FinancialReport? _financialReport;
  TransactionReport? _transactionReport;
  ProductReport? _productReport;
  DailyRecapReport? _dailyRecapReport;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _service = ReportService(widget.db);
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    _financialReport = _service.getFinancialReport(
      startDate: _startDate,
      endDate: _endDate,
    );
    _transactionReport = _service.getTransactionReport(
      startDate: _startDate,
      endDate: _endDate,
      statusFilter: _statusFilter,
    );
    _productReport = _service.getProductReport();
    _dailyRecapReport = _service.getDailyRecapReport(
      _startDate.year,
      _startDate.month,
    );
    setState(() {});
  }

  String get _dateLabel =>
      '${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year}';

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.pitchBlack,
            surface: AppColors.pureWhite,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final ts = '${now.year}${now.month}${now.day}_${now.hour}${now.minute}';
      switch (_tabController.index) {
        case 0:
          if (_financialReport != null) {
            final pdf = await PdfGenerator.generateFinancialReport(
              _financialReport!,
            );
            await PdfGenerator.saveAndOpenPdf(pdf, 'laporan_keuangan_$ts.pdf');
          }
        case 1:
          if (_transactionReport != null) {
            final pdf = await PdfGenerator.generateTransactionReport(
              _transactionReport!,
            );
            await PdfGenerator.saveAndOpenPdf(pdf, 'laporan_transaksi_$ts.pdf');
          }
        case 2:
          if (_productReport != null) {
            final pdf = await PdfGenerator.generateProductReport(
              _productReport!,
            );
            await PdfGenerator.saveAndOpenPdf(pdf, 'laporan_produk_$ts.pdf');
          }
        case 3:
          if (_dailyRecapReport != null) {
            final pdf = await PdfGenerator.generateDailyRecapReport(
              _dailyRecapReport!,
            );
            await PdfGenerator.saveAndOpenPdf(pdf, 'rekap_harian_$ts.pdf');
          }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal export PDF: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  // ===================== HEADER (TETAP SAMA) =====================

  Widget _buildHeader() {
    return Container(
      color: AppColors.pureWhite,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.softBlackGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: AppColors.pureWhite,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Laporan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.pitchBlack,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              _PdfButton(
                loading: _loading,
                onTap: _loading ? null : _exportPdf,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildFilterRow(),
        ],
      ),
    );
  }

  // ===================== FILTER ROW (DIPERBAIKI) =====================

  Widget _buildFilterRow() {
    final isProduk = _tabController.index == 2;
    final isTransaksi = _tabController.index == 1;

    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // ===== DATE PICKER =====
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: isProduk ? null : _pickDateRange,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isProduk ? AppColors.borderGrey : Colors.transparent,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range_rounded,
                      size: 16,
                      color: isProduk
                          ? AppColors.softGrey
                          : AppColors.pitchBlack,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isProduk ? 'Semua Waktu' : _dateLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isProduk
                              ? AppColors.softGrey
                              : AppColors.pitchBlack,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isProduk)
                      const Icon(
                        Icons.expand_more_rounded,
                        size: 18,
                        color: AppColors.softGrey,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ===== SPACER =====
          const SizedBox(width: 8),

          // ===== BULAN INI BUTTON =====
          if (!isProduk)
            GestureDetector(
              onTap: () {
                final now = DateTime.now();
                setState(() {
                  _startDate = DateTime(now.year, now.month, 1);
                  _endDate = now;
                });
                _loadData();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.blackGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Bulan Ini',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.pureWhite,
                  ),
                ),
              ),
            ),

          // ===== STATUS DROPDOWN (HANYA UNTUK TAB TRANSAKSI) =====
          if (isTransaksi) ...[
            const SizedBox(width: 8),
            _StatusDropdown(
              value: _statusFilter,
              onChange: (v) {
                setState(() => _statusFilter = v);
                _loadData();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.pureWhite,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.pureWhite,
        unselectedLabelColor: AppColors.softGrey,
        indicator: BoxDecoration(
          gradient: AppColors.blackGradient,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        tabs: const [
          Tab(text: 'Keuangan'),
          Tab(text: 'Transaksi'),
          Tab(text: 'Produk'),
          Tab(text: 'Rekap Harian'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.pitchBlack),
      );
    }
    return TabBarView(
      controller: _tabController,
      children: [
        _buildFinancialTab(),
        _buildTransactionTab(),
        _buildProductTab(),
        _buildDailyRecapTab(),
      ],
    );
  }

  // ===================== FINANCIAL TAB =====================

  Widget _buildFinancialTab() {
    final r = _financialReport;
    if (r == null) return const SizedBox();

    // ===== MEKANIK HARIAN BERDASARKAN BULAN =====
    // Generate semua tanggal dalam rentang (termasuk yang tidak ada data)
    final allDates = <DateTime>[];
    DateTime current = _startDate;
    while (current.isBefore(_endDate) || current.isAtSameMomentAs(_endDate)) {
      allDates.add(current);
      current = current.add(const Duration(days: 1));
    }

    // Map data ke semua tanggal
    final Map<DateTime, DailySummary> fullMap = {};
    for (var date in allDates) {
      final key = DateTime(date.year, date.month, date.day);
      if (r.dailySummaries.containsKey(key)) {
        fullMap[key] = r.dailySummaries[key]!;
      } else {
        fullMap[key] = DailySummary(date: key, revenue: 0, orderCount: 0);
      }
    }

    final sortedEntries = fullMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final totalDailyRevenue = sortedEntries.fold<double>(
      0,
      (s, e) => s + e.value.revenue,
    );
    final daysActive = sortedEntries.where((e) => e.value.revenue > 0).length;
    final bestDay = sortedEntries.isEmpty
        ? null
        : sortedEntries.reduce(
            (a, b) => a.value.revenue >= b.value.revenue ? a : b,
          );

    return RefreshIndicator(
      color: AppColors.pitchBlack,
      onRefresh: () async => _loadData(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _StatRow(
              children: [
                _MiniStatCard(
                  icon: Icons.trending_up_rounded,
                  value: 'Rp ${_f(r.totalRevenue)}',
                  label: 'Total Pendapatan',
                  color: 0xFF2D2D2D,
                ),
                _MiniStatCard(
                  icon: Icons.savings_rounded,
                  value: 'Rp ${_f(r.netSavings)}',
                  label: 'Tabungan Bersih',
                  color: 0xFF1B5E20,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _StatRow(
              children: [
                _MiniStatCard(
                  icon: Icons.trending_down_rounded,
                  value: 'Rp ${_f(r.totalLoss)}',
                  label: 'Total Kerugian',
                  color: 0xFF8B0000,
                ),
                _MiniStatCard(
                  icon: Icons.account_balance_wallet_outlined,
                  value: 'Rp ${_f(r.totalAdminFeeProfit)}',
                  label: 'Keuntungan Admin',
                  color: 0xFF1565C0,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _InfoCard(
              title: 'Rincian Kerugian',
              icon: Icons.info_outline,
              children: [
                _Info(label: 'Komplain', value: 'Rp ${_f(r.totalLossFromComplaints)}'),
                _Info(label: 'Ongkir Gratis', value: 'Rp ${_f(r.totalShippingLoss)}'),
                _Info(label: 'Diskon Voucher', value: 'Rp ${_f(r.totalVoucherLoss)}'),
                _Info(label: 'Diskon Dompet', value: 'Rp ${_f(r.totalWalletDiscountLoss)}'),
              ],
            ),
            const SizedBox(height: 10),
            _StatRow(
              children: [
                _MiniStatCard(
                  icon: Icons.receipt_long_rounded,
                  value: '${r.totalOrders}',
                  label: 'Total Pesanan',
                  color: 0xFF3D3D3D,
                ),
                _MiniStatCard(
                  icon: Icons.bar_chart_rounded,
                  value: 'Rp ${_f(r.averageOrderValue)}',
                  label: 'Rata-rata per Transaksi',
                  color: 0xFF2D2D2D,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Pendapatan per Metode Bayar',
              icon: Icons.payment_rounded,
              children: [
                _Info(label: 'QRIS', value: 'Rp ${_f(r.qrisRevenue)}'),
                _Info(
                  label: 'Dompet Digital',
                  value: 'Rp ${_f(r.walletRevenue)}',
                ),
                _Info(label: 'COD', value: 'Rp ${_f(r.codRevenue)}'),
              ],
            ),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Pendapatan per Kategori',
              icon: Icons.category_rounded,
              children: r.revenueByCategory.entries.isEmpty
                  ? [_Info(label: 'Belum ada data', value: '-')]
                  : r.revenueByCategory.entries
                        .map(
                          (e) =>
                              _Info(label: e.key, value: 'Rp ${_f(e.value)}'),
                        )
                        .toList(),
            ),
            const SizedBox(height: 12),
            _buildDailyCompactCard(
              totalDailyRevenue,
              daysActive,
              sortedEntries.length,
              bestDay,
              sortedEntries,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyCompactCard(
    double total,
    int activeDays,
    int totalDays,
    MapEntry<DateTime, DailySummary>? bestDay,
    List<MapEntry<DateTime, DailySummary>> entries,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: AppColors.softBlackGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.pureWhite,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pendapatan Harian (${_startDate.day} ${_monthName(_startDate.month)} - ${_endDate.day} ${_monthName(_endDate.month)})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.pitchBlack,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderGrey),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _DailyStat(label: 'Total', value: 'Rp ${_f(total)}'),
                    const SizedBox(width: 16),
                    _DailyStat(
                      label: 'Hari Aktif',
                      value: '$activeDays / $totalDays',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _DailyStat(
                      label: 'Rata-rata',
                      value:
                          'Rp ${_f(activeDays > 0 ? total / activeDays : 0)}',
                    ),
                    const SizedBox(width: 16),
                    if (bestDay != null)
                      _DailyStat(
                        label: 'Hari Tertinggi',
                        value: 'Rp ${_f(bestDay.value.revenue)}',
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderGrey),
          InkWell(
            onTap: () => _showDailyDetail(entries),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(14),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: AppColors.softGrey,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Lihat Rincian Lengkap',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.softGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDailyDetail(List<MapEntry<DateTime, DailySummary>> entries) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: AppColors.softBlackGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.pureWhite,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Rincian Harian (${_startDate.day} ${_monthName(_startDate.month)} - ${_endDate.day} ${_monthName(_endDate.month)})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.pitchBlack,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.pitchBlack,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderGrey),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: entries.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: AppColors.borderGrey),
                itemBuilder: (_, i) {
                  final e = entries[i];
                  final hasData = e.value.revenue > 0 || e.value.orderCount > 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: hasData
                                ? AppColors.pitchBlack
                                : AppColors.lightGrey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${e.value.date.day}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: hasData
                                    ? AppColors.pureWhite
                                    : AppColors.softGrey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${e.value.date.day} ${_monthName(e.value.date.month)} ${e.value.date.year}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: hasData
                                      ? AppColors.pitchBlack
                                      : AppColors.softGrey,
                                ),
                              ),
                              if (e.value.orderCount > 0)
                                Text(
                                  '${e.value.orderCount} pesanan',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.softGrey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          hasData ? 'Rp ${_f(e.value.revenue)}' : '-',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: hasData
                                ? AppColors.pitchBlack
                                : AppColors.softGrey,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== TRANSACTION TAB =====================

  Widget _buildTransactionTab() {
    final r = _transactionReport;
    if (r == null) return const SizedBox();

    return RefreshIndicator(
      color: AppColors.pitchBlack,
      onRefresh: () async => _loadData(),
      child: r.orders.isEmpty
          ? const Center(
              child: Text(
                'Belum ada transaksi',
                style: TextStyle(fontSize: 14, color: AppColors.softGrey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: r.orders.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.pureWhite,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderGrey),
                          ),
                          child: Text(
                            '${r.totalOrders} transaksi',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.softGrey,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Rp ${_f(r.totalRevenue)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pitchBlack,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return _OrderCard(order: r.orders[index - 1]);
              },
            ),
    );
  }

  // ===================== PRODUCT TAB =====================

  Widget _buildProductTab() {
    final r = _productReport;
    if (r == null) return const SizedBox();

    return RefreshIndicator(
      color: AppColors.pitchBlack,
      onRefresh: () async => _loadData(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _StatRow(
              children: [
                _MiniStatCard(
                  icon: Icons.inventory_2_rounded,
                  value: '${r.totalProducts}',
                  label: 'Total Produk',
                  color: 0xFF2D2D2D,
                ),
                _MiniStatCard(
                  icon: Icons.shopping_cart_rounded,
                  value: '${r.totalSold}',
                  label: 'Total Terjual',
                  color: 0xFF333333,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _WideStatCard(
              icon: Icons.monetization_on_rounded,
              value: 'Rp ${_f(r.totalRevenue)}',
              label: 'Total Revenue Produk',
              color: 0xFF1B5E20,
            ),
            const SizedBox(height: 16),
            if (r.items.isEmpty)
              const Center(
                child: Text(
                  'Belum ada produk',
                  style: TextStyle(fontSize: 14, color: AppColors.softGrey),
                ),
              )
            else
              ...r.items.map(
                (item) => _ProductCard(item: item, totalSold: r.totalSold),
              ),
          ],
        ),
      ),
    );
  }

  // ===================== DAILY RECAP TAB =====================

  Widget _buildDailyRecapTab() {
    final r = _dailyRecapReport;
    if (r == null) return const SizedBox();

    final visibleDays = r.days.reversed.take(7).toList();
    final hasMore = r.days.any((d) => d.revenue > 0 || d.orderCount > 0);

    return RefreshIndicator(
      color: AppColors.pitchBlack,
      onRefresh: () async => _loadData(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _StatRow(
              children: [
                _MiniStatCard(
                  icon: Icons.monetization_on_rounded,
                  value: 'Rp ${_f(r.totalRevenue)}',
                  label: 'Total Pendapatan',
                  color: 0xFF2D2D2D,
                ),
                _MiniStatCard(
                  icon: Icons.shopping_bag_rounded,
                  value: '${r.totalOrders}',
                  label: 'Total Pesanan',
                  color: 0xFF333333,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _WideStatCard(
              icon: Icons.trending_up_rounded,
              value: 'Rp ${_f(r.averageDailyRevenue)}',
              label: 'Rata-rata Pendapatan Harian',
              color: 0xFF1B5E20,
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.borderGrey.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: AppColors.softBlackGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.history_rounded,
                            color: AppColors.pureWhite,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '7 Hari Terakhir',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.pitchBlack,
                          ),
                        ),
                        const Spacer(),
                        if (hasMore)
                          Text(
                            '${r.days.length} hari',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.softGrey,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.borderGrey),
                  ...visibleDays.map(
                    (d) => _RecapRow(day: d, monthName: r.monthName, r: r),
                  ),
                  if (hasMore) ...[
                    const Divider(height: 1, color: AppColors.borderGrey),
                    InkWell(
                      onTap: () => _showMonthlyDetail(r),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(14),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.expand_more_rounded,
                              size: 18,
                              color: AppColors.softGrey,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Lihat Rincian Lengkap',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.softGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthlyDetail(DailyRecapReport r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: AppColors.softBlackGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: AppColors.pureWhite,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Rincian ${r.monthName} ${r.year}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.pitchBlack,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.pitchBlack,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderGrey),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: r.days.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: AppColors.borderGrey),
                itemBuilder: (_, i) =>
                    _RecapRow(day: r.days[i], monthName: r.monthName, r: r),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== HELPER =====================

  String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return names[month - 1];
  }

  String _f(double n) => n
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}

// ===================== SHARED WIDGETS (SAMA) =====================

class _StatRow extends StatelessWidget {
  final List<Widget> children;
  const _StatRow({required this.children});

  @override
  Widget build(BuildContext context) {
    final list = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      list.add(Expanded(child: children[i]));
      if (i < children.length - 1) {
        list.add(const SizedBox(width: 10));
      }
    }
    return Row(children: list);
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final int color;

  const _MiniStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = Color(color);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c, c.withValues(alpha: 0.8)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _WideStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final int color;

  const _WideStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = Color(color);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c, c.withValues(alpha: 0.8)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_Info> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.pitchBlack,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderGrey),
          ...children,
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final String label;
  final String value;

  const _Info({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderGrey.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.softGrey),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.pitchBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyStat extends StatelessWidget {
  final String label;
  final String value;

  const _DailyStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.pitchBlack,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.softGrey),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusColors = {
      OrderStatus.pending: AppColors.warning,
      OrderStatus.paid: AppColors.info,
      OrderStatus.processing: AppColors.pitchBlack,
      OrderStatus.shipped: AppColors.pitchBlack,
      OrderStatus.delivered: AppColors.success,
      OrderStatus.cancelled: AppColors.error,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.softBlackGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '#${order.id.substring(order.id.length - 4)}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.pureWhite,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.pitchBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${order.items.length} item',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.softGrey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        order.paymentMethod.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.softGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rp ${_formatPrice(order.totalPrice)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.pitchBlack,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (statusColors[order.status] ?? AppColors.softGrey)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  order.status.displayName,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: statusColors[order.status] ?? AppColors.softGrey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPrice(double n) => n
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}

class _ProductCard extends StatelessWidget {
  final ProductReportItem item;
  final int totalSold;

  const _ProductCard({required this.item, required this.totalSold});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.pitchBlack,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.category,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.softGrey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniStat(label: 'Terjual', value: '${item.totalSold}'),
              const SizedBox(width: 20),
              _MiniStat(
                label: 'Revenue',
                value: 'Rp ${_fmt(item.totalRevenue)}',
              ),
              const SizedBox(width: 20),
              _MiniStat(label: 'Stok', value: '${item.stockRemaining}'),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalSold > 0 ? item.totalSold / totalSold : 0,
              backgroundColor: AppColors.lightGrey,
              valueColor: const AlwaysStoppedAnimation(AppColors.pitchBlack),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double n) => n
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.softGrey),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.pitchBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecapRow extends StatelessWidget {
  final DailySummary day;
  final String monthName;
  final DailyRecapReport r;

  const _RecapRow({
    required this.day,
    required this.monthName,
    required this.r,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = day.revenue > 0 || day.orderCount > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderGrey.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: hasData ? AppColors.pitchBlack : AppColors.lightGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${day.date.day}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: hasData ? AppColors.pureWhite : AppColors.softGrey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${day.date.day} $monthName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: hasData ? AppColors.pitchBlack : AppColors.softGrey,
              ),
            ),
          ),
          if (day.orderCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${day.orderCount}',
                style: const TextStyle(fontSize: 10, color: AppColors.softGrey),
              ),
            ),
          Text(
            hasData ? 'Rp ${_fmt(day.revenue)}' : '-',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: hasData ? AppColors.pitchBlack : AppColors.softGrey,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double n) => n
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}

// ===================== FILTER WIDGETS (DIPERBAIKI) =====================

class _StatusDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChange;

  const _StatusDropdown({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.filter_list_rounded,
            size: 16,
            color: AppColors.softGrey,
          ),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.pitchBlack,
              ),
              dropdownColor: AppColors.pureWhite,
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              items:
                  [
                        'Semua',
                        'Pending',
                        'Dibayar',
                        'Diproses',
                        'Dikirim',
                        'Selesai',
                        'Dibatalkan',
                      ]
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Text(
                              s,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (v) {
                if (v != null) onChange(v);
              },
              icon: const Icon(
                Icons.arrow_drop_down_rounded,
                size: 18,
                color: AppColors.softGrey,
              ),
              iconSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onTap;

  const _PdfButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          gradient: AppColors.softBlackGradient,
          borderRadius: BorderRadius.circular(10),
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.pureWhite,
                ),
              )
            : const Icon(
                Icons.picture_as_pdf_rounded,
                size: 18,
                color: AppColors.pureWhite,
              ),
      ),
    );
  }
}
