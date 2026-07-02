import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rc_mobile_v2/core/database/hive_db.dart';
import 'package:rc_mobile_v2/core/theme/app_colors.dart';
import 'package:rc_mobile_v2/core/widgets/product_image.dart';
import 'package:rc_mobile_v2/features/home/domain/models/order_model.dart';
import 'package:rc_mobile_v2/features/home/domain/models/chat_message_model.dart';
import 'package:rc_mobile_v2/features/home/data/repositories/order_repository.dart';
import 'dart:io';

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
      builder: (ctx) => _OrderDetailSheet(order: order, db: _db, onChanged: () => setState(() {})),
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
                child: Center(child: Text(order.orderNumber, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.pureWhite))),
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
  final OrderModel order;
  final VoidCallback onChanged;
  final HiveDb db;
  const _OrderDetailSheet({required this.order, required this.onChanged, required this.db});
  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  final _trackingController = TextEditingController();
  late HiveDb _db;

  @override
  void initState() {
    super.initState();
    _db = widget.db;
  }

  void _openChatWithUser(OrderModel order) {
    final userEmail = _db.getUserEmailById(order.userId);
    if (userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email user tidak ditemukan')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ChatWithOrderScreen(
          email: userEmail,
          order: order,
          db: _db,
        ),
      ),
    );
  }

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
    if (status == OrderStatus.shipped) {
      // Show dialog to input tracking number
      final result = await showDialog<Map<String, String>>(
        context: context,
        builder: (ctx) => _TrackingInputDialog(
          courier: widget.order.courier ?? '',
          courierService: widget.order.courierService ?? '',
        ),
      );
      if (result == null) return;

      await OrderRepository.syncOrderStatusWithTracking(
        widget.order.id,
        status,
        trackingNumber: result['trackingNumber'] ?? '',
      );
    } else {
      await OrderRepository.syncOrderStatus(widget.order.id, status);
    }
    widget.onChanged();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
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
                                  Text('Pesanan ${order.orderNumber}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.pureWhite)),
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
                    const Text('Aksi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.pitchBlack)),
                    const SizedBox(height: 10),
                    // Chat Button
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Navigate to chat with this user
                          _openChatWithUser(order);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: AppColors.pureWhite,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.chat_rounded, size: 18),
                        label: const Text('Chat tentang Pesanan Ini', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ),
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

class _TrackingInputDialog extends StatefulWidget {
  final String courier;
  final String courierService;

  const _TrackingInputDialog({
    required this.courier,
    required this.courierService,
  });

  @override
  State<_TrackingInputDialog> createState() => _TrackingInputDialogState();
}

class _TrackingInputDialogState extends State<_TrackingInputDialog> {
  final _trackingController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.softBlackGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_shipping, size: 18, color: AppColors.pureWhite),
          ),
          const SizedBox(width: 10),
          const Text(
            'Input Nomor Resi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Courier info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightGrey.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.business, size: 18, color: AppColors.softGrey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.courier} ${widget.courierService}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nomor Resi',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.pitchBlack),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _trackingController,
              decoration: InputDecoration(
                hintText: 'Masukkan nomor resi pengiriman',
                hintStyle: const TextStyle(color: AppColors.softGrey, fontSize: 13),
                filled: true,
                fillColor: AppColors.lightGrey.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.pitchBlack, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nomor resi harus diisi';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: AppColors.softGrey)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'trackingNumber': _trackingController.text.trim(),
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.pitchBlack,
            foregroundColor: AppColors.pureWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: const Text('Simpan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ===================== CHAT WITH ORDER SCREEN =====================

class _ChatWithOrderScreen extends StatefulWidget {
  final String email;
  final OrderModel order;
  final HiveDb db;

  const _ChatWithOrderScreen({
    required this.email,
    required this.order,
    required this.db,
  });

  @override
  State<_ChatWithOrderScreen> createState() => _ChatWithOrderScreenState();
}

class _ChatWithOrderScreenState extends State<_ChatWithOrderScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _imagePicker = ImagePicker();
  bool _initialMessageSent = false;

  @override
  void initState() {
    super.initState();
    widget.db.markMessagesRead(widget.email);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialMessageSent) {
      _initialMessageSent = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendOrderDetailAutoMessage();
      });
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.pitchBlack),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.pitchBlack),
              title: const Text('Galeri Foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        _sendImage(pickedFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memilih foto')),
        );
      }
    }
  }

  void _sendImage(String imagePath) {
    widget.db.sendMessage(ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderEmail: 'admin@admin.com',
      senderName: 'Admin',
      senderRole: 'admin',
      message: 'Mengirim foto',
      timestamp: DateTime.now(),
      receiverEmail: widget.email,
      imageUrl: imagePath,
    ));
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _sendOrderDetailAutoMessage() {
    final order = widget.order;
    final itemsList = order.items.map((item) => '• ${item.name} (Rp ${_formatPrice(item.price)})').join('\n');

    final autoMessage = '''📦 DETAIL PESANAN ${order.orderNumber}

🛒 Produk yang dipesan:
$itemsList

💰 Total: ${_formatPrice(order.totalPrice)}
🚚 Pengiriman: ${order.shippingCost == 0 ? 'GRATIS' : _formatPrice(order.shippingCost)}

📍 Alamat Pengiriman:
${order.userAddress}

Jika ada pertanyaan tentang pesanan ini, silakan balas pesan ini. Terima kasih!''';

    widget.db.sendMessage(ChatMessageModel(
      id: 'auto_${DateTime.now().millisecondsSinceEpoch}',
      senderEmail: 'admin@admin.com',
      senderName: 'Admin',
      senderRole: 'admin',
      message: autoMessage,
      timestamp: DateTime.now(),
      receiverEmail: widget.email, // User's email
    ));
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  List<ChatMessageModel> get _messages => widget.db.getMessages(widget.email);

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    widget.db.sendMessage(ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderEmail: 'admin@admin.com',
      senderName: 'Admin',
      senderRole: 'admin',
      message: text,
      timestamp: DateTime.now(),
      receiverEmail: widget.email, // User's email
    ));
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _sendQuickMessage(String message) {
    widget.db.sendMessage(ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderEmail: 'admin@admin.com',
      senderName: 'Admin',
      senderRole: 'admin',
      message: message,
      timestamp: DateTime.now(),
      receiverEmail: widget.email, // User's email
    ));
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.pitchBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.order.userName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.pitchBlack),
            ),
            Text(
              'Pesanan ${widget.order.orderNumber}',
              style: const TextStyle(fontSize: 12, color: AppColors.softGrey, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Order Info Card
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.softBlackGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt_long, color: AppColors.pureWhite, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pesanan ${widget.order.orderNumber}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.pitchBlack),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.order.items.length} item • ${_formatPrice(widget.order.totalPrice)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.softGrey),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.pitchBlack,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.order.statusDisplay,
                          style: const TextStyle(fontSize: 9, color: AppColors.pureWhite, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Quick Actions
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _QuickActionChip(
                  icon: Icons.refresh,
                  label: 'Kirim Ulang Detail',
                  onTap: () => _sendQuickMessage('Berikut kami kirim ulang detail pesanan Anda:\n\nSilakan tanyakan jika ada yang kurang jelas.'),
                ),
                const SizedBox(width: 8),
                _QuickActionChip(
                  icon: Icons.help_outline,
                  label: 'Butuh Bantuan?',
                  onTap: () => _sendQuickMessage('Halo! Apakah ada yang bisa kami bantu mengenai pesanan ${widget.order.orderNumber}?'),
                ),
                const SizedBox(width: 8),
                _QuickActionChip(
                  icon: Icons.check_circle_outline,
                  label: 'Pesanan Ready',
                  onTap: () => _sendQuickMessage('Hai! Pesanan ${widget.order.orderNumber} sudah ready dan akan segera kami proses. Terima kasih! 😊'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.softGrey),
                        const SizedBox(height: 12),
                        const Text('Belum ada pesan', style: TextStyle(color: AppColors.softGrey)),
                        const SizedBox(height: 4),
                        const Text('Gunakan tombol quick action di atas', style: TextStyle(fontSize: 12, color: AppColors.softGrey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isAdmin = msg.senderRole == 'admin';

                      // Image message
                      if (msg.isImageMessage) {
                        return Align(
                          alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.65,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.pitchBlack.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.file(
                                    File(msg.imageUrl!),
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      height: 150,
                                      color: AppColors.lightGrey,
                                      child: const Center(
                                        child: Icon(Icons.broken_image, color: AppColors.softGrey),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    color: isAdmin ? AppColors.pitchBlack : AppColors.pureWhite,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (!isAdmin) ...[
                                          Text(msg.senderName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.softGrey)),
                                          const SizedBox(width: 8),
                                        ],
                                        Text(
                                          '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(fontSize: 10, color: isAdmin ? AppColors.pureWhite.withValues(alpha: 0.6) : AppColors.softGrey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      // Text message
                      return Align(
                        alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isAdmin ? AppColors.pitchBlack : AppColors.pureWhite,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isAdmin ? const Radius.circular(16) : Radius.zero,
                              bottomRight: isAdmin ? Radius.zero : const Radius.circular(16),
                            ),
                            border: isAdmin ? null : Border.all(color: AppColors.borderGrey),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isAdmin)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(msg.senderName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.softGrey)),
                                ),
                              Text(msg.message, style: TextStyle(fontSize: 14, color: isAdmin ? AppColors.pureWhite : AppColors.pitchBlack)),
                              const SizedBox(height: 4),
                              Text(
                                '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(fontSize: 10, color: isAdmin ? AppColors.pureWhite.withValues(alpha: 0.6) : AppColors.softGrey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              boxShadow: [BoxShadow(color: AppColors.shadowColor, blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                // Camera Button
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.softBlackGradient,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.camera_alt, color: AppColors.pureWhite, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Ketik pesan...',
                      hintStyle: const TextStyle(fontSize: 14, color: AppColors.softGrey),
                      filled: true,
                      fillColor: AppColors.lightGrey,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(gradient: AppColors.blackGradient, borderRadius: BorderRadius.circular(22)),
                    child: const Icon(Icons.send_rounded, color: AppColors.pureWhite, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderGrey),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.pitchBlack),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.pitchBlack, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
