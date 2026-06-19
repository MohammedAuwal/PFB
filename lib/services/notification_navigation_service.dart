import 'package:flutter/material.dart';
import 'package:pfb/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:pfb/features/admin/presentation/screens/admin_escalation_dashboard_screen.dart';
import 'package:pfb/features/admin/presentation/screens/admin_orders_screen.dart';
import 'package:pfb/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:pfb/features/orders/presentation/screens/order_screen.dart';
import 'package:pfb/features/rider/presentation/screens/rider_home_screen.dart';
import 'package:pfb/features/shell/presentation/screens/main_shell_screen.dart';
import 'package:pfb/services/firebase_service.dart';

class NotificationNavigationService {
  NotificationNavigationService._();

  static final NotificationNavigationService instance =
      NotificationNavigationService._();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final FirebaseService _firebaseService = FirebaseService();

  bool _isNavigating = false;

  Future<void> handlePayload(Map<String, dynamic> data) async {
    final notificationId = (data['notificationId'] ?? '').toString().trim();
    final notificationCollection =
        (data['notificationCollection'] ?? '').toString().trim();

    if (notificationId.isNotEmpty) {
      try {
        await _firebaseService.markNotificationAsRead(
          notificationId,
          recipientCollection:
              notificationCollection.isEmpty ? null : notificationCollection,
        );
      } catch (_) {}
    }

    final navigator = navigatorKey.currentState;
    if (navigator == null || _isNavigating) return;

    _isNavigating = true;

    try {
      final type = (data['type'] ?? '').toString().toLowerCase();
      final targetScreen =
          (data['targetScreen'] ?? '').toString().toLowerCase();
      final targetId = (data['targetId'] ?? '').toString();

      if (targetScreen == 'admin_escalation_dashboard' ||
          type.contains('escalation')) {
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => AdminEscalationDashboardScreen(),
            settings: RouteSettings(
              name: 'admin_escalation_dashboard',
              arguments: targetId,
            ),
          ),
        );
        return;
      }

      if (targetScreen == 'admin_orders' ||
          type.contains('admin_assignment_order')) {
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => AdminOrdersScreen(),
            settings: RouteSettings(
              name: 'admin_orders',
              arguments: targetId,
            ),
          ),
        );
        return;
      }

      // Deep link: order_detail with specific orderId
      if (targetScreen == 'order_detail' && targetId.isNotEmpty) {
        try {
          final order = await _firebaseService.getOrderById(targetId);
          if (order != null) {
            await navigator.push(
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(order: order),
                settings: RouteSettings(
                  name: 'order_detail',
                  arguments: targetId,
                ),
              ),
            );
            return;
          }
        } catch (_) {}
        // Fallback to orders list
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => OrderScreen(),
            settings: RouteSettings(
              name: 'orders',
              arguments: targetId,
            ),
          ),
        );
        return;
      }

      // Deep link: ride_detail with specific rideId
      if ((targetScreen == 'ride_detail' || type.contains('ride') || type.contains('delivery')) &&
          targetId.isNotEmpty) {
        try {
          final ride = await _firebaseService.getRideById(targetId);
          if (ride != null) {
            // Navigate to rider home which shows ride details
            await navigator.push(
              MaterialPageRoute(
                builder: (_) => const RiderHomeScreen(),
                settings: RouteSettings(
                  name: 'rider_home',
                  arguments: targetId,
                ),
              ),
            );
            return;
          }
        } catch (_) {}
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => const RiderHomeScreen(),
            settings: RouteSettings(
              name: 'rider_home',
              arguments: targetId,
            ),
          ),
        );
        return;
      }

      if (targetScreen == 'admin_rides') {
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => const RiderHomeScreen(),
            settings: RouteSettings(
              name: 'rider_home',
              arguments: targetId,
            ),
          ),
        );
        return;
      }

      if (type.contains('order') || targetScreen == 'orders') {
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => OrderScreen(),
            settings: RouteSettings(
              name: 'orders',
              arguments: targetId,
            ),
          ),
        );
        return;
      }

      if (type.contains('admin_assignment') ||
          targetScreen == 'admin_dashboard') {
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => const AdminDashboardScreen(),
            settings: RouteSettings(
              name: 'admin_dashboard',
              arguments: targetId,
            ),
          ),
        );
        return;
      }

      await navigator.push(
        MaterialPageRoute(
          builder: (_) => const MainShellScreen(),
          settings: RouteSettings(
            name: 'main_shell',
            arguments: targetId,
          ),
        ),
      );
    } catch (_) {
    } finally {
      _isNavigating = false;
    }
  }
}
