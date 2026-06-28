import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/database/hive_db.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../home/data/repositories/cart_repository.dart';
import '../../../home/domain/models/product_model.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../home/presentation/screens/cart_screen.dart';
import '../../../home/presentation/screens/checkout_screen.dart';
import '../../../home/presentation/screens/product_detail_screen.dart';
import '../../../home/presentation/screens/category_screen.dart';
import '../../../home/presentation/screens/history_screen.dart';
import '../../../home/presentation/screens/ai_stylist_screen.dart';
import '../../../home/presentation/screens/wishlist_screen.dart';
import '../../../home/presentation/screens/edit_profile_screen.dart';
import '../../../home/presentation/screens/shipping_address_screen.dart';
import '../../../home/presentation/screens/help_center_screen.dart';
import '../../../home/presentation/screens/about_us_screen.dart';
import '../../../home/presentation/screens/top_up_screen.dart';
import '../../../home/presentation/screens/voucher_screen.dart';

/// Main Navigation Screen with Bottom Navigation Bar
class MainNavigationScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const MainNavigationScreen({
    super.key,
    this.onLogout,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final CartRepository _cart = CartRepository();

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _initializeScreens();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAddress());
  }

  void _checkAddress() {
    if (!HiveDb.instance.hasUserAddress()) {
      _showAddressPrompt();
    }
  }

  void _showAddressPrompt() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AddressFormSheet(
        onSaved: () => setState(() {}),
      ),
    );
  }

  void _initializeScreens() {
    _screens.clear();
    _screens.add(_buildHomeScreen());
    _screens.add(const CategoryScreen());
    _screens.add(const AiStylistScreen());
    _screens.add(const HistoryScreen());
    _screens.add(ProfileScreen(onLogout: _handleLogout));
  }

  Widget _buildHomeScreen() {
    return HomeScreen(
      onProductTap: _navigateToProductDetail,
    );
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) {
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(
          onCheckout: _navigateToCheckout,
          onContinueShopping: () {
            Navigator.pop(context);
          },
          onProductTap: (productId) {
            final product = HiveDb.instance.getProductById(productId) ??
              ProductModel(id: '', name: 'Produk', price: 0, imageUrl: '', category: '');
            _navigateToProductDetail(product);
          },
        ),
      ),
    );
  }

  void _navigateToCheckout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          onOrderSuccess: () {
            Navigator.popUntil(context, (route) => route.isFirst);
            setState(() {
              _screens[0] = _buildHomeScreen();
            });
          },
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _handleLogout() async {
    await HiveDb.instance.clearUserSession();
    widget.onLogout?.call();
  }

  void _navigateToProductDetail(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(
          product: product,
          onAddToCart: _navigateToCart,
        ),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return NavigationBar(
      backgroundColor: AppColors.primaryWhite,
      indicatorColor: AppColors.primaryBlack,
      surfaceTintColor: Colors.transparent,
      shadowColor: AppColors.shadowColor,
      elevation: 2,
      height: kBottomNavigationBarHeight,
      selectedIndex: _currentIndex,
      onDestinationSelected: _onTabSelected,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        _buildNavDestination(
          index: 0,
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          label: 'Home',
        ),
        const NavigationDestination(
          icon: Icon(Icons.category_outlined, color: AppColors.softGrey),
          selectedIcon: Icon(Icons.category, color: AppColors.primaryWhite),
          label: 'Kategori',
        ),
        const NavigationDestination(
          icon: Icon(Icons.smart_toy, color: AppColors.softGrey),
          selectedIcon: Icon(Icons.smart_toy, color: AppColors.primaryWhite),
          label: 'AI',
        ),
        const NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined, color: AppColors.softGrey),
          selectedIcon: Icon(Icons.receipt_long, color: AppColors.primaryWhite),
          label: 'Riwayat',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline, color: AppColors.softGrey),
          selectedIcon: Icon(Icons.person, color: AppColors.primaryWhite),
          label: 'Profil',
        ),
      ],
    );
  }

  Widget _buildNavDestination({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    if (_cart.itemCount > 0 && index == 0) {
      return Badge(
        label: Text(
          _cart.itemCount > 9 ? '9+' : '${_cart.itemCount}',
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
        ),
        child: NavigationDestination(
          icon: Icon(icon, color: AppColors.softGrey),
          selectedIcon: Icon(activeIcon, color: AppColors.primaryWhite),
          label: label,
        ),
      );
    }

    return NavigationDestination(
      icon: Icon(icon, color: AppColors.softGrey),
      selectedIcon: Icon(activeIcon, color: AppColors.primaryWhite),
      label: label,
    );
  }
}

