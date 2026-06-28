import 'package:hive_flutter/hive_flutter.dart';
import '../../features/home/domain/models/cart_model.dart';
import '../../features/home/domain/models/order_model.dart';
import '../../features/home/domain/models/product_model.dart';
import '../../features/home/domain/models/category_model.dart';
import '../../features/home/domain/models/chat_message_model.dart';
import 'adapters/product_model_adapter.dart';
import 'adapters/cart_item_model_adapter.dart';
import 'adapters/order_model_adapter.dart';
import 'adapters/category_model_adapter.dart';
import 'adapters/chat_message_model_adapter.dart';

class HiveDb {
  HiveDb._();

  static final HiveDb instance = HiveDb._();

  static const String _cartBoxName = 'cart_box';
  static const String _ordersBoxName = 'orders_box';
  static const String _authBoxName = 'auth_box';
  static const String _usersBoxName = 'users_box';
  static const String _productsBoxName = 'products_box';
  static const String _categoriesBoxName = 'categories_box';
  static const String _messagesBoxName = 'messages_box';
  static const String _walletBoxName = 'wallet_box';
  static const String _complaintsBoxName = 'complaints_box';
  static const String _vouchersBoxName = 'vouchers_box';

  static const int _dbVersion = 7;
  static const String _versionKey = 'db_version';

  Box<CartItemModel>? _cartBox;
  Box<OrderModel>? _ordersBox;
  Box? _authBox;
  Box? _usersBox;
  Box? _productsBox;
  Box? _categoriesBox;
  Box? _messagesBox;
  Box? _walletBox;
  Box? _complaintsBox;
  Box? _vouchersBox;

  Box<CartItemModel> get cartBox {
    if (_cartBox == null || !_cartBox!.isOpen) {
      throw Exception('Cart box not initialized');
    }
    return _cartBox!;
  }

  Box<OrderModel> get ordersBox {
    if (_ordersBox == null || !_ordersBox!.isOpen) {
      throw Exception('Orders box not initialized');
    }
    return _ordersBox!;
  }

  Box get authBox {
    if (_authBox == null || !_authBox!.isOpen) {
      throw Exception('Auth box not initialized');
    }
    return _authBox!;
  }

  Box get usersBox {
    if (_usersBox == null || !_usersBox!.isOpen) {
      throw Exception('Users box not initialized');
    }
    return _usersBox!;
  }

  Box get productsBox {
    if (_productsBox == null || !_productsBox!.isOpen) {
      throw Exception('Products box not initialized');
    }
    return _productsBox!;
  }

  Box get categoriesBox {
    if (_categoriesBox == null || !_categoriesBox!.isOpen) {
      throw Exception('Categories box not initialized');
    }
    return _categoriesBox!;
  }

  Box get messagesBox {
    if (_messagesBox == null || !_messagesBox!.isOpen) {
      throw Exception('Messages box not initialized');
    }
    return _messagesBox!;
  }

  Box get walletBox {
    if (_walletBox == null || !_walletBox!.isOpen) {
      throw Exception('Wallet box not initialized');
    }
    return _walletBox!;
  }

  Box get complaintsBox {
    if (_complaintsBox == null || !_complaintsBox!.isOpen) {
      throw Exception('Complaints box not initialized');
    }
    return _complaintsBox!;
  }

  Box get vouchersBox {
    if (_vouchersBox == null || !_vouchersBox!.isOpen) {
      throw Exception('Vouchers box not initialized');
    }
    return _vouchersBox!;
  }

  Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(ProductModelAdapter());
    Hive.registerAdapter(BannerModelAdapter());
    Hive.registerAdapter(CartItemModelAdapter());
    Hive.registerAdapter(OrderModelAdapter());
    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(ChatMessageModelAdapter());

    await _checkAndMigrate();

