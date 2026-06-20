import 'package:flutter/material.dart';
import 'package:pfb/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:pfb/features/admin/presentation/screens/admin_escalation_dashboard_screen.dart';
import 'package:pfb/features/admin/presentation/screens/admin_orders_screen.dart';
import 'package:pfb/features/admin/presentation/screens/admin_rides_screen.dart';
import 'package:pfb/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:pfb/features/orders/presentation/screens/order_screen.dart';
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
      final targetId = (data['targetId'] ?? '').toString().trim();

      // ── Escalations ───────────────────────────────────────────
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

      // ── Admin Orders ──────────────────────────────────────────
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

      // ── Admin Deliveries (legacy admin_rides targetScreen) ────
      if (targetScreen == 'admin_rides' ||
          type.contains('admin_assignment_delivery')) {
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => AdminRidesScreen(),
            settings: RouteSettings(
              name: 'admin_deliveries',
              arguments: targetId,
            ),
          ),
        );
        return;
      }

      // ── Deep link: Order detail ───────────────────────────────
      if ((targetScreen == 'order_detail' ||
              type.contains('order_status_update') ||
              type.contains('order_created')) &&
          targetId.isNotEmpty) {
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

        await navigator.push(
          MaterialPageRoute(
            builder: (_) => OrderScreen(),
            settings: RouteSettings(name: 'orders', arguments: targetId),
          ),
        );
        return;
      }

      // ── Legacy ride/delivery notification types → Orders ─────
      // Since rides were removed, treat ride/delivery payloads as order payloads.
      if ((targetScreen == 'ride_detail' ||
              type.contains('ride') ||
              type.contains('delivery')) &&
          targetId.isNotEmpty) {
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

        await navigator.push(
          MaterialPageRoute(
            builder: (_) => OrderScreen(),
            settings: RouteSettings(name: 'orders', arguments: targetId),
          ),
        );
        return;
      }

      // ── Orders list ───────────────────────────────────────────
      if (type.contains('order') || targetScreen == 'orders') {
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => OrderScreen(),
            settings: RouteSettings(name: 'orders', arguments: targetId),
          ),
        );
        return;
      }

      // ── Admin dashboard ───────────────────────────────────────
      if (type.contains('admin_assignment') ||
          targetScreen == 'admin_dashboard') {
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => const AdminDashboardScreen(),
            settings: RouteSettings(name: 'admin_dashboard', arguments: targetId),
          ),
        );
        return;
      }

      // ── Fallback ──────────────────────────────────────────────
      await navigator.push(
        MaterialPageRoute(
          builder: (_) => const MainShellScreen(),
          settings: RouteSettings(name: 'main_shell', arguments: targetId),
        ),
      );
    } finally {
      _isNavigating = false;
    }
  }
}
