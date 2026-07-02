import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/database/hive_db.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../../data/indonesia_regions.dart';
import '../../../../core/services/location_helper.dart';
import '../../../home/data/repositories/cart_repository.dart';
import '../../../home/data/repositories/order_repository.dart';
import '../../../home/domain/models/order_model.dart';
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
import '../../../auth/presentation/screens/forgot_password_screen.dart';
import '../../../home/presentation/screens/shipping_address_screen.dart';
import '../../../home/presentation/screens/help_center_screen.dart';
import '../../../home/presentation/screens/about_us_screen.dart';

import '../../../home/presentation/screens/voucher_screen.dart';
import '../../../home/presentation/screens/points_screen.dart';
import '../../../home/presentation/screens/my_reviews_screen.dart';

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
              ProductModel(id: '', name: 'Produk', price: 0, images: const [], category: '');
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColorMedium,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                showBadge: _cart.itemCount > 0,
                badgeCount: _cart.itemCount,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.category_outlined,
                activeIcon: Icons.category,
                label: 'Kategori',
              ),
              _buildAISpecialNavItem(),
              _buildNavItem(
                index: 3,
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long,
                label: 'Riwayat',
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    bool showBadge = false,
    int badgeCount = 0,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabSelected(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.pitchBlack.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 24,
                child: showBadge
                    ? Badge(
                        label: Text(
                          badgeCount > 9 ? '9+' : '$badgeCount',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Icon(
                          isSelected ? activeIcon : icon,
                          size: 22,
                          color: isSelected
                              ? AppColors.pitchBlack
                              : AppColors.softGrey,
                        ),
                      )
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child: Icon(
                          isSelected ? activeIcon : icon,
                          key: ValueKey('nav_${index}_$isSelected'),
                          size: 22,
                          color: isSelected
                              ? AppColors.pitchBlack
                              : AppColors.softGrey,
                        ),
                      ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color:
                      isSelected ? AppColors.pitchBlack : AppColors.softGrey,
                  letterSpacing: 0.2,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAISpecialNavItem() {
    final isSelected = _currentIndex == 2;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabSelected(2),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.blackGradient : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : AppColors.softGrey.withValues(alpha: 0.25),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.pitchBlack.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.pureWhite
                      : AppColors.pitchBlack.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: isSelected
                      ? AppColors.pitchBlack
                      : AppColors.softGrey,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color:
                      isSelected ? AppColors.pureWhite : AppColors.softGrey,
                  letterSpacing: 0.3,
                ),
                child: const Text('AI'),
              ),
            ],
          ),
        ),
      ),
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
        child: RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
            children: [
              // Profile Header with Cover Banner
              _buildProfileHeader(name, email, photo),

              // Order Stats Row
              _buildOrderStats(),

              // Account Section
              _buildSectionTitle(Translations.of('my_account', context)),
              const SizedBox(height: 12),
              _buildMenuCard(context, [
                _ProfileMenuItem(
                  icon: Icons.receipt_long_outlined,
                  title: Translations.of('order_history', context),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ).then((_) => _refresh()),
                ),
                _ProfileMenuItem(
                  icon: Icons.star_outline_rounded,
                  title: Translations.of('my_reviews', context),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyReviewsScreen()),
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
                  title: Translations.of('edit_profile', context),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  ).then((_) => _refresh()),
                ),
                _ProfileMenuItem(
                  icon: Icons.location_on_outlined,
                  title: Translations.of('shipping_address', context),
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
              _buildSectionTitle(Translations.of('settings', context)),
              const SizedBox(height: 12),
              _buildMenuCard(context, [
                _ProfileMenuItem(
                  icon: Icons.translate_rounded,
                  title: Translations.of('language', context),
                  onTap: () => _showLanguageSheet(context),
                ),
                _ProfileMenuItem(
                  icon: Icons.help_outline_rounded,
                  title: Translations.of('help_center', context),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
                  ),
                ),
                _ProfileMenuItem(
                  icon: Icons.info_outline_rounded,
                  title: '${Translations.of('about', context)} Us',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                  ),
                ),
                _ProfileMenuItem(
                  icon: Icons.lock_outline_rounded,
                  title: Translations.of('change_password', context),
                  onTap: () {
                    final email = HiveDb.instance.getUserSession()?['email'] as String? ?? '';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ForgotPasswordScreen(
                          initialEmail: email,
                          title: Translations.of('change_password', context),
                          readOnlyEmail: true,
                        ),
                      ),
                    );
                  },
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
    ),
    );
  }

  Widget _buildProfileHeader(String name, String email, String photo) {
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 4),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: AppColors.lightGrey,
              shape: BoxShape.circle,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: photo.isNotEmpty
                  ? Image.file(File(photo), fit: BoxFit.cover)
                  : const Icon(Icons.person_outline, size: 46, color: AppColors.softGrey),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.softGrey,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStats() {
    final session = _db.getUserSession();
    final userId = session?['id'] ?? '';
    final orders = OrderRepository().getUserOrders(userId);
    final diproses = orders.where((o) => o.status == OrderStatus.processing || o.status == OrderStatus.paid).length;
    final dikirim = orders.where((o) => o.status == OrderStatus.shipped).length;
    final selesai = orders.where((o) => o.status == OrderStatus.delivered).length;
    final points = _db.getPointsBalance();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.lightGrey.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(child: _statItem('Diproses', '$diproses', Icons.receipt_outlined, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryScreen())).then((_) => _refresh());
            })),
            _statDivider(),
            Expanded(child: _statItem('Dikirim', '$dikirim', Icons.local_shipping_outlined, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryScreen())).then((_) => _refresh());
            })),
            _statDivider(),
            Expanded(child: _statItem('Selesai', '$selesai', Icons.check_circle_outline, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryScreen())).then((_) => _refresh());
            })),
            _statDivider(),
            Expanded(child: _statItem('Poin', '$points', Icons.stars_rounded, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PointsScreen())).then((_) => _refresh());
            })),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String count, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.pitchBlack),
          const SizedBox(height: 6),
          Text(
            count,
            style: AppTextStyles.heading4.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.softGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.borderGrey.withValues(alpha: 0.5),
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
                    Translations.of('logout', context),
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

  void _showLanguageSheet(BuildContext context) {
    final langProvider = context.read<LanguageProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _LanguageSheetProfile(langProvider: langProvider);
      },
    );
  }
}

