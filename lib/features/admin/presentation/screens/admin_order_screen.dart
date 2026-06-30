import 'package:flutter/material.dart';
import 'package:rc_mobile_v2/core/database/hive_db.dart';
import 'package:rc_mobile_v2/core/theme/app_colors.dart';
import 'package:rc_mobile_v2/core/widgets/product_image.dart';
import 'package:rc_mobile_v2/features/home/domain/models/order_model.dart';
import 'package:rc_mobile_v2/features/home/data/repositories/order_repository.dart';

class AdminOrderScreen extends StatefulWidget {
  final HiveDb db;
  const AdminOrderScreen({super.key, required this.db});

  @override
  State<AdminOrderScreen> createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen> {
  late HiveDb _db;
  String _statusFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _db = widget.db;
  }

  List<OrderModel> get _orders {
    var list = _db.getOrders()..sort((a, b) => b.orderDate.compareTo(a.orderDate));
    if (_statusFilter == 'Semua') return list;
    final status = _parseStatus(_statusFilter);
    return list.where((o) => o.status == status).toList();
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

  void _showDetail(OrderModel order) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => _OrderDetailSheet(order: order, onChanged: () => setState(() {})),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          Container(
            color: AppColors.pureWhite,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(gradient: AppColors.softBlackGradient, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.receipt_long_rounded, color: AppColors.pureWhite, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Manajemen Transaksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.pitchBlack)),
                    const Spacer(),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.lightGrey, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.download_rounded, size: 18, color: AppColors.pitchBlack),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['Semua', 'Pending', 'Dibayar', 'Diproses', 'Dikirim', 'Selesai', 'Dibatalkan'].map((s) {
                      final sel = s == _statusFilter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _statusFilter = s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              gradient: sel ? AppColors.blackGradient : null,
                              color: sel ? null : AppColors.lightGrey,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(child: Text(s, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: sel ? AppColors.pureWhite : AppColors.softGrey))),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.softGrey),
                        const SizedBox(height: 12),
                        const Text('Belum ada transaksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.pitchBlack)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.pitchBlack,
                    onRefresh: () async => setState(() {}),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) => _buildCard(_orders[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(OrderModel order) {
    final statusColors = {
      OrderStatus.pending: AppColors.warning, OrderStatus.paid: AppColors.info,
      OrderStatus.processing: AppColors.pitchBlack, OrderStatus.shipped: AppColors.pitchBlack,
      OrderStatus.delivered: AppColors.success, OrderStatus.cancelled: AppColors.error,
    };
    return GestureDetector(
      onTap: () => _showDetail(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.5)),
          boxShadow: [BoxShadow(color: AppColors.pitchBlack.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(gradient: AppColors.softBlackGradient, borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text('#${order.id.substring(order.id.length - 4)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.pureWhite))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.userName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.pitchBlack)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('${order.items.length} item', style: const TextStyle(fontSize: 11, color: AppColors.softGrey)),
                        const SizedBox(width: 8),
                        Text(order.paymentMethod.displayName, style: const TextStyle(fontSize: 11, color: AppColors.softGrey)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Rp ${_f(order.totalPrice)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.pitchBlack)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (statusColors[order.status] ?? AppColors.softGrey).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(order.status.displayName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColors[order.status] ?? AppColors.softGrey)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _f(double n) => n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}

class _OrderDetailSheet extends StatefulWidget {
  final OrderModel order; final VoidCallback onChanged;
  const _OrderDetailSheet({required this.order, required this.onChanged});
  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  List<OrderStatus> get _transitions {
    switch (widget.order.status) {
      case OrderStatus.pending: return [OrderStatus.paid, OrderStatus.cancelled];
      case OrderStatus.paid: return [OrderStatus.processing, OrderStatus.cancelled];
      case OrderStatus.processing: return [OrderStatus.shipped, OrderStatus.cancelled];
      case OrderStatus.shipped: return [OrderStatus.delivered];
      default: return [];
    }
  }

  Future<void> _changeStatus(OrderStatus status) async {
    await OrderRepository.syncOrderStatus(widget.order.id, status);
    widget.onChanged();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final transitions = _transitions;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(color: AppColors.pureWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        children: [
          Center(child: Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.borderGrey, borderRadius: BorderRadius.circular(2)))),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Detail Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.pitchBlack, letterSpacing: -0.3)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.lightGrey, shape: BoxShape.circle), child: const Icon(Icons.close, size: 20, color: AppColors.pitchBlack)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(gradient: AppColors.blackGradient, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.pitchBlack.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.pureWhite.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.receipt_long, color: AppColors.pureWhite, size: 24)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pesanan #${order.id.substring(order.id.length - 6)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.pureWhite)),
                                  const SizedBox(height: 4),
                                  Text(order.statusDisplay, style: TextStyle(fontSize: 13, color: AppColors.pureWhite.withValues(alpha: 0.8))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(color: AppColors.pureWhite.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tanggal', style: TextStyle(fontSize: 12, color: AppColors.pureWhite)),
                              Text('${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.pureWhite)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _section('Pelanggan', [
                    _row('Nama', order.userName),
                    _row('No. HP', order.userPhone),
                    _row('Alamat', order.userAddress),
                    _row('Pembayaran', order.paymentMethod.displayName),
                  ]),
                  const SizedBox(height: 20),
                  _section('Item (${order.items.length})', [
                    ...order.items.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.lightGrey, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(color: AppColors.borderGrey, borderRadius: BorderRadius.circular(8)),
                            child: ProductImage(imageUrl: item.imageUrl, width: 48, height: 48),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.pitchBlack))),
                          Text('Rp ${_f(item.price)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.pitchBlack)),
                        ],
                      ),
                    )),
                  ]),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.lightGrey, borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      children: [
                        _summary('Subtotal', 'Rp ${_f(order.totalPrice - order.shippingCost)}'),
                        const SizedBox(height: 8),
                        _summary('Pengiriman', order.shippingCost == 0 ? 'GRATIS' : _f(order.shippingCost)),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: AppColors.borderGrey)),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.pitchBlack)),
                          Text('Rp ${_f(order.totalPrice)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.pitchBlack, letterSpacing: -0.3)),
                        ]),
                        if (order.paymentProof != null && order.paymentProof!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: AppColors.borderGrey),
                          const SizedBox(height: 12),
                          _summary('Bukti Bayar', 'Lampiran tersedia'),
                        ],
                      ],
                    ),
                  ),
                  if (transitions.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Ubah Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.pitchBlack)),
                    const SizedBox(height: 10),
                    ...transitions.map((s) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _changeStatus(s),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.pitchBlack, foregroundColor: AppColors.pureWhite,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2, shadowColor: AppColors.pitchBlack.withValues(alpha: 0.3),
                        ),
                        child: Text('Tandai ${s.displayName}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    )),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(gradient: AppColors.softBlackGradient, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.info_outline, size: 14, color: AppColors.pureWhite)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.pitchBlack)),
      ]),
      const SizedBox(height: 8),
      ...children,
    ]);
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.softGrey))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.pitchBlack))),
    ]),
  );

  Widget _summary(String l, String v) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(l, style: const TextStyle(fontSize: 13, color: AppColors.softGrey)),
    Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.pitchBlack)),
  ]);

  String _f(double n) => n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}
