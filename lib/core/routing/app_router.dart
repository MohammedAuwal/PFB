// lib/core/routing/app_router.dart
import 'package:flutter/material.dart';
import 'package:pfb/config/routes/route_names.dart';
import 'package:pfb/features/admin/presentation/screens/add_product_screen.dart';
import 'package:pfb/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:pfb/features/admin/presentation/screens/admin_orders_screen.dart';
import 'package:pfb/features/auth/presentation/screens/login_screen.dart';
import 'package:pfb/features/auth/presentation/screens/signup_screen.dart';
import 'package:pfb/features/cart/presentation/screens/cart_screen.dart';
import 'package:pfb/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:pfb/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:pfb/features/orders/presentation/screens/order_screen.dart';
import 'package:pfb/features/pos/data/models/pos_sale_model.dart';
import 'package:pfb/features/pos/presentation/screens/pos_dashboard_screen.dart';
import 'package:pfb/features/pos/presentation/screens/pos_receipt_screen.dart';
import 'package:pfb/features/pos/data/repositories/pos_repository.dart';
import 'package:pfb/features/products/presentation/screens/product_list_screen.dart';
import 'package:pfb/features/profile/presentation/screens/profile_screen.dart';
import 'package:pfb/features/shell/presentation/screens/main_shell_screen.dart';
import 'package:pfb/features/splash/presentation/screens/splash_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {

      // ── Auth ─────────────────────────────────────────────────────────────
      case RouteNames.splash:
        return _route(const SplashScreen());

      case RouteNames.login:
        return _route(
          LoginScreen(
            redirectTo: settings.arguments is String
                ? settings.arguments as String
                : null,
          ),
        );

      case RouteNames.signup:
        return _route(const SignupScreen());

      // ── Customer Shell ────────────────────────────────────────────────────
      case RouteNames.mainShell:
        return _route(const MainShellScreen());

      case RouteNames.home:
        return _route(const ProductListScreen());

      case RouteNames.cart:
        return _route(const CartScreen());

      case RouteNames.orders:
        return _route(OrderScreen());

      case RouteNames.profile:
        return _route(const ProfileScreen());

      case RouteNames.favorites:
        return _route(FavoritesScreen());

      case RouteNames.notifications:
        return _route(const NotificationsScreen());

      // ── Admin ─────────────────────────────────────────────────────────────
      case RouteNames.admin:
        return _route(const AdminDashboardScreen());

      case RouteNames.addProduct:
        return _route(const AddProductScreen());

      case RouteNames.adminOrders:
        return _route(AdminOrdersScreen());

      // ── POS Terminal ──────────────────────────────────────────────────────
      case RouteNames.posDashboard:
        return _route(const PosDashboardScreen());

      // ── POS Receipt ───────────────────────────────────────────────────────
      // Arguments: PosSaleModel passed directly for immediate post-sale display
      // OR a receiptId String for loading from Firestore
      case RouteNames.posReceipt:
        final args = settings.arguments;

        // Case 1: Sale model passed directly (post-checkout flow)
        if (args is PosSaleModel) {
          return _route(
            PosReceiptScreen(
              sale: args,
              repo: PosRepository(),
            ),
          );
        }

        // Case 2: Receipt ID string (deep link / reprint flow)
        if (args is String && args.isNotEmpty) {
          return _route(
            _PosReceiptLoaderScreen(receiptId: args),
          );
        }

        // Case 3: Map with sale key (flexible passing)
        if (args is Map<String, dynamic>) {
          final sale = args['sale'] as PosSaleModel?;
          final receiptId =
              args['receiptId'] as String?;

          if (sale != null) {
            return _route(
              PosReceiptScreen(
                sale: sale,
                repo: PosRepository(),
              ),
            );
          }

          if (receiptId != null && receiptId.isNotEmpty) {
            return _route(
              _PosReceiptLoaderScreen(
                  receiptId: receiptId),
            );
          }
        }

        // Fallback — bad arguments
        return _route(
          const _PosReceiptErrorScreen(),
        );

      // ── 404 ───────────────────────────────────────────────────────────────
      default:
        return _route(
          const Scaffold(
            body: Center(
              child: Text('Page not found'),
            ),
          ),
        );
    }
  }

  // ── Route Builder ─────────────────────────────────────────────────────────

  static MaterialPageRoute<T> _route<T>(Widget child) {
    return MaterialPageRoute<T>(builder: (_) => child);
  }

  // ── Navigation Helpers ────────────────────────────────────────────────────

  static Future<void> clearAndGo(
    BuildContext context,
    String route, {
    Object? arguments,
  }) async {
    if (!context.mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        route,
        (route) => false,
        arguments: arguments,
      );
    });
  }

  /// Navigate to POS dashboard — admin guard should be applied
  /// before calling this from UI.
  static Future<void> goToPOS(BuildContext context) {
    return Navigator.of(context).pushNamed(
      RouteNames.posDashboard,
    );
  }

  /// Navigate to receipt screen with a completed sale model.
  static Future<void> goToReceipt(
    BuildContext context,
    PosSaleModel sale,
  ) {
    return Navigator.of(context).pushNamed(
      RouteNames.posReceipt,
      arguments: sale,
    );
  }

  /// Navigate to receipt by ID — for reprinting.
  static Future<void> goToReceiptById(
    BuildContext context,
    String receiptId,
  ) {
    return Navigator.of(context).pushNamed(
      RouteNames.posReceipt,
      arguments: receiptId,
    );
  }

  /// Replace current route with POS dashboard.
  static Future<void> replaceWithPOS(BuildContext context) {
    return Navigator.of(context).pushReplacementNamed(
      RouteNames.posDashboard,
    );
  }
}