    _cartBox = await Hive.openBox<CartItemModel>(_cartBoxName);
    _ordersBox = await Hive.openBox<OrderModel>(_ordersBoxName);
    _authBox = await Hive.openBox(_authBoxName);
    _usersBox = await Hive.openBox(_usersBoxName);
    _productsBox = await Hive.openBox(_productsBoxName);
    _categoriesBox = await Hive.openBox(_categoriesBoxName);
    _messagesBox = await Hive.openBox(_messagesBoxName);
    _walletBox = await Hive.openBox(_walletBoxName);
    _complaintsBox = await Hive.openBox(_complaintsBoxName);
    _vouchersBox = await Hive.openBox(_vouchersBoxName);

    await _seedAdminUser();
    await _seedCategories();
    await _seedProducts();
  }

  Future<void> _checkAndMigrate() async {
    final versionBox = await Hive.openBox('_version_box');
    final storedVersion = versionBox.get(_versionKey) as int? ?? 0;

    if (storedVersion < _dbVersion) {
      for (final name in [
        _cartBoxName,
        _ordersBoxName,
        _authBoxName,
        _usersBoxName,
        _productsBoxName,
        _categoriesBoxName,
        _messagesBoxName,
        _walletBoxName,
        _complaintsBoxName,
        _vouchersBoxName,
      ]) {
        if (Hive.isBoxOpen(name)) {
          await Hive.box(name).close();
        }
        await Hive.deleteBoxFromDisk(name);
      }
      await versionBox.put(_versionKey, _dbVersion);
    }
    await versionBox.close();
  }

  Future<void> _seedAdminUser() async {
    if (!usersBox.containsKey('admin@admin.com')) {
      await usersBox.put('admin@admin.com', {
        'id': 'admin_001',
        'name': 'Admin',
        'email': 'admin@admin.com',
        'password': 'admin123',
        'role': 'admin',
        'isActive': true,
        'walletBalance': 0.0,
      });
    }
  }

  Future<void> _seedCategories() async {
    if (categoriesBox.length > 0) return;

    final categories = [
      {'id': 'cat_1', 'name': 'T-Shirt', 'iconPath': 'tshirt'},
      {'id': 'cat_2', 'name': 'Celana', 'iconPath': 'pants'},
      {'id': 'cat_3', 'name': 'Kemeja', 'iconPath': 'shirt'},
      {'id': 'cat_4', 'name': 'Hoodie', 'iconPath': 'hoodie'},
      {'id': 'cat_5', 'name': 'Topi', 'iconPath': 'accessories'},
    ];

    for (final cat in categories) {
      await categoriesBox.put(
        cat['id'],
        CategoryModel.fromMap(cat),
      );
    }
  }

  Future<void> _seedProducts() async {
    if (productsBox.length > 0) return;

    final products = [
      {
        'id': 'prod_1',
        'name': 'Republik Casual T Shirt',
        'price': 149000,
        'rating': 4.8,
        'reviewCount': 245,
        'imageUrl': 'assets/images/products/T Shirt.png',
        'category': 'T-Shirt',
        'isFavorite': false,
        'isActive': true,
        'description': 'T-shirt katun premium dengan bahan lembut dan nyaman dipakai sehari-hari.',
        'availableSizes': ['S', 'M', 'L', 'XL'],
        'stock': 50,
        'weight': 200,
      },
      {
        'id': 'prod_2',
        'name': 'Republik Casual Celana',
        'price': 279000,
        'rating': 4.4,
        'reviewCount': 134,
        'imageUrl': 'assets/images/products/Celana.png',
        'category': 'Celana',
        'isFavorite': false,
        'isActive': true,
        'description': 'Celana chino slim fit yang nyaman dan cocok untuk berbagai acara.',
        'availableSizes': ['M', 'L', 'XL'],
        'stock': 25,
        'weight': 400,
      },
      {
        'id': 'prod_3',
        'name': 'Republik Casual Kemeja',
        'price': 249000,
        'rating': 4.6,
        'reviewCount': 189,
        'imageUrl': 'assets/images/products/Kemeja.png',
        'category': 'Kemeja',
        'isFavorite': false,
        'isActive': true,
        'description': 'Kemeja Oxford slim fit dengan potongan modern dan rapi.',
        'availableSizes': ['M', 'L', 'XL'],
        'stock': 35,
        'weight': 250,
      },
      {
        'id': 'prod_4',
        'name': 'Republik Casual Hoodie',
        'price': 329000,
        'rating': 4.9,
        'reviewCount': 312,
        'imageUrl': 'assets/images/products/Hoodie.png',
        'category': 'Hoodie',
        'isFavorite': false,
        'isActive': true,
        'description': 'Hoodie premium dengan bahan cotton fleece yang hangat dan nyaman.',
        'availableSizes': ['S', 'M', 'L', 'XL'],
        'stock': 30,
        'weight': 500,
      },
      {
        'id': 'prod_5',
        'name': 'Republik Casual Topi',
        'price': 99000,
        'rating': 4.5,
        'reviewCount': 98,
        'imageUrl': 'assets/images/products/Topi.png',
        'category': 'Topi',
        'isFavorite': false,
        'isActive': true,
        'description': 'Topi casual stylish untuk melengkapi gaya sehari-hari.',
        'availableSizes': ['One Size'],
        'stock': 50,
        'weight': 100,
      },
    ];

    for (final product in products) {
      await productsBox.put(
        product['id'],
        ProductModel.fromMap(product),
      );
    }
  }

  Future<void> close() async {
    await _cartBox?.close();
    await _ordersBox?.close();
    await _authBox?.close();
    await _usersBox?.close();
    await _productsBox?.close();
    await _categoriesBox?.close();
    await _messagesBox?.close();
    await _walletBox?.close();
    await _complaintsBox?.close();
    await _vouchersBox?.close();
  }

  // ===== AUTH =====

  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    String address = '',
    String phone = '',
  }) async {
    if (usersBox.containsKey(email)) {
      return {'success': false, 'message': 'Email sudah terdaftar'};
    }

    final user = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'email': email,
      'password': password,
      'role': 'user',
      'isActive': true,
      'address': address,
      'phone': phone,
      'voucher': 20000,
      'walletBalance': 0.0,
    };

    await usersBox.put(email, user);
    return {'success': true, 'message': 'Registrasi berhasil', 'user': user};
  }

  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final stored = usersBox.get(email);
    if (stored == null) {
      return {'success': false, 'message': 'Email tidak terdaftar'};
    }
    if (stored is! Map) {
      return {'success': false, 'message': 'Data pengguna tidak valid'};
    }

    final user = Map<String, dynamic>.from(stored);
    if (user['isActive'] == false) {
      return {'success': false, 'message': 'Akun telah dinonaktifkan'};
    }
    if (user['password'] != password) {
      return {'success': false, 'message': 'Password salah'};
    }

    return {
      'success': true,
      'message': 'Login berhasil',
      'user': {
        'id': user['id'],
        'name': user['name'],
        'email': user['email'],
        'role': user['role'],
        'isLoggedIn': true,
      },
    };
  }

  Future<Map<String, dynamic>> loginAdmin({
    required String email,
    required String password,
  }) async {
    final result = await loginUser(email: email, password: password);
    if (result['success'] != true) return result;

    final user = result['user'] as Map<String, dynamic>;
    if (user['role'] != 'admin') {
      return {'success': false, 'message': 'Akun ini bukan admin'};
    }

    return result;
  }

  Map<String, dynamic>? getUserSession() {
    final id = _authBox?.get('user_id');
    final name = _authBox?.get('user_name');
    final email = _authBox?.get('user_email');
    final role = _authBox?.get('user_role');
    final isLoggedIn = _authBox?.get('is_logged_in') ?? false;

    if (isLoggedIn == true && id != null && email != null) {
      return {
        'id': id,
        'name': name ?? (email as String).split('@').first,
        'email': email,
        'role': role ?? 'user',
        'isLoggedIn': true,
      };
    }
    return null;
  }

  Future<void> saveUserSession(Map<String, dynamic> user) async {
    await _authBox!.put('user_id', user['id']);
    await _authBox!.put('user_name', user['name']);
    await _authBox!.put('user_email', user['email']);
    await _authBox!.put('user_role', user['role'] ?? 'user');
    await _authBox!.put('is_logged_in', true);
  }

  Future<void> clearUserSession() async {
    await _authBox!.clear();
  }

  Map<String, String?> getUserContact() {
    final session = getUserSession();
    if (session == null) return {'address': null, 'phone': null};
    final email = session['email'] as String?;
    if (email == null) return {'address': null, 'phone': null};
    final raw = usersBox.get(email);
    if (raw == null) return {'address': null, 'phone': null};
    final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    return {
      'address': data['address'] as String?,
      'phone': data['phone'] as String?,
    };
  }

  bool hasUserAddress() {
    final contact = getUserContact();
    final address = contact['address'];
    return address != null && address.isNotEmpty;
  }

  String getUserAddress() {
    final contact = getUserContact();
    return contact['address'] ?? '';
  }

  String getUserPhone() {
    final contact = getUserContact();
    return contact['phone'] ?? '';
  }

  String getUserPhoto() {
    final session = getUserSession();
    if (session == null) return '';
    final email = session['email'] as String?;
    if (email == null) return '';
    final raw = usersBox.get(email);
    if (raw == null) return '';
    final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    return data['photo'] as String? ?? '';
  }

  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    final session = getUserSession();
    if (session == null) return;
    final email = session['email'] as String?;
    if (email == null) return;
    final raw = usersBox.get(email);
    if (raw == null) return;
    final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    data.addAll(updates);
    await usersBox.put(email, data);
    if (updates.containsKey('name')) {
      await _authBox!.put('user_name', updates['name']);
    }
  }

  double? getVoucher() {
    final session = getUserSession();
    if (session == null) return null;
    final email = session['email'] as String?;
    if (email == null) return null;
    final raw = usersBox.get(email);
    if (raw == null) return null;
    final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    return (data['voucher'] as num?)?.toDouble();
  }

  Future<void> setVoucher(double? discount) async {
    await updateUserProfile({'voucher': discount});
  }

  // ===== USERS =====

  List<Map<String, dynamic>> getAllUsers() {
    final users = <Map<String, dynamic>>[];
    for (final key in usersBox.keys) {
      final user = usersBox.get(key);
      if (user != null && user is Map) {
        users.add(Map<String, dynamic>.from(user));
      }
    }
    return users;
  }

  Future<void> toggleUserActive(String email) async {
    final user = usersBox.get(email);
    if (user != null && user is Map) {
      final data = Map<String, dynamic>.from(user);
      data['isActive'] = data['isActive'] == false ? true : false;
      await usersBox.put(email, data);
    }
  }

  // ===== CART =====

  List<CartItemModel> getCartItems() {
    return cartBox.values.toList();
  }

  Future<void> saveCartItem(CartItemModel item) async {
    await cartBox.put(item.id, item);
  }

  Future<void> deleteCartItem(String id) async {
    await cartBox.delete(id);
  }

  Future<void> clearCart() async {
    await cartBox.clear();
  }

  // ===== PRODUCTS =====

  List<ProductModel> getProducts() {
    return productsBox.values.cast<ProductModel>().toList();
  }

  List<ProductModel> getActiveProducts() {
    return productsBox.values
        .cast<ProductModel>()
        .where((p) => p.isActive)
        .toList();
  }

  ProductModel? getProductById(String id) {
    return productsBox.get(id);
  }

  Future<void> saveProduct(ProductModel product) async {
    await productsBox.put(product.id, product);
  }

  Future<void> deleteProduct(String id) async {
    await productsBox.delete(id);
  }

  Future<void> toggleProductActive(String id) async {
    final product = productsBox.get(id);
    if (product != null) {
      await productsBox.put(id, product.copyWith(isActive: !product.isActive));
    }
  }

  // ===== CATEGORIES =====

  List<CategoryModel> getCategories() {
    return categoriesBox.values.cast<CategoryModel>().toList();
  }

  CategoryModel? getCategoryById(String id) {
    return categoriesBox.get(id);
  }

  Future<void> saveCategory(CategoryModel category) async {
    await categoriesBox.put(category.id, category);
  }

  Future<void> deleteCategory(String id) async {
    await categoriesBox.delete(id);
  }

  // ===== ORDERS =====

  List<OrderModel> getOrders() {
    return ordersBox.values.toList();
  }

  List<OrderModel> getUserOrders(String userId) {
    return ordersBox.values.where((o) => o.userId == userId).toList();
  }

  OrderModel? getOrderById(String id) {
    return ordersBox.get(id);
  }

  Future<void> saveOrder(OrderModel order) async {
    await ordersBox.put(order.id, order);
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final order = ordersBox.get(orderId);
    if (order != null) {
      OrderModel updated = order.copyWith(status: newStatus);
      if (newStatus == OrderStatus.shipped) {
        updated = updated.copyWith(shippedDate: DateTime.now());
      } else if (newStatus == OrderStatus.delivered) {
        updated = updated.copyWith(deliveredDate: DateTime.now());
      } else if (newStatus == OrderStatus.paid) {
        updated = updated.copyWith(paymentDate: DateTime.now());
      }
      await ordersBox.put(orderId, updated);
    }
  }

  Future<void> updatePaymentProof(String orderId, String proofUrl) async {
    final order = ordersBox.get(orderId);
    if (order != null) {
      await ordersBox.put(
        orderId,
        order.copyWith(paymentProof: proofUrl),
      );
    }
  }

  // ===== CHAT MESSAGES =====

  List<ChatMessageModel> getMessages(String userEmail) {
    final all = messagesBox.values
        .map((e) => ChatMessageModel.fromMap(Map<String, dynamic>.from(e)))
        .where((m) =>
            m.senderEmail == userEmail || m.senderEmail == 'admin@admin.com')
        .toList();
    all.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return all;
  }

  List<String> getAllConversationUsers() {
    final seen = <String>{};
    for (final raw in messagesBox.values) {
      final m = ChatMessageModel.fromMap(Map<String, dynamic>.from(raw));
      if (m.senderRole == 'user') {
        seen.add(m.senderEmail);
      }
    }
    return seen.toList();
  }

  int getUnreadCount(String userEmail) {
    return messagesBox.values
        .map((e) => ChatMessageModel.fromMap(Map<String, dynamic>.from(e)))
        .where((m) => m.senderEmail == userEmail && !m.isRead)
        .length;
  }

  Future<void> sendMessage(ChatMessageModel msg) async {
    await messagesBox.put(msg.id, msg.toMap());
  }

  Future<void> markMessagesRead(String userEmail) async {
    final keys = <String>[];
    final updated = <Map<String, dynamic>>[];
    for (final key in messagesBox.keys) {
      final raw = messagesBox.get(key);
      if (raw == null) continue;
      final m = ChatMessageModel.fromMap(Map<String, dynamic>.from(raw));
      if (m.senderEmail == userEmail && !m.isRead) {
        keys.add(key.toString());
        updated.add(m.copyWith(isRead: true).toMap());
      }
    }
    for (int i = 0; i < keys.length; i++) {
      await messagesBox.put(keys[i], updated[i]);
    }
  }

  // ===== WALLET =====

  double getWalletBalance() {
    final session = getUserSession();
    if (session == null) return 0;
    final email = session['email'] as String?;
    if (email == null) return 0;
    final raw = usersBox.get(email);
    if (raw == null) return 0;
    final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    return (data['walletBalance'] as num?)?.toDouble() ?? 0;
  }

  Future<void> topUpWallet(double amount) async {
    final session = getUserSession();
    if (session == null) return;
    final email = session['email'] as String?;
    if (email == null) return;
    final raw = usersBox.get(email);
    if (raw == null) return;
    final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    final currentBalance = (data['walletBalance'] as num?)?.toDouble() ?? 0;
    data['walletBalance'] = currentBalance + amount;
    await usersBox.put(email, data);
  }

  Future<void> deductWallet(double amount) async {
    final session = getUserSession();
    if (session == null) return;
    final email = session['email'] as String?;
    if (email == null) return;
    final raw = usersBox.get(email);
    if (raw == null) return;
    final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    final currentBalance = (data['walletBalance'] as num?)?.toDouble() ?? 0;
    data['walletBalance'] = currentBalance - amount;
    await usersBox.put(email, data);
  }

  Future<void> addTopUpRecord(Map<String, dynamic> record) async {
    final id = record['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    await walletBox.put(id, record);
  }

  List<Map<String, dynamic>> getTopUpRecords({String? userEmail}) {
    final records = <Map<String, dynamic>>[];
    for (final key in walletBox.keys) {
      final raw = walletBox.get(key);
      if (raw == null || raw is! Map) continue;
      final record = Map<String, dynamic>.from(raw);
      if (userEmail == null || record['userEmail'] == userEmail) {
        records.add(record);
      }
    }
    records.sort((a, b) => (b['timestamp'] as String).compareTo(a['timestamp'] as String));
    return records;
  }

  List<Map<String, dynamic>> getPendingTopUps() {
    return getTopUpRecords().where((r) => r['status'] == 'pending').toList();
  }

  Future<void> updateTopUpStatus(String id, String status) async {
    final raw = walletBox.get(id);
    if (raw == null || raw is! Map) return;
    final record = Map<String, dynamic>.from(raw);
    record['status'] = status;
    await walletBox.put(id, record);
  }

  // ===== COMPLAINTS =====

  Future<void> addComplaint(Map<String, dynamic> complaint) async {
    final id = complaint['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    await complaintsBox.put(id, complaint);
  }

  List<Map<String, dynamic>> getComplaints({String? userEmail}) {
    final list = <Map<String, dynamic>>[];
    for (final key in complaintsBox.keys) {
      final raw = complaintsBox.get(key);
      if (raw == null || raw is! Map) continue;
      final c = Map<String, dynamic>.from(raw);
      if (userEmail == null || c['userEmail'] == userEmail) {
        list.add(c);
      }
    }
    list.sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));
    return list;
  }

  List<Map<String, dynamic>> getPendingComplaints() {
    return getComplaints().where((c) => c['status'] == 'pending').toList();
  }

  Future<void> updateComplaintStatus(String id, String status) async {
    final raw = complaintsBox.get(id);
    if (raw == null || raw is! Map) return;
    final c = Map<String, dynamic>.from(raw);
    c['status'] = status;
    await complaintsBox.put(id, c);
  }

  // ===== RC BALANCE =====

  double getRcBalance() {
    final raw = usersBox.get('rc_balance');
    if (raw == null) return 0;
    return (raw as num).toDouble();
  }

  Future<void> deductRcBalance(double amount) async {
    final current = getRcBalance();
    await usersBox.put('rc_balance', current + amount);
  }

  double getTotalLossFromComplaints() {
    final complaints = getComplaints().where((c) => c['status'] == 'resolved').toList();
    return complaints.fold<double>(0, (sum, c) => sum + ((c['refundAmount'] as num?)?.toDouble() ?? 0));
  }

  // ===== VOUCHERS =====

  Future<void> addVoucher(Map<String, dynamic> voucher) async {
    final id = voucher['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    await vouchersBox.put(id, voucher);
  }

  List<Map<String, dynamic>> getVouchers() {
    final list = <Map<String, dynamic>>[];
    for (final key in vouchersBox.keys) {
      final raw = vouchersBox.get(key);
      if (raw == null || raw is! Map) continue;
      list.add(Map<String, dynamic>.from(raw));
    }
    list.sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));
    return list;
  }

  List<Map<String, dynamic>> getActiveVouchers() {
    return getVouchers().where((v) => v['isActive'] == true).toList();
  }

  Future<void> updateVoucher(String id, Map<String, dynamic> data) async {
    await vouchersBox.put(id, data);
  }

  Future<void> deleteVoucher(String id) async {
    await vouchersBox.delete(id);
  }
}
