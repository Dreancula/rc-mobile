## Goal
Complete shipping, checkout, chat, stock synchronization, wishlist, voucher, profile, AI stylist, wallet/top-up, and complaint/refund features.

## Constraints & Preferences
- Store location: Jl. Margonda No.8, Pondok Cina, Kecamatan Beji, Kota Depok, Jawa Barat 16424
- Shipping cost = distance (from Depok to user's city) × total product weight × courier rate
- Products have single color (removed color variants from product detail and cart)
- Products must show available stock and weight (grams) synced with DB; admin sets both
- Users must enter full address during registration; existing users without address prompted at login
- Courier options: GoSend (same-day, ≤80km), SiCepat BEST (1-day, ≤200km), SiCepat REG, JNE REG, J&T Express, JNE OKE (economical)
- Chat stored locally in Hive (admin and buyer share same device storage)
- Monochrome design; existing admin panel styling preserved
- AI Stylist: recommendation engine mapping style → categories, size by weight
- Voucher: welcome voucher (Rp 20,000) on registration; Dompet Digital RC only, COD cannot use
- Nav bar order: HOME, KATEGORI, AI, RIWAYAT, PROFIL
- QRIS replaced by Dompet Digital RC as payment method (wallet + COD)
- Wallet top-up includes admin fee Rp 2,500 per transaction
- Complaints: user can submit with photos + description 5 min after order delivered; refund 30% of order total (RC loss)

### Done
- Updated `ProductModel`: added `stock` (int) and `weight` (double, grams); removed `availableColors`
- Updated `CartItemModel`: removed `selectedColor`; added `weight` + `totalWeight`
- Updated `OrderModel`: added `courier`, `courierService`, `estimatedDelivery`; extended `PaymentMethod` enum with `wallet`
- Rewrote adapters (`ProductModelAdapter`, `OrderModelAdapter`) for new fields
- Created `ShippingCalculator` service: 50+ city distances from Depok, 6 courier rate tables
- Updated `HiveDb.registerUser()`: accepts `address` and `phone`, stored in user map; adds `voucher: 20000`, `walletBalance: 0.0`
- Updated `_seedProducts()`: all 6 seed products have `stock` (20-100) and `weight` (100-600g)
- Updated `register_screen.dart`: added phone and address fields with validation
- Added address check in `MainNavigationScreen`: `_checkAddress()` via `addPostFrameCallback`, shows `_AddressFormSheet` bottom sheet if address missing
- Updated `product_detail_screen.dart`: removed color selector, added stock/weight badges, quantity capped by stock, low-stock warning (red text when ≤5), description from `widget.product.description` (fallback to default), favorite heart toggle persists to HiveDb
- Updated `cart_screen.dart`: removed shipping cost row (computed at checkout), shows weight per item; fixed scroll bug by replacing `Column`+`Expanded(ListView)` with plain `ListView`
- Updated `cart_item_card.dart`: shows "size • weight" instead of "color, size"
- Updated `checkout_screen.dart`: real user address/phone, courier selection with distance badge, dynamic shipping cost, voucher section (toggle for Dompet Digital RC, locked/disabled for COD), discount row in order summary, voucher cleared after order placed; replaced QRIS payment method with Dompet Digital RC + COD; added wallet info card (balance, top-up button, 2% discount display, insufficient balance warning with redirect to TopUp); wallet deduction on order success; wallet discount 2% of subtotal (max Rp 20.000)
- Updated `admin_product_screen.dart`: added stock and weight text fields with validation
- Updated `cart_repository.dart`: removed `selectedColor` param from `addItem`; passes `product.weight`; stock check in `addItem` (throws if insufficient) and `incrementQuantity` (caps at stock)
- Updated `order_repository.dart`: `createOrder` accepts `courier`, `courierService`, `estimatedDelivery`, `voucherDiscount`; stores in `OrderModel`; stock check before order; stock deduction after order; stock restore in `_restoreStock()` called from `updateOrderStatus`/`syncOrderStatus` on cancellation
- Fixed errors: duplicate `maxLines` in register_screen, `ShippingOption` → `CourierOption`, `estimatedDistance` → `estimatedDistanceKm`, `estimatedDays` → `etd`, removed `await` on sync `calculate()` call, duplicate `'Bogor'` key in `_cityDistances`, missing `_paymentMethods` list, duplicate `initState` in checkout, `getVoucher()` type cast (`as double?` → `(as num?)?.toDouble()`)
- Bumped `_dbVersion` from 2→3 (then 3→4 for chat, 4→5 for AI Stylist/wishlist/voucher, 5→6 for wallet/complaint)
- Created `ChatMessageModel` (id, senderEmail, senderName, senderRole, message, timestamp, isRead)
- Created `ChatMessageModelAdapter` (typeId=6)
- Added `messagesBox` + CRUD methods in `HiveDb`: `getMessages()`, `sendMessage()`, `markMessagesRead()`, `getAllConversationUsers()`, `getUnreadCount()`, `getVoucher()`, `setVoucher()`, `getUserPhoto()`
- Updated `HiveDb.updateUserProfile()`: syncs `name` to authBox session if present
- Created `ChatScreen` for buyer (message bubbles, input bar, auto-scroll, timestamps)
- Created `AdminChatScreen` for admin (conversation list with unread badges, chat detail view with reply)
- Created `AiStylistScreen` (replaced PetsGameScreen): gender toggle, weight input, style chips (Casual/Formal/Sporty/Streetwear), product recommendations by category mapping, size by weight, white theme, total price display, individual add-to-cart + add-all-to-cart
- Created `WishlistScreen`: shows all favorited products from HiveDB, unfavorite, add to cart, navigate to detail
- Created `EditProfileScreen`: image picker for photo, name/phone editing, saves to HiveDB
- Created `ShippingAddressScreen`: edit phone + full address, saves to HiveDB
- Created `HelpCenterScreen`: FAQ list (6 items)
- Created `AboutUsScreen`: brand info, contact details
- Updated profile screen: StatefulWidget, photo/name/email from DB, menu items wired (Wishlist, Edit Profile, Shipping Address, Help Center, About Us), wallet card (balance + Top Up button), voucher card label changed from "QRIS ONLY" → "Dompet Digital RC", removed Payment Methods
- Updated home screen: sticky header (moved out of CustomScrollView), dynamic `userName` from `HiveDb.getUserSession()`, notification icon replaced with chat icon → `ChatScreen`, "Produk Populer" → "Produk", "Lihat Semua" on categories/products navigates to `CategoryScreen`; **replaced promo banner section with Dompet Digital RC card** (gradient, balance, Top Up button)
- Updated category screen: uses `HiveDb.getActiveProducts()` instead of `HomeDummyData`, favorite toggle persists to HiveDB
- Updated nav bar order: HOME, KATEGORI, AI, RIWAYAT, PROFIL (AI tab with `Icons.smart_toy`)
- Updated `CartRepository.formatPrice()`: full thousand-separator format (e.g. "Rp 1.400.000") instead of abbreviated (JT/RB)
- Updated price formatting in `category_screen.dart`, `product_card.dart`, `home_screen.dart` to use same full format
- Cleaned up: removed unused `_navigateToSearch`, `_citiesFound`, deprecated `withOpacity` → `withValues`, unnecessary underscores in `errorBuilder`, old PetsGameScreen file renamed to `ai_stylist_screen.dart`, removed `HomeDummyData` import from home_screen
- Added try-catch in `product_detail_screen._addToCart()` to handle stock exceptions
- Created `ProductImage` widget (`core/widgets/product_image.dart`): auto-detects network vs local file path; used in 9 user-facing screens (product_detail, home, product_card, category, wishlist, checkout, cart_item_card, ai_stylist, history)
- **Wallet/Dompet Digital RC**: added `walletBox` + CRUD in HiveDb (`getWalletBalance`, `topUpWallet`, `deductWallet`, `addTopUpRecord`, `getTopUpRecords`, `getPendingTopUps`, `updateTopUpStatus`); admin seed includes `walletBalance: 0.0`
- Created `TopUpScreen`: preset amounts (50k/100k/200k/500k) + custom input, admin fee Rp 2.500 breakdown, total payment display, QRIS placeholder payment view, "Sudah Bayar" creates pending record
- Created `AdminWalletScreen` (index 7 in admin drawer): lists pending top-ups with confirm/reject buttons; confirmation credits user wallet
- **Complaint/Refund**: added `complaintsBox` + CRUD in HiveDb (`addComplaint`, `getComplaints`, `getPendingComplaints`, `updateComplaintStatus`); added `rcBalance` tracking (`getRcBalance`, `deductRcBalance`, `getTotalLossFromComplaints`) stored in `usersBox` key `'rc_balance'`
- Created `ComplaintScreen`: order info, description field, photo upload (up to 3, via `image_picker`), refund info (30% of total), submit button
- Created `AdminComplaintScreen` (index 9 in admin drawer): pending complaints list with user/order info, description, photo thumbnails, confirm (processes 30% refund, deducts from `rcBalance`) and reject buttons
- Updated `history_screen.dart`: added complaint button that appears 5 min after order is delivered (status `delivered` + `deliveredDate` check); navigates to `ComplaintScreen` with order id/number/total
- Admin drawer: added "Dompet Digital" (index 7) and "Komplain" (index 9)
- Admin dashboard: shows total `rcBalance` loss from resolved complaints

### In Progress
- (none)

### Blocked
- Gallery picker channel error still requires `flutter clean && flutter run` full rebuild

## Key Decisions
- Shipping uses estimated city distance from Depok (no real API); 50+ cities mapped with approximate km
- Courier rates: base fee + (weightKg × ratePerKgPerKm × distance/10); minimum 1kg billed
- Weight tracked per `CartItemModel` so checkout can compute total shipment weight
- Stock deducted at order creation (not at delivery) to prevent overselling
- Products with `stock=0` or insufficient stock prevented at checkout via `createOrder` validation
- Chat stored in Hive (same device, shared between admin/user logins); messages keyed by timestamp-id; conversation identified by user email
- `_dbVersion` incremented each time adapter binary format changes to force box deletion and reseed
- AI Stylist replaces gamified PETS screen; style→category mapping hardcoded (Casual→T-Shirt/Hoodie/Celana/Jaket, Formal→Kemeja/Celana, etc.)
- Size recommendation by weight: <50=S, 50-60=M, 60-75=L, >75=XL
- Voucher stored in user map in usersBox; welcome voucher Rp 20,000 given on registration; Dompet Digital RC only toggle at checkout
- Wishlist persisted via `ProductModel.isFavorite` saved to HiveDB; separate `WishlistScreen` queries active products where `isFavorite == true`
- Profile photo stored as local file path in user map; `image_picker` package used for gallery
- QRIS fully replaced by Dompet Digital RC as payment method
- Wallet discount: 2% of subtotal, capped at Rp 20,000, shown in order summary
- Top-up admin fee Rp 2,500 is added to payment total, not deducted from wallet balance
- Complaint refund: 30% of order total, deducted from `rcBalance` (stored as `'rc_balance'` key in `usersBox`), shown on admin dashboard
- Complaint button appears only when order status is `delivered` and `deliveredDate` is at least 5 minutes in the past

## Next Steps
1. Test all flows end-to-end: registration → wishlist → AI stylist → checkout with wallet → top-up → order → complaint → refund → check RC losses on dashboard
2. Verify chat works across admin/buyer roles on same device
3. Add voucher admin management (optional)
4. Consider migrating shipping calculator to real API integration

## Critical Context
- Flutter 3.41.9, Dart 3.11.5, Hive for persistence
- `_dbVersion = 6`; migration deletes all boxes on version mismatch
- `OrderRepository` singleton with in-memory cache; `syncOrderStatus()` keeps in-memory list synced when admin updates order
- `CartRepository` singleton; always reads/writes through `HiveDb`
- All models from Hive non-typed boxes must explicitly cast via `Map<String, dynamic>.from(raw)` to avoid `_Map<dynamic, dynamic>` subtype errors
- `ChatMessageModel.toMap()` serializes timestamp as ISO 8601 string; `fromMap()` parses it back
- `image_picker` package added to pubspec.yaml
- `ProductModel` `isFavorite` field persisted in Hive; initially set via `toMap()/fromMap()` in adapter
- `walletBalance` stored in user data map; access via `num?` cast to avoid int/double issues
- `rcBalance` stored in `usersBox` under key `'rc_balance'`; complaint refunds deduct from it
- `ProductImage` widget handles both `Image.network` and `Image.file` based on URL prefix; used in all product image displays
- `OrderModel` has no `orderNumber` field; displayed order number = last 6 chars of `id`

## Relevant Files
- `lib/core/widgets/product_image.dart`: handles network + local file images
- `lib/core/database/hive_db.dart`: _dbVersion=6, walletBox, complaintsBox, rcBalance CRUD, voucher/photo CRUD, updateUserProfile syncs name to session
- `lib/features/home/domain/models/product_model.dart`: stock, weight, isFavorite fields
- `lib/features/home/domain/models/cart_model.dart`: removed selectedColor, added weight/totalWeight
- `lib/features/home/domain/models/order_model.dart`: courier, courierService, estimatedDelivery; PaymentMethod includes wallet
- `lib/features/home/domain/models/chat_message_model.dart`: chat message model
- `lib/features/home/data/services/shipping_calculator.dart`: distance lookup + courier rates
- `lib/features/home/data/repositories/order_repository.dart`: stock check/deduction/restore in createOrder, updateOrderStatus, syncOrderStatus
- `lib/features/home/data/repositories/cart_repository.dart`: stock-aware addItem/incrementQuantity, formatPrice full format
- `lib/core/database/adapters/chat_message_model_adapter.dart`: typeId=6
- `lib/features/home/presentation/screens/top_up_screen.dart`: top-up flow with admin fee Rp 2.500
- `lib/features/home/presentation/screens/complaint_screen.dart`: user complaint with photo upload & description
- `lib/features/home/presentation/screens/chat_screen.dart`: buyer chat UI
- `lib/features/home/presentation/screens/ai_stylist_screen.dart`: AI Stylist recommendation screen
- `lib/features/home/presentation/screens/wishlist_screen.dart`: wishlist view with unfavorite + add to cart
- `lib/features/home/presentation/screens/edit_profile_screen.dart`: profile editing with photo upload
- `lib/features/home/presentation/screens/shipping_address_screen.dart`: address editing
- `lib/features/home/presentation/screens/help_center_screen.dart`: FAQ
- `lib/features/home/presentation/screens/about_us_screen.dart`: company info
- `lib/features/home/presentation/screens/home_screen.dart`: sticky header, dynamic name, chat icon, category nav, Dompet Digital RC card replaces promo banner
- `lib/features/home/presentation/screens/category_screen.dart`: uses HiveDb products, persistent favorite toggle
- `lib/features/home/presentation/screens/checkout_screen.dart`: Dompet Digital RC + COD payment, wallet info card, 2% discount, top-up redirect
- `lib/features/home/presentation/screens/cart_screen.dart`: scrollable ListView for cart items
- `lib/features/home/presentation/screens/product_detail_screen.dart`: stock-check try-catch, low-stock warning, real description, favorite heart toggle
- `lib/features/home/presentation/screens/history_screen.dart`: complaint button 5 min after delivery
- `lib/features/home/presentation/widgets/product_card.dart`: full price format
- `lib/features/home/presentation/widgets/cart_item_card.dart`: user ProductImage
- `lib/features/main_navigation/presentation/screens/main_navigation_screen.dart`: nav order HOME/KATEGORI/AI/RIWAYAT/PROFIL, ProfileScreen with wallet card, voucher card, all menu items wired
- `lib/features/admin/presentation/screens/admin_screen.dart`: "Dompet Digital" index 7, "Komplain" index 9, "Chat Pembeli" index 8
- `lib/features/admin/presentation/screens/admin_wallet_screen.dart`: admin top-up confirmation
- `lib/features/admin/presentation/screens/admin_complaint_screen.dart`: admin complaint review + 30% refund processing
- `lib/features/admin/presentation/screens/admin_dashboard.dart`: displays total RC loss from resolved complaints
- `lib/features/admin/presentation/screens/admin_chat_screen.dart`: admin conversation list + detail
- `lib/features/auth/presentation/screens/register_screen.dart`: welcome voucher on registration
