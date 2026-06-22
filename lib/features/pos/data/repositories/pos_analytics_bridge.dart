// lib/features/pos/data/repositories/pos_analytics_bridge.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pfb/core/constants/app_constants.dart';
import 'package:pfb/features/pos/data/repositories/pos_repository.dart';

/// Bridges POS physical shop data into the existing
/// Super Admin Analytics system.
///
/// Call methods from SuperAdminAnalyticsScreen
/// to get combined online + physical data.
class PosAnalyticsBridge {
  final PosRepository _repo;
  final FirebaseFirestore _firestore;

  PosAnalyticsBridge({PosRepository? repo})
      : _repo = repo ?? PosRepository(),
        _firestore = FirebaseFirestore.instance;

  // ── Combined Revenue ──────────────────────────────────────────────────────

  /// Returns online revenue, physical revenue, and combined total
  /// for the given date range.
  Future<Map<String, double>> getCombinedRevenue({
    required DateTime from,
    required DateTime to,
  }) async {
    // Physical shop revenue from POS
    final posData = await _repo.getRevenueSummary(
        from: from, to: to);
    final physicalRevenue =
        (posData['physicalShopRevenue'] as num?)
                ?.toDouble() ??
            0;

    // Online revenue from existing orders collection
    final ordersSnapshot = await _firestore
        .collection(AppConstants.ordersCollection)
        .where('createdAt',
            isGreaterThanOrEqualTo:
                from.toIso8601String())
        .where('createdAt',
            isLessThanOrEqualTo: to.toIso8601String())
        .where('paymentStatus', isEqualTo: 'paid')
        .get();

    double onlineRevenue = 0;
    for (final doc in ordersSnapshot.docs) {
      onlineRevenue +=
          ((doc.data()['totalAmount'] as num?)
                  ?.toDouble() ??
              0);
    }

    return {
      'physicalShop': physicalRevenue,
      'online': onlineRevenue,
      'total': physicalRevenue + onlineRevenue,
    };
  }

  // ── Daily Breakdown ───────────────────────────────────────────────────────

  /// Daily POS analytics from the aggregates subcollection
  Future<List<Map<String, dynamic>>>
      getPosDailyData({
    required DateTime from,
    required DateTime to,
  }) async {
    final snapshot = await _firestore
        .collection(AppConstants.posAnalyticsCollection)
        .doc('physical_shop')
        .collection('daily')
        .where('date',
            isGreaterThanOrEqualTo: _dateKey(from))
        .where('date',
            isLessThanOrEqualTo: _dateKey(to))
        .orderBy('date')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'date': data['date'] ?? '',
        'revenue':
            (data['totalRevenue'] as num?)
                    ?.toDouble() ??
                0,
        'transactions':
            (data['totalTransactions'] as num?)
                    ?.toInt() ??
                0,
        'discounts':
            (data['totalDiscounts'] as num?)
                    ?.toDouble() ??
                0,
      };
    }).toList();
  }

  // ── Admin Performance Leaderboard ─────────────────────────────────────────

  Stream<List<Map<String, dynamic>>>
      watchAdminPerformanceLeaderboard() {
    return _repo.watchAllAdminPerformance();
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}