class _LanguageSheetProfile extends StatefulWidget {
  final LanguageProvider langProvider;

  const _LanguageSheetProfile({required this.langProvider});

  @override
  State<_LanguageSheetProfile> createState() => _LanguageSheetProfileState();
}

class _LanguageSheetProfileState extends State<_LanguageSheetProfile>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lp = widget.langProvider;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                Translations.tr('select_language', lp.locale),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A0A0A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                Translations.tr('choose_language', lp.locale),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF999999),
                ),
              ),
              const SizedBox(height: 20),
              _buildOption(
                label: 'English',
                isSelected: lp.locale == AppLocale.en,
                onTap: () {
                  lp.setLocale(AppLocale.en);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 10),
              _buildOption(
                label: 'Bahasa Indonesia',
                isSelected: lp.locale == AppLocale.id,
                onTap: () {
                  lp.setLocale(AppLocale.id);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF0A0A0A)
            : const Color(0xFF0A0A0A).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.language, size: 22, color: Color(0xFF0A0A0A)),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF0A0A0A),
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  const Icon(Icons.check_rounded, size: 22, color: Colors.white),
              ],
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
  String _selectedProvince = '';
  String _selectedCity = '';
  List<String> _cities = [];
  bool _saving = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    final db = HiveDb.instance;
    _phoneCtrl.text = db.getUserPhone();
    _addressCtrl.text = db.getUserAddress();
    _selectedProvince = db.getUserProvince();
    _selectedCity = db.getUserCity();
    if (_selectedProvince.isNotEmpty) {
      _cities = IndonesiaRegions.citiesByProvince[_selectedProvince] ?? [];
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  String _buildFullAddress() {
    final parts = <String>[];
    if (_addressCtrl.text.trim().isNotEmpty) parts.add(_addressCtrl.text.trim());
    if (_selectedCity.isNotEmpty) parts.add(_selectedCity);
    if (_selectedProvince.isNotEmpty) parts.add(_selectedProvince);
    return parts.join(', ');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProvince.isEmpty || _selectedCity.isEmpty) return;
    setState(() => _saving = true);
    await HiveDb.instance.updateUserProfile({
      'phone': _phoneCtrl.text.trim(),
      'address': _buildFullAddress(),
      'province': _selectedProvince,
      'city': _selectedCity,
    });
    setState(() => _saving = false);
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onSaved();
  }

  Future<void> _detectLocation() async {
    setState(() => _locating = true);
    final result = await LocationHelper.detectLocation();
    if (!mounted) return;
    setState(() => _locating = false);

    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    String? matchedProvince = result.province;
    if (matchedProvince != null && !IndonesiaRegions.provinces.contains(matchedProvince)) {
      matchedProvince = null;
    }

    String? matchedCity = result.city;
    List<String> citiesInProvince = matchedProvince != null
        ? List<String>.from(IndonesiaRegions.citiesByProvince[matchedProvince] ?? [])
        : <String>[];

    if (matchedCity != null) {
      final found = IndonesiaRegions.findMatchingCity(matchedCity, citiesInProvince);
      if (found != null) {
        matchedCity = found;
      } else if (matchedProvince != null) {
        final (prov, city) = IndonesiaRegions.findProvinceAndCity(matchedCity);
        if (prov != null && city != null) {
          matchedProvince = prov;
          matchedCity = city;
          citiesInProvince = List<String>.from(IndonesiaRegions.citiesByProvince[matchedProvince]!);
        } else {
          matchedCity = null;
        }
      } else {
        final (prov, city) = IndonesiaRegions.findProvinceAndCity(matchedCity);
        if (prov != null && city != null) {
          matchedProvince = prov;
          matchedCity = city;
          citiesInProvince = List<String>.from(IndonesiaRegions.citiesByProvince[matchedProvince]!);
        } else {
          matchedCity = null;
        }
      }
    }

    setState(() {
      _selectedProvince = matchedProvince ?? '';
      _cities = citiesInProvince;
      _selectedCity = matchedCity ?? '';
    });
  }

  InputDecoration _inputDec(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.charcoal, size: 20),
      filled: true,
      fillColor: AppColors.lightGrey,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    );
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
              'Alamat Pengiriman',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.pitchBlack),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lengkapi alamat untuk melanjutkan',
              style: TextStyle(fontSize: 14, color: AppColors.softGrey),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _phoneCtrl,
              decoration: _inputDec('No. Telepon', Icons.phone_outlined),
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.isEmpty) ? 'No. telepon harus diisi' : null,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 48,
              child: OutlinedButton.icon(
                onPressed: _locating ? null : _detectLocation,
                icon: _locating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location_rounded, size: 20),
                label: Text(_locating ? 'Mendeteksi lokasi...' : 'Deteksi Lokasi Saya'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.pitchBlack,
                  side: const BorderSide(color: AppColors.pitchBlack),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedProvince.isEmpty ? null : _selectedProvince,
              decoration: _inputDec('Provinsi', Icons.map_outlined),
              items: IndonesiaRegions.provinces.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) {
                if (v != null) setState(() {
                  _selectedProvince = v;
                  _selectedCity = '';
                  _cities = IndonesiaRegions.citiesByProvince[v] ?? [];
                });
              },
              validator: (v) => v == null || v.isEmpty ? 'Pilih provinsi' : null,
              dropdownColor: AppColors.pureWhite,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCity.isEmpty ? null : _selectedCity,
              decoration: _inputDec('Kota/Kabupaten', Icons.location_city_outlined),
              items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedCity = v);
              },
              validator: (v) => v == null || v.isEmpty ? 'Pilih kota' : null,
              dropdownColor: AppColors.pureWhite,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressCtrl,
              decoration: _inputDec('Detail alamat (jalan, gang, no. rumah)', Icons.location_on_outlined),
              maxLines: 2,
              validator: (v) => (v == null || v.isEmpty) ? 'Detail alamat harus diisi' : null,
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                    : const Text('Simpan Alamat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
