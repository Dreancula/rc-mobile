import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rc_mobile_v2/features/admin/data/services/report_service.dart';
import 'package:rc_mobile_v2/features/home/domain/models/order_model.dart';

class PdfGenerator {
  static const _fontColor = PdfColor.fromInt(0xFF0A0A0A);
  static const _greyColor = PdfColor.fromInt(0xFF9E9E9E);
  static const _lightGrey = PdfColor.fromInt(0xFFF0F0F0);
  static const _whiteColor = PdfColor.fromInt(0xFFFFFFFF);
  static const _darkCard = PdfColor.fromInt(0xFF1A1A1A);

  // CACHE LOGO
  static Uint8List? _cachedLogo;

  // LOAD LOGO DARI ASSETS (ASYNC)
  static Future<Uint8List> _getLogoImage() async {
    if (_cachedLogo != null) return _cachedLogo!;
    try {
      final ByteData data = await rootBundle.load('assets/images/logo.png');
      _cachedLogo = data.buffer.asUint8List();
      return _cachedLogo!;
    } catch (e) {
      // Jika logo tidak ditemukan, return empty data
      return Uint8List(0);
    }
  }

  // HEADER DENGAN LOGO DAN INFORMASI PERUSAHAAN
  static Future<pw.Widget> _buildCompanyHeader(
    pw.Font font,
    pw.Font boldFont,
  ) async {
    final logoBytes = await _getLogoImage();

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _darkCard,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Logo
          pw.Container(
            width: 60,
            height: 60,
            child: logoBytes.isNotEmpty
                ? pw.Image(pw.MemoryImage(logoBytes), width: 60, height: 60)
                : pw.SizedBox(), // Placeholder jika logo tidak ada
          ),
          pw.SizedBox(width: 16),
          // Informasi Perusahaan
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'REPUBLIK CASUAL',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 18,
                    color: _whiteColor,
                    letterSpacing: 2,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Jl. Margonda No.8, Pondok Cina, Kecamatan Beji,',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    color: _whiteColor,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Kota Depok, Jawa Barat 16424',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    color: _whiteColor,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Telp: 085694520082',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    color: _whiteColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // HEADER DENGAN TANGGAL
  static Future<pw.Widget> _buildHeader(
    String title,
    pw.Font font,
    pw.Font boldFont,
    DateTime start,
    DateTime end,
  ) async {
    final header = await _buildCompanyHeader(font, boldFont);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        header,
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: pw.BoxDecoration(
            color: _lightGrey,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 14,
                  color: _fontColor,
                ),
              ),
              pw.Text(
                '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 11,
                  color: _greyColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // HEADER TANPA TANGGAL
  static Future<pw.Widget> _buildHeaderNoDate(
    String title,
    pw.Font font,
    pw.Font boldFont,
  ) async {
    final header = await _buildCompanyHeader(font, boldFont);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        header,
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: pw.BoxDecoration(
            color: _lightGrey,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 14,
              color: _fontColor,
            ),
          ),
        ),
      ],
    );
  }

  // GENERATE FINANCIAL REPORT
  static Future<Uint8List> generateFinancialReport(
    FinancialReport report,
  ) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.leagueSpartanRegular();
    final boldFont = await PdfGoogleFonts.leagueSpartanBold();
    final header = await _buildHeader(
      'Laporan Keuangan',
      font,
      boldFont,
      report.startDate,
      report.endDate,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          header,
          pw.SizedBox(height: 24),
          _buildSummaryCards(report, font, boldFont),
          pw.SizedBox(height: 24),
          _buildSectionTitle('Ringkasan', font, boldFont),
          pw.SizedBox(height: 8),
          _buildInfoTable([
            _row(
              'Total Pendapatan',
              _formatRp(report.totalRevenue),
              boldFont,
              font,
            ),
            _row(
              'Total Kerugian',
              _formatRp(report.totalLoss),
              boldFont,
              font,
            ),
            _row(
              '  - Komplain',
              _formatRp(report.totalLossFromComplaints),
              boldFont,
              font,
            ),
            _row(
              '  - Ongkir Gratis',
              _formatRp(report.totalShippingLoss),
              boldFont,
              font,
            ),
            _row(
              '  - Diskon Voucher',
              _formatRp(report.totalVoucherLoss),
              boldFont,
              font,
            ),
            _row(
              '  - Diskon Dompet',
              _formatRp(report.totalWalletDiscountLoss),
              boldFont,
              font,
            ),
            _row(
              'Keuntungan Admin',
              _formatRp(report.totalAdminFeeProfit),
              boldFont,
              font,
            ),
            _row(
              'Tabungan Bersih',
              _formatRp(report.netSavings),
              boldFont,
              font,
            ),
            _row('Total Pesanan', '${report.totalOrders}', boldFont, font),
            _row(
              'Pesanan Selesai',
              '${report.deliveredOrders}',
              boldFont,
              font,
            ),
            _row(
              'Rata-rata per Transaksi',
              _formatRp(report.averageOrderValue),
              boldFont,
              font,
            ),
          ]),
          pw.SizedBox(height: 20),
          _buildSectionTitle('Pendapatan per Metode Bayar', font, boldFont),
          pw.SizedBox(height: 8),
          _buildInfoTable([
            _row('QRIS', _formatRp(report.qrisRevenue), boldFont, font),
            _row(
              'Dompet Digital',
              _formatRp(report.walletRevenue),
              boldFont,
              font,
            ),
            _row('COD', _formatRp(report.codRevenue), boldFont, font),
          ]),
          pw.SizedBox(height: 20),
          _buildSectionTitle('Pendapatan per Kategori', font, boldFont),
          pw.SizedBox(height: 8),
          _buildInfoTable(
            report.revenueByCategory.entries
                .map((e) => _row(e.key, _formatRp(e.value), boldFont, font))
                .toList(),
          ),
          pw.SizedBox(height: 20),
          _buildSectionTitle(
            'Pendapatan Harian (30 Hari Terakhir)',
            font,
            boldFont,
          ),
          pw.SizedBox(height: 8),
          _buildDailyTable(report.dailySummaries, font, boldFont),
          pw.SizedBox(height: 20),
          _buildFooter(font),
        ],
      ),
    );

    return pdf.save();
  }

  // GENERATE TRANSACTION REPORT
  static Future<Uint8List> generateTransactionReport(
    TransactionReport report,
  ) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.leagueSpartanRegular();
    final boldFont = await PdfGoogleFonts.leagueSpartanBold();
    final header = await _buildHeader(
      'Laporan Transaksi',
      font,
      boldFont,
      report.startDate,
      report.endDate,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          header,
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total Transaksi: ${report.totalOrders}',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 12,
                  color: _fontColor,
                ),
              ),
              pw.Text(
                'Total: ${_formatRp(report.totalRevenue)}',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 12,
                  color: _fontColor,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          _buildTransactionTable(report.orders, font, boldFont),
          pw.SizedBox(height: 20),
          _buildFooter(font),
        ],
      ),
    );

    return pdf.save();
  }

  // GENERATE PRODUCT REPORT
  static Future<Uint8List> generateProductReport(ProductReport report) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.leagueSpartanRegular();
    final boldFont = await PdfGoogleFonts.leagueSpartanBold();
    final header = await _buildHeaderNoDate('Laporan Produk', font, boldFont);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          header,
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total Produk: ${report.totalProducts}',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 12,
                  color: _fontColor,
                ),
              ),
              pw.Text(
                'Total Terjual: ${report.totalSold}',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 12,
                  color: _fontColor,
                ),
              ),
              pw.Text(
                'Total Revenue: ${_formatRp(report.totalRevenue)}',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 12,
                  color: _fontColor,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          _buildProductTable(report.items, font, boldFont),
          pw.SizedBox(height: 20),
          _buildFooter(font),
        ],
      ),
    );

    return pdf.save();
  }

  // GENERATE DAILY RECAP REPORT
  static Future<Uint8List> generateDailyRecapReport(
    DailyRecapReport report,
  ) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.leagueSpartanRegular();
    final boldFont = await PdfGoogleFonts.leagueSpartanBold();
    final header = await _buildHeaderNoDate(
      'Rekap Harian - ${report.monthName} ${report.year}',
      font,
      boldFont,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          header,
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total Pendapatan: ${_formatRp(report.totalRevenue)}',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 12,
                  color: _fontColor,
                ),
              ),
              pw.Text(
                'Total Pesanan: ${report.totalOrders}',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 12,
                  color: _fontColor,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Rata-rata Harian: ${_formatRp(report.averageDailyRevenue)}',
            style: pw.TextStyle(font: font, fontSize: 11, color: _greyColor),
          ),
          pw.SizedBox(height: 16),
          _buildDailyRecapTable(report.days, font, boldFont),
          pw.SizedBox(height: 20),
          _buildFooter(font),
        ],
      ),
    );

    return pdf.save();
  }

  // SUMMARY CARDS
  static pw.Widget _buildSummaryCards(
    FinancialReport report,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Row(
      children: [
        _card(
          'Total Pendapatan',
          _formatRp(report.totalRevenue),
          boldFont,
          font,
        ),
        pw.SizedBox(width: 12),
        _card('Kerugian', _formatRp(report.totalLoss), boldFont, font),
        pw.SizedBox(width: 12),
        _card('Bersih', _formatRp(report.netSavings), boldFont, font),
      ],
    );
  }

  static pw.Widget _card(
    String title,
    String value,
    pw.Font boldFont,
    pw.Font font,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: _darkCard,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 16,
                color: _whiteColor,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              title,
              style: pw.TextStyle(font: font, fontSize: 10, color: _whiteColor),
            ),
          ],
        ),
      ),
    );
  }

  // SECTION TITLE
  static pw.Widget _buildSectionTitle(
    String title,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: _lightGrey,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(font: boldFont, fontSize: 13, color: _fontColor),
      ),
    );
  }

  // INFO TABLE
  static pw.Widget _buildInfoTable(List<pw.Widget> rows) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _lightGrey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(children: rows),
    );
  }

  static pw.Widget _row(
    String label,
    String value,
    pw.Font boldFont,
    pw.Font font,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _lightGrey)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: font, fontSize: 11, color: _greyColor),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 11,
              color: _fontColor,
            ),
          ),
        ],
      ),
    );
  }

  // DAILY TABLE
  static pw.Widget _buildDailyTable(
    Map<DateTime, DailySummary> summaries,
    pw.Font font,
    pw.Font boldFont,
  ) {
    final entries = summaries.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return pw.Table(
      border: pw.TableBorder.all(color: _lightGrey, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _lightGrey),
          children: [
            _cell('Tanggal', boldFont, true),
            _cell('Pendapatan', boldFont, true),
            _cell('Pesanan', boldFont, true),
          ],
        ),
        ...entries.map(
          (e) => pw.TableRow(
            children: [
              _cell(
                '${e.value.date.day}/${e.value.date.month}/${e.value.date.year}',
                font,
                false,
              ),
              _cell(_formatRp(e.value.revenue), font, false),
              _cell('${e.value.orderCount}', font, false),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _cell(String text, pw.Font font, bool isHeader) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 9,
          color: _fontColor,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  // TRANSACTION TABLE
  static pw.Widget _buildTransactionTable(
    List<OrderModel> orders,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: _lightGrey, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _lightGrey),
          children: [
            _cell('ID', boldFont, true),
            _cell('Pelanggan', boldFont, true),
            _cell('Total', boldFont, true),
            _cell('Status', boldFont, true),
            _cell('Pembayaran', boldFont, true),
            _cell('Tanggal', boldFont, true),
          ],
        ),
        ...orders.map(
          (o) => pw.TableRow(
            children: [
              _cell('#${o.id.substring(o.id.length - 6)}', font, false),
              _cell(o.userName, font, false),
              _cell(_formatRp(o.totalPrice), font, false),
              _cell(o.status.displayName, font, false),
              _cell(o.paymentMethod.displayName, font, false),
              _cell(
                '${o.orderDate.day}/${o.orderDate.month}/${o.orderDate.year}',
                font,
                false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // PRODUCT TABLE
  static pw.Widget _buildProductTable(
    List<ProductReportItem> items,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: _lightGrey, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _lightGrey),
          children: [
            _cell('Produk', boldFont, true),
            _cell('Kategori', boldFont, true),
            _cell('Harga', boldFont, true),
            _cell('Terjual', boldFont, true),
            _cell('Revenue', boldFont, true),
            _cell('Stok', boldFont, true),
          ],
        ),
        ...items.map(
          (item) => pw.TableRow(
            children: [
              _cell(item.productName, font, false),
              _cell(item.category, font, false),
              _cell(_formatRp(item.price), font, false),
              _cell('${item.totalSold}', font, false),
              _cell(_formatRp(item.totalRevenue), font, false),
              _cell('${item.stockRemaining}', font, false),
            ],
          ),
        ),
      ],
    );
  }

  // DAILY RECAP TABLE
  static pw.Widget _buildDailyRecapTable(
    List<DailySummary> days,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: _lightGrey, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _lightGrey),
          children: [
            _cell('Hari', boldFont, true),
            _cell('Pendapatan', boldFont, true),
            _cell('Pesanan', boldFont, true),
          ],
        ),
        ...days.map(
          (d) => pw.TableRow(
            children: [
              _cell('${d.date.day}/${d.date.month}', font, false),
              _cell(_formatRp(d.revenue), font, false),
              _cell('${d.orderCount}', font, false),
            ],
          ),
        ),
      ],
    );
  }

  // FOOTER
  static pw.Widget _buildFooter(pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 16),
      child: pw.Column(
        children: [
          pw.Divider(color: _lightGrey),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Republik Casual',
                style: pw.TextStyle(font: font, fontSize: 9, color: _greyColor),
              ),
              pw.Text(
                'Dicetak: ${_now()}',
                style: pw.TextStyle(font: font, fontSize: 9, color: _greyColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // FORMAT RUPIAH
  static String _formatRp(double n) {
    final formatted = n
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'Rp $formatted';
  }

  // GET CURRENT TIME
  static String _now() {
    final n = DateTime.now();
    return '${n.day}/${n.month}/${n.year} ${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  // SAVE AND OPEN PDF
  static Future<void> saveAndOpenPdf(Uint8List bytes, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }
}
