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
import 'package:pfb/features/products/presentation/screens/product_list_screen.dart';
import 'package:pfb/features/profile/presentation/screens/profile_screen.dart';
import 'package:pfb/features/shell/presentation/screens/main_shell_screen.dart';
import 'package:pfb/features/splash/presentation/screens/splash_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
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
      case RouteNames.home:
        return _route(const ProductListScreen());
      case RouteNames.admin:
        return _route(const AdminDashboardScreen());
      case RouteNames.cart:
        return _route(const CartScreen());
      case RouteNames.orders:
        return _route(OrderScreen());
      case RouteNames.profile:
        return _route(const ProfileScreen());
      case RouteNames.favorites:
        return _route(FavoritesScreen());
      case RouteNames.addProduct:
        return _route(const AddProductScreen());
      case RouteNames.adminOrders:
        return _route(AdminOrdersScreen());
      case RouteNames.mainShell:
        return _route(const MainShellScreen());
      case RouteNames.notifications:
        return _route(const NotificationsScreen());
      default:
        return _route(
          const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }

  static MaterialPageRoute _route(Widget child) {
    return MaterialPageRoute(builder: (_) => child);
  }

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
}