// ── POS Receipt Loader ─────────────────────────────────────────────────────────
// Loads a sale from Firestore by receipt ID then shows PosReceiptScreen.

class _PosReceiptLoaderScreen extends StatefulWidget {
  final String receiptId;

  const _PosReceiptLoaderScreen({
    required this.receiptId,
  });

  @override
  State<_PosReceiptLoaderScreen> createState() =>
      _PosReceiptLoaderScreenState();
}

class _PosReceiptLoaderScreenState
    extends State<_PosReceiptLoaderScreen> {
  final PosRepository _repo = PosRepository();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final receipt =
        await _repo.getReceiptById(widget.receiptId);

    if (!mounted) return;

    if (receipt == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const _PosReceiptErrorScreen(),
        ),
      );
      return;
    }

    // Build a minimal PosSaleModel from the receipt for display
    // The PosReceiptScreen only needs the sale to call
    // ReceiptModel.fromSale() — we pass the receipt data through
    // a thin adapter here.
    final sale = _receiptToSale(receipt);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PosReceiptScreen(
          sale: sale,
          repo: _repo,
        ),
      ),
    );
  }

  PosSaleModel _receiptToSale(dynamic receipt) {
    // receipt is ReceiptModel — map back to PosSaleModel for display
    // All display fields are available on ReceiptModel
    return PosSaleModel(
      id: receipt.saleId,
      receiptId: receipt.receiptId,
      branchId: receipt.branchId,
      branchName: receipt.branchName,
      cashierUid: receipt.cashierUid,
      cashierName: receipt.cashierName,
      cashierEmail: '',
      customerName: receipt.customerName,
      customerPhone: receipt.customerPhone,
      items: receipt.items,
      subtotal: receipt.subtotal,
      discountValue: receipt.discountValue,
      discountType: receipt.discountType,
      discountReason: receipt.discountReason,
      finalTotal: receipt.finalTotal,
      paymentMethod: receipt.paymentMethod,
      mixedPayment: receipt.mixedPayment,
      amountTendered: receipt.amountTendered,
      changeGiven: receipt.changeGiven,
      saleChannel: 'physical_shop',
      createdAt: receipt.issuedAt,
      status: 'completed',
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// ── POS Receipt Error Screen ───────────────────────────────────────────────────

class _PosReceiptErrorScreen extends StatelessWidget {
  const _PosReceiptErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Receipt not found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The receipt could not be loaded.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}