/// Profile Screen - Clean Modern & Elegant Monochrome Design
class ProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const ProfileScreen({super.key, this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final HiveDb _db = HiveDb.instance;

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final session = _db.getUserSession();
    final name = session?['name'] as String? ?? 'User';
    final email = session?['email'] as String? ?? '';
    final photo = _db.getUserPhoto();

    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 48),
              // Profile Header with Squircle Frame
              _buildProfileHeader(name, email, photo),
              const SizedBox(height: 40),

              // Account Section
              _buildSectionTitle('Account'),
              const SizedBox(height: 12),
              _buildMenuCard(context, [
                _ProfileMenuItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'Riwayat Pesanan',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ).then((_) => _refresh()),
                ),
                _ProfileMenuItem(
                  icon: Icons.favorite_outline,
                  title: 'Wishlist',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WishlistScreen()),
                  ).then((_) => _refresh()),
                ),
                _ProfileMenuItem(
                  icon: Icons.edit_outlined,
                  title: 'Edit Profile',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  ).then((_) => _refresh()),
                ),
                _ProfileMenuItem(
                  icon: Icons.location_on_outlined,
                  title: 'Shipping Address',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ShippingAddressScreen()),
                  ).then((_) => _refresh()),
                ),
                _ProfileMenuItem(
                  icon: Icons.confirmation_num_outlined,
                  title: 'Voucher',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VoucherScreen()),
                  ).then((_) => _refresh()),
                ),
              ]),

              const SizedBox(height: 28),

              // Settings Section
              _buildSectionTitle('Settings'),
              const SizedBox(height: 12),
              _buildMenuCard(context, [
                _ProfileMenuItem(
                  icon: Icons.help_outline_rounded,
                  title: 'Help Center',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
                  ),
                ),
                _ProfileMenuItem(
                  icon: Icons.info_outline_rounded,
                  title: 'About Us',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                  ),
                ),
              ]),

              const SizedBox(height: 32),

              // Logout Button - Black Outlined Style
              _buildLogoutButton(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String name, String email, String photo) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: ShapeDecoration(
            color: AppColors.lightGrey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            shadows: [
              BoxShadow(
                color: AppColors.pitchBlack.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: photo.isNotEmpty
                ? Image.file(File(photo), fit: BoxFit.cover)
                : const Icon(Icons.person_outline, size: 48, color: AppColors.softGrey),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: AppTextStyles.heading3.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.softGrey,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.softGrey,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, List<_ProfileMenuItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.lightGrey.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.pitchBlack.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                _buildMenuItemTile(item),
                if (index < items.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 68),
                    child: Container(
                      height: 1,
                      color: AppColors.lightGrey.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMenuItemTile(_ProfileMenuItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: ShapeDecoration(
                  color: AppColors.pitchBlack.withValues(alpha: 0.04),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Icon(
                  item.icon,
                  size: 22,
                  color: AppColors.pitchBlack,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.pitchBlack,
                    fontSize: 15,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: AppColors.softGrey.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.pitchBlack,
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onLogout,
              borderRadius: BorderRadius.circular(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.logout_rounded,
                    size: 22,
                    color: AppColors.pitchBlack,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Logout',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.pitchBlack,
                      fontSize: 15,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Model for Profile Menu Item
class _ProfileMenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

class _AddressFormSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddressFormSheet({required this.onSaved});

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _phoneCtrl.text = HiveDb.instance.getUserPhone();
    _addressCtrl.text = HiveDb.instance.getUserAddress();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await HiveDb.instance.updateUserProfile({
      'phone': _phoneCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
    });
    setState(() => _saving = false);
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Icon(Icons.location_on_rounded, size: 32, color: AppColors.pitchBlack),
            const SizedBox(height: 12),
            const Text(
              'Shipping Address Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.pitchBlack,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please provide your shipping address to continue shopping.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.softGrey,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _phoneCtrl,
              decoration: InputDecoration(
                hintText: 'Phone number',
                prefixIcon: Icon(Icons.phone_outlined, color: AppColors.charcoal, size: 20),
                filled: true,
                fillColor: AppColors.lightGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.isEmpty) ? 'Phone is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressCtrl,
              decoration: InputDecoration(
                hintText: 'Full address (street, city, postal code)',
                prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.charcoal, size: 20),
                filled: true,
                fillColor: AppColors.lightGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 3,
              validator: (v) => (v == null || v.isEmpty) ? 'Address is required' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pitchBlack,
                  foregroundColor: AppColors.pureWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.pureWhite),
                        ),
                      )
                    : const Text(
                        'Save Address',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
