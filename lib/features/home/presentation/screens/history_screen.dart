import 'package:flutter/material.dart';
import '../../../../core/database/hive_db.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/product_image.dart';
import '../../data/repositories/order_repository.dart';
import '../../domain/models/order_model.dart';
import 'chat_screen.dart';
import 'complaint_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  final OrderRepository _orderRepo = OrderRepository();
  final HiveDb _db = HiveDb.instance;
  late TabController _tabController;

  final List<_TabItem> _tabs = const [
    _TabItem(label: 'Semua', status: null),
    _TabItem(label: 'Pending', status: 'pending'),
    _TabItem(label: 'Diproses', status: 'processing'),
    _TabItem(label: 'Dikirim', status: 'shipped'),
    _TabItem(label: 'Selesai', status: 'delivered'),
  ];

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<OrderModel> _getFilteredOrders() {
    final session = _db.getUserSession();
    final userId = session?['id'] ?? '';
    final orders = _orderRepo.getUserOrders(userId);
    final status = _tabs[_selectedIndex].status;
    if (status == null) return orders.where((o) => o.items.isNotEmpty).toList();
    if (status == 'processing') {
      return orders.where((o) => (o.status == OrderStatus.paid || o.status == OrderStatus.processing) && o.items.isNotEmpty).toList();
    }
    final targetStatus = _statusFromString(status);
    return orders.where((o) => o.status == targetStatus && o.items.isNotEmpty).toList();
  }

  OrderStatus _statusFromString(String s) {
    switch (s) {
      case 'pending': return OrderStatus.pending;
      case 'paid': return OrderStatus.paid;
      case 'processing': return OrderStatus.processing;
      case 'shipped': return OrderStatus.shipped;
      case 'delivered': return OrderStatus.delivered;
      default: return OrderStatus.pending;
    }
  }

  void _confirmReceived(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Pesanan'),
        content: const Text('Apakah pesanan sudah diterima?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              _orderRepo.updateOrderStatus(order.id, OrderStatus.delivered);
              Navigator.pop(ctx);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.pitchBlack, foregroundColor: AppColors.pureWhite, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Sudah Diterima'),
          ),
        ],
      ),
    );
  }

  void _openComplaint(OrderModel order) {
    final user = _db.getUserSession();
    if (user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComplaintScreen(
          orderId: order.id,
          orderNumber: order.id.substring(order.id.length - 6),
          orderTotal: order.totalPrice,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final stats = _orderRepo.getOrderStats();
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(stats),
            _buildTabBar(),
            Expanded(child: _buildOrdersList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, int> stats) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pesanan Saya', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.pitchBlack, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text('${stats['total'] ?? 0} total pesanan', style: const TextStyle(fontSize: 14, color: AppColors.softGrey)),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.chat_outlined, color: AppColors.pitchBlack, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.blackGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: AppColors.pitchBlack.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.receipt_long, color: AppColors.pureWhite, size: 18),
                const SizedBox(width: 8),
                Text('${stats['total'] ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.pureWhite)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 42,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicator: BoxDecoration(
              gradient: AppColors.blackGradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: AppColors.pitchBlack.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.all(4),
            dividerColor: Colors.transparent,
            labelColor: AppColors.pureWhite,
            unselectedLabelColor: AppColors.softGrey,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            tabs: _tabs.map((tab) => Tab(text: tab.label)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    final orders = _getFilteredOrders();
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.softGrey),
              ),
              const SizedBox(height: 20),
              const Text('Belum ada pesanan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.pitchBlack)),
              const SizedBox(height: 8),
              const Text('Mulai belanja dan pesananmu\nakan muncul di sini', style: TextStyle(fontSize: 14, color: AppColors.softGrey, height: 1.5), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.pitchBlack,
      onRefresh: () async => setState(() {}),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        physics: const BouncingScrollPhysics(),
        itemCount: orders.length,
        itemBuilder: (context, index) => _buildOrderCard(orders[index]),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(color: AppColors.pitchBlack.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _showOrderDetails(order),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(gradient: AppColors.softBlackGradient, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.receipt_outlined, color: AppColors.pureWhite, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pesanan #${order.id.substring(order.id.length - 6)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.pitchBlack, letterSpacing: 0.3)),
                          const SizedBox(height: 4),
                          Text(_formatDate(order.orderDate), style: const TextStyle(fontSize: 12, color: AppColors.softGrey)),
                        ],
                      ),
                    ],
                  ),
                  _buildStatusBadge(order.status),
                ],
              ),
            ),
          ),
          _buildProductsPreview(order),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.borderGrey.withValues(alpha: 0), AppColors.borderGrey, AppColors.borderGrey.withValues(alpha: 0)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 12, color: AppColors.softGrey)),
                    const SizedBox(height: 2),
                    Text(_formatPrice(order.totalPrice), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.pitchBlack, letterSpacing: -0.3)),
                  ],
                ),
                Row(
                  children: [
                    if (order.status == OrderStatus.shipped)
                      GestureDetector(
                        onTap: () => _confirmReceived(order),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: AppColors.blackGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: AppColors.pitchBlack.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_outline, color: AppColors.pureWhite, size: 16),
                              const SizedBox(width: 6),
                              const Text('Pesanan Diterima', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.pureWhite)),
                            ],
                          ),
                        ),
                      )
                    else if (order.status == OrderStatus.delivered &&
                        _db.getComplaints().where((c) => c['orderId'] == order.id).isEmpty)
                      GestureDetector(
                        onTap: () => _openComplaint(order),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.feedback_outlined, size: 16, color: AppColors.error),
                              const SizedBox(width: 6),
                              const Text('Ajukan Komplain', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.error)),
                            ],
                          ),
                        ),
                      )
                    else if (order.status == OrderStatus.delivered)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderGrey),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, size: 16, color: AppColors.softGrey),
                            const SizedBox(width: 6),
                            const Text('Sudah Dikomplain', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.softGrey)),
                          ],
                        ),
                      ),
                    if (order.status != OrderStatus.shipped) ...[
                      if (order.status == OrderStatus.delivered &&
                          _db.getComplaints().where((c) => c['orderId'] == order.id).isEmpty)
                        const SizedBox(width: AppConstants.spacingS),
                      GestureDetector(
                        onTap: () => _showOrderDetails(order),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderGrey),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Detail', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.pitchBlack)),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.pitchBlack),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    final text = status.displayName;
    final isActive = status != OrderStatus.delivered && status != OrderStatus.cancelled;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: isActive ? AppColors.blackGradient : null,
        color: isActive ? null : AppColors.lightGrey,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isActive ? [BoxShadow(color: AppColors.pitchBlack.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2))] : null,
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isActive ? AppColors.pureWhite : AppColors.softGrey, letterSpacing: 0.5)),
    );
  }

  Widget _buildProductsPreview(OrderModel order) {
    if (order.items.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        children: [
          SizedBox(
            width: 90, height: 60,
            child: Stack(
              children: [
                for (int i = 0; i < order.items.take(3).length; i++)
                  Positioned(
                    left: i * 18.0,
                    child: Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.pureWhite, width: 2.5),
                        boxShadow: [BoxShadow(color: AppColors.pitchBlack.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: ProductImage(
                        imageUrl: order.items[i].imageUrl,
                        width: 52,
                        height: 52,
                        borderRadius: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.items.isNotEmpty ? order.items.first.name : '',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.pitchBlack),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(order.items.length > 1 ? '+${order.items.length - 1} item lainnya' : '1 item', style: const TextStyle(fontSize: 12, color: AppColors.softGrey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.lightGrey.withValues(alpha: 0.5), shape: BoxShape.circle),
            child: const Icon(Icons.chevron_right, color: AppColors.softGrey, size: 20),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OrderDetailsSheet(
        order: order,
        onConfirmReceived: order.status == OrderStatus.shipped
            ? () { Navigator.pop(context); _confirmReceived(order); }
            : null,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatPrice(double price) {
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }
}

class _TabItem {
  final String label;
  final String? status;
  const _TabItem({required this.label, this.status});
}

class _DashLinePainter extends CustomPainter {
  final Color color;
  _DashLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const dashWidth = 4.0;
    const dashGap = 3.0;
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, (startY + dashWidth).clamp(0, size.height)), paint);
      startY += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashLinePainter oldDelegate) => oldDelegate.color != color;
}

class _OrderDetailsSheet extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onConfirmReceived;
  const _OrderDetailsSheet({required this.order, this.onConfirmReceived});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.borderGrey, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Detail Pesanan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.pitchBlack, letterSpacing: -0.3)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.lightGrey.withValues(alpha: 0.5), shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 20, color: AppColors.pitchBlack),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderGrey),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.blackGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: AppColors.pitchBlack.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppColors.pureWhite.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.receipt_long, color: AppColors.pureWhite, size: 24),
                            ),
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
                              const Text('Tanggal Pesanan', style: TextStyle(fontSize: 12, color: AppColors.pureWhite)),
                              Text(_formatDate(order.orderDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.pureWhite)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSection('Alamat Pengiriman', Icons.location_on_outlined, [
                    const SizedBox(height: 8),
                    Text(order.userName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.pitchBlack)),
                    const SizedBox(height: 4),
                    Text(order.userPhone, style: const TextStyle(fontSize: 13, color: AppColors.softGrey)),
                    const SizedBox(height: 4),
                    Text(order.userAddress, style: const TextStyle(fontSize: 13, color: AppColors.softGrey, height: 1.4)),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Produk (${order.items.length})', Icons.shopping_bag_outlined, [
                    const SizedBox(height: 12),
                    ...order.items.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.pureWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(color: AppColors.lightGrey, borderRadius: BorderRadius.circular(10)),
                          child: ProductImage(
                            imageUrl: item.imageUrl,
                            width: 60,
                            height: 60,
                            borderRadius: 10,
                          ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.pitchBlack), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text('Rp ${item.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.pitchBlack)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                  ]),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow('Subtotal', _formatPrice(order.totalPrice - order.shippingCost)),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Pengiriman', order.shippingCost == 0 ? 'GRATIS' : _formatPrice(order.shippingCost)),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: AppColors.borderGrey)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.pitchBlack)),
                            Text(_formatPrice(order.totalPrice), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.pitchBlack, letterSpacing: -0.3)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildShippingTimeline(),
                  const SizedBox(height: 16),
                  _buildSection('Informasi Pembayaran', Icons.payment_outlined, [
                    const SizedBox(height: 8),
                    _buildInfoRow('Metode', order.paymentMethod.displayName),
                  ]),
                  if (onConfirmReceived != null) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onConfirmReceived,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.pitchBlack,
                          foregroundColor: AppColors.pureWhite,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                          shadowColor: AppColors.pitchBlack.withValues(alpha: 0.3),
                        ),
                        child: const Text('Pesanan Sudah Diterima', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
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

  Widget _buildShippingTimeline() {
    final isPast = <bool>[
      order.status == OrderStatus.processing ||
          order.status == OrderStatus.shipped ||
          order.status == OrderStatus.delivered,
      order.status == OrderStatus.shipped ||
          order.status == OrderStatus.delivered,
      order.status == OrderStatus.delivered,
    ];
    final isCurrent = <bool>[
      order.status == OrderStatus.paid,
      order.status == OrderStatus.processing,
      order.status == OrderStatus.shipped,
    ];
    final dates = <String?>[
      order.status == OrderStatus.processing || order.status == OrderStatus.shipped || order.status == OrderStatus.delivered
          ? _formatDate(order.paymentDate ?? order.orderDate)
          : null,
      order.shippedDate != null ? _formatDate(order.shippedDate!) : null,
      order.deliveredDate != null ? _formatDate(order.deliveredDate!) : null,
    ];

    final steps = [
      ('Barang Dikemas', Icons.inventory_2_rounded),
      ('Barang Dikirim', Icons.local_shipping_rounded),
      ('Barang Diterima', Icons.check_circle_rounded),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(gradient: AppColors.softBlackGradient, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.local_shipping_rounded, size: 16, color: AppColors.pureWhite),
              ),
              const SizedBox(width: 8),
              const Text('Status Pengiriman', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.pitchBlack)),
            ],
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: SizedBox(
                  height: 28,
                  child: CustomPaint(
                    size: const Size(2, 28),
                    painter: _DashLinePainter(
                      color: isPast[i] ? AppColors.pitchBlack : AppColors.borderGrey,
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    gradient: isPast[i] || isCurrent[i]
                        ? AppColors.blackGradient
                        : null,
                    color: isPast[i] || isCurrent[i] ? null : AppColors.borderGrey.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                    boxShadow: isCurrent[i]
                        ? [BoxShadow(color: AppColors.pitchBlack.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Icon(
                    steps[i].$2,
                    size: 20,
                    color: isPast[i] || isCurrent[i] ? AppColors.pureWhite : AppColors.softGrey,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        steps[i].$1,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isPast[i] || isCurrent[i] ? FontWeight.w700 : FontWeight.w500,
                          color: isPast[i] || isCurrent[i] ? AppColors.pitchBlack : AppColors.softGrey,
                        ),
                      ),
                      if (dates[i] != null)
                        Text(
                          dates[i]!,
                          style: TextStyle(
                            fontSize: 11,
                            color: isPast[i] || isCurrent[i] ? AppColors.softGrey : AppColors.borderGrey,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isPast[i])
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.pitchBlack.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 14, color: AppColors.pitchBlack),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(gradient: AppColors.softBlackGradient, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: AppColors.pureWhite),
            ),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.pitchBlack)),
          ],
        ),
        ...children,
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.softGrey)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.pitchBlack)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.softGrey)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.pitchBlack)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatPrice(double price) {
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }
}
