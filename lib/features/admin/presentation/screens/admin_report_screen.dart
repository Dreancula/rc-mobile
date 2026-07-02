import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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

    // Generate 7 days for trend chart
    final trendDays = List.generate(7, (i) {
      return DateTime.now().subtract(Duration(days: 6 - i));
    });

    final Map<int, double> trendData = {};
    double maxTrendValue = 0;
    for (int i = 0; i < trendDays.length; i++) {
      final day = trendDays[i];
      final dayRevenue = r.dailySummaries.entries
          .where((e) =>
              e.key.year == day.year &&
              e.key.month == day.month &&
              e.key.day == day.day)
          .fold<double>(0, (s, e) => s + e.value.revenue);
      trendData[i] = dayRevenue;
      if (dayRevenue > maxTrendValue) maxTrendValue = dayRevenue;
    }

    return RefreshIndicator(
      color: AppColors.pitchBlack,
      onRefresh: () async => _loadData(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // === ROW 1: Revenue & Shipping ===
            _StatRow(
              children: [
                _StatCard(
                  title: 'Revenue Produk',
                  value: 'Rp ${_f(r.totalRevenue)}',
                  icon: Icons.trending_up_rounded,
                  gradient: const LinearGradient(colors: [Color(0xFF2D2D2D), Color(0xFF0A0A0A)]),
                  onTap: () => _showFinancialDetail(
                    'Revenue Produk',
                    'Pendapatan dari penjualan produk (EXCLUDE ongkir)',
                    Icons.trending_up_rounded,
                    const Color(0xFF2D2D2D),
                    [
                      _DetailItem(title: 'Total Harga Produk', value: 'Rp ${_f(r.totalRevenue)}', description: 'Total harga produk yang terjual'),
                      _DetailItem(title: 'Rumus', value: 'Harga - Ongkir', color: AppColors.softGrey),
                      _DetailItem(title: 'Kenapa exclude ongkir?', value: '', description: 'Ongkir adalah pass-through ke kurir, bukan revenue kami'),
                    ],
                  ),
                ),
                _StatCard(
                  title: 'Ongkir',
                  value: 'Rp ${_f(r.totalShippingCollected)}',
                  icon: Icons.local_shipping_rounded,
                  gradient: const LinearGradient(colors: [Color(0xFF5D4037), Color(0xFF3E2723)]),
                  onTap: () => _showFinancialDetail(
                    'Ongkir (Pass-through)',
                    'Uang ongkir yang dikumpulkan untuk kurir',
                    Icons.local_shipping_rounded,
                    const Color(0xFF5D4037),
                    [
                      _DetailItem(title: 'Total Ongkir', value: 'Rp ${_f(r.totalShippingCollected)}', description: 'Total ongkir dari semua pesanan selesai'),
                      _DetailItem(title: 'Status', value: 'Pass-through', color: AppColors.warning),
                      _DetailItem(title: 'Penjelasan', value: '', description: 'Uang ongkir bukan revenue kami. Nanti dibayar ke pihak ketiga (kurir).'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // === ROW 2: Gross Sales & Net Profit ===
            _StatRow(
              children: [
                _StatCard(
                  title: 'Total Penjualan',
                  value: 'Rp ${_f(r.totalGrossSales)}',
                  icon: Icons.account_balance_wallet_rounded,
                  gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF0D1442)]),
                  onTap: () => _showFinancialDetail(
                    'Total Penjualan Kotor',
                    'Total semua uang yang masuk (gross sales)',
                    Icons.account_balance_wallet_rounded,
                    const Color(0xFF1A237E),
                    [
                      _DetailItem(title: 'Gross Sales', value: 'Rp ${_f(r.totalGrossSales)}', description: 'Total semua transaksi'),
                      _DetailItem(title: 'Rumus', value: 'Revenue + Ongkir', color: AppColors.softGrey),
                    ],
                  ),
                ),
                _StatCard(
                  title: 'Keuntungan Bersih',
                  value: 'Rp ${_f(r.netSavings > 0 ? r.netSavings : 0)}',
                  icon: Icons.savings_rounded,
                  gradient: r.netSavings >= 0
                      ? const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF0D3B0F)])
                      : const LinearGradient(colors: [Color(0xFFC62828), Color(0xFF8B0000)]),
                  onTap: () => _showFinancialDetail(
                    'Keuntungan Bersih',
                    'Profit bersih setelah semua potongan',
                    Icons.savings_rounded,
                    r.netSavings >= 0 ? const Color(0xFF1B5E20) : const Color(0xFFC62828),
                    [
                      _DetailItem(title: 'Revenue Produk', value: 'Rp ${_f(r.totalRevenue)}', color: AppColors.success),
                      _DetailItem(title: 'Total Diskon/Potongan', value: '- Rp ${_f(r.totalLoss)}', color: AppColors.error),
                      _DetailItem(title: 'Fee Admin', value: '+ Rp ${_f(r.totalAdminFeeProfit)}', color: AppColors.info),
                      _DetailItem(title: 'Keuntungan Bersih', value: 'Rp ${_f(r.netSavings)}', description: 'Revenue - Diskon + Fee Admin'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // === ROW 3: Discounts & Fee Admin ===
            _StatRow(
              children: [
                _StatCard(
                  title: 'Total Diskon',
                  value: 'Rp ${_f(r.totalLoss)}',
                  icon: Icons.discount_rounded,
                  gradient: const LinearGradient(colors: [Color(0xFF8B0000), Color(0xFF5C0000)]),
                  onTap: () => _showFinancialDetail(
                    'Total Diskon & Potongan',
                    'Semua bentuk pengurangan revenue',
                    Icons.discount_rounded,
                    const Color(0xFF8B0000),
                    [
                      _DetailItem(title: 'Komplain (Refund 30%)', value: 'Rp ${_f(r.totalLossFromComplaints)}', description: 'Pengembalian dana 30% dari harga produk karena komplain', color: AppColors.error),
                      _DetailItem(title: 'Ongkir Gratis', value: 'Rp ${_f(r.totalShippingLoss)}', description: 'Selisih ongkir yang dibayar toko (promo gratis ongkir)', color: AppColors.error),
                      _DetailItem(title: 'Diskon Voucher', value: 'Rp ${_f(r.totalVoucherLoss)}', description: 'Potongan harga dari voucher yang dipakai customer', color: AppColors.error),
                      _DetailItem(title: 'Diskon Dompet (2%)', value: 'Rp ${_f(r.totalWalletDiscountLoss)}', description: 'Diskon 2% dari total belanja yang dibayar dari dompet digital RC', color: AppColors.error),
                    ],
                  ),
                ),
                _StatCard(
                  title: 'Fee Admin',
                  value: 'Rp ${_f(r.totalAdminFeeProfit)}',
                  icon: Icons.account_balance_wallet_outlined,
                  gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF0D47A1)]),
                  onTap: () => _showFinancialDetail(
                    'Fee Admin',
                    'Keuntungan dari setiap top-up wallet',
                    Icons.account_balance_wallet_outlined,
                    const Color(0xFF1565C0),
                    [
                      _DetailItem(title: 'Total Fee Admin', value: 'Rp ${_f(r.totalAdminFeeProfit)}', description: 'Fee admin dari setiap top-up wallet'),
                      _DetailItem(title: 'Penjelasan', value: '', description: 'Setiap kali user top-up wallet, kami dapat fee admin. Fee ini menambah keuntungan bersih kami.'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // === ROW 4: Stats ===
            _StatRow(
              children: [
                _StatCard(
                  title: 'Total Transaksi',
                  value: '${r.totalOrders}',
                  icon: Icons.receipt_long_rounded,
                  gradient: const LinearGradient(colors: [Color(0xFF3D3D3D), Color(0xFF1A1A1A)]),
                  onTap: () => _showFinancialDetail(
                    'Total Transaksi',
                    'Semua pesanan dalam sistem',
                    Icons.receipt_long_rounded,
                    const Color(0xFF3D3D3D),
                    [
                      _DetailItem(title: 'Total Pesanan', value: '${r.totalOrders}', description: 'Semua pesanan (semua status)'),
                      _DetailItem(title: 'Pesanan Selesai', value: '${r.deliveredOrders}', description: 'Pesanan yang sudah diterima customer', color: AppColors.success),
                    ],
                  ),
                ),
                _StatCard(
                  title: 'Rata-rata Transaksi',
                  value: 'Rp ${_f(r.averageOrderValue)}',
                  icon: Icons.bar_chart_rounded,
                  gradient: const LinearGradient(colors: [Color(0xFF2D2D2D), Color(0xFF0A0A0A)]),
                  onTap: () => _showFinancialDetail(
                    'Rata-rata per Transaksi',
                    'Revenue rata-rata per pesanan',
                    Icons.bar_chart_rounded,
                    const Color(0xFF2D2D2D),
                    [
                      _DetailItem(title: 'Revenue Produk', value: 'Rp ${_f(r.totalRevenue)}'),
                      _DetailItem(title: 'Pesanan Selesai', value: '${r.deliveredOrders}'),
                      _DetailItem(title: 'Rata-rata', value: 'Rp ${_f(r.averageOrderValue)}', description: 'Revenue ÷ Pesanan Selesai'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // === TREND CHART 7 DAYS ===
            _TrendChartCard(
              title: 'Tren Revenue 7 Hari',
              icon: Icons.show_chart_rounded,
              trendData: trendData,
              maxValue: maxTrendValue,
              trendDays: trendDays,
            ),
            const SizedBox(height: 12),

            // === Payment Methods ===
            _InfoCard(
              title: 'Revenue per Metode Bayar',
              icon: Icons.payment_rounded,
              children: [
                _Info(label: 'QRIS', value: 'Rp ${_f(r.qrisRevenue)}'),
                _Info(label: 'Dompet Digital', value: 'Rp ${_f(r.walletRevenue)}'),
                _Info(label: 'COD', value: 'Rp ${_f(r.codRevenue)}'),
              ],
            ),
            const SizedBox(height: 12),

            // === Category ===
            _InfoCard(
              title: 'Revenue per Kategori',
              icon: Icons.category_rounded,
              children: r.revenueByCategory.entries.isEmpty
                  ? [_Info(label: 'Belum ada data', value: '-')]
                  : r.revenueByCategory.entries.map((e) => _Info(label: e.key, value: 'Rp ${_f(e.value)}')).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Show financial detail dialog
  void _showFinancialDetail(String title, String subtitle, IconData icon, Color color, List<_DetailItem> items) {
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
                  gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
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
                          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.pureWhite)),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.pureWhite.withValues(alpha: 0.8))),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8, height: 8,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(color: item.color ?? AppColors.softGrey, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.pitchBlack)),
                          if (item.description != null) ...[
                            const SizedBox(height: 2),
                            Text(item.description!, style: const TextStyle(fontSize: 11, color: AppColors.softGrey)),
                          ],
                        ],
                      ),
                    ),
                    Text(item.value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: item.color ?? AppColors.pitchBlack)),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pitchBlack,
                    foregroundColor: AppColors.pureWhite,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

// ===================== NEW HELPER CLASSES =====================

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

// StatCard with tap to show detail
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.pitchBlack.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: AppColors.pureWhite, size: 18),
                  ),
                  const Spacer(),
                  Icon(Icons.touch_app, color: AppColors.pureWhite.withValues(alpha: 0.5), size: 14),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.pureWhite,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.pureWhite.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Trend Chart Card with colored bars (red/green based on value)
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
                  final isLow = entry.value > 0 && entry.value < (maxValue * 0.3);
                  final hasData = entry.value > 0;

                  Color barColor;
                  if (!hasData) {
                    barColor = AppColors.lightGrey;
                  } else if (isHigh) {
                    barColor = const Color(0xFF2E7D32); // Green - high
                  } else if (isMedium) {
                    barColor = const Color(0xFFF9A825); // Yellow/Amber - medium
                  } else {
                    barColor = const Color(0xFFE53935); // Red - low
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
