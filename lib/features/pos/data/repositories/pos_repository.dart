// lib/features/pos/data/repositories/pos_repository.dart
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pfb/core/constants/app_constants.dart';
import 'package:pfb/features/pos/data/models/pos_cart_item_model.dart';
import 'package:pfb/features/pos/data/models/pos_sale_model.dart';
import 'package:pfb/features/pos/data/models/receipt_model.dart';
import 'package:pfb/models/product_model.dart';
import 'package:pfb/services/firebase_service.dart';

class PosRepository {
  final FirebaseService _firebaseService;
  final FirebaseFirestore _firestore;

  PosRepository({FirebaseService? firebaseService})
      : _firebaseService =
            firebaseService ?? FirebaseService(),
        _firestore = FirebaseFirestore.instance;

  // ── Receipt ID Generation ─────────────────────────────────────────────────

  String generateReceiptId() {
    final now = DateTime.now();
    final rand =
        Random().nextInt(9999).toString().padLeft(4, '0');
    final date =
        '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    return 'PFB-$date-$rand';
  }

  // ── Product Search ────────────────────────────────────────────────────────

  /// Reuses FirebaseService.watchAllProducts() — no duplication
  Stream<List<ProductModel>> watchAllProducts() {
    return _firebaseService.watchAllProducts();
  }

  /// Client-side search: name, category, fabricType (SKU future-ready)
  List<ProductModel> searchProducts(
    List<ProductModel> allProducts,
    String query,
  ) {
    if (query.trim().isEmpty) return allProducts;
    final lower = query.trim().toLowerCase();
    return allProducts.where((p) {
      return p.name.toLowerCase().contains(lower) ||
          p.category.toLowerCase().contains(lower) ||
          (p.fabricType?.toLowerCase().contains(lower) ??
              false);
    }).toList();
  }

  // ── Cart Calculations ─────────────────────────────────────────────────────

  double calculateSubtotal(List<PosCartItemModel> items) {
    return items.fold(
        0.0, (sum, item) => sum + item.lineTotal);
  }

  double calculateDiscount({
    required double subtotal,
    required double discountValue,
    required PosDiscountType discountType,
  }) {
    if (discountType == PosDiscountType.none ||
        discountValue <= 0) return 0.0;
    if (discountType == PosDiscountType.percentage) {
      return (discountValue / 100) * subtotal;
    }
    // Fixed — clamp so discount cannot exceed subtotal
    return discountValue.clamp(0, subtotal).toDouble();
  }

  double calculateFinalTotal({
    required double subtotal,
    required double discountAmount,
  }) {
    return (subtotal - discountAmount)
        .clamp(0, double.infinity)
        .toDouble();
  }

  double calculateChange({
    required double amountTendered,
    required double finalTotal,
  }) {
    return (amountTendered - finalTotal)
        .clamp(0, double.infinity)
        .toDouble();
  }

  // ── Checkout / Sale Persistence ───────────────────────────────────────────

  Future<PosSaleModel> completeSale({
    required List<PosCartItemModel> cartItems,
    required String cashierUid,
    required String cashierName,
    required String cashierEmail,
    String customerName = '',
    String customerPhone = '',
    double discountValue = 0,
    PosDiscountType discountType = PosDiscountType.none,
    String discountReason = '',
    required PosPaymentMethod paymentMethod,
    PosMixedPayment? mixedPayment,
    double amountTendered = 0,
    String branchId = AppConstants.defaultBranchId,
    String branchName = AppConstants.defaultBranchName,
  }) async {
    if (cartItems.isEmpty) throw Exception('Cart is empty');

    final subtotal = calculateSubtotal(cartItems);
    final discountAmount = calculateDiscount(
      subtotal: subtotal,
      discountValue: discountValue,
      discountType: discountType,
    );
    final finalTotal = calculateFinalTotal(
      subtotal: subtotal,
      discountAmount: discountAmount,
    );
    final changeGiven = calculateChange(
      amountTendered: amountTendered,
      finalTotal: finalTotal,
    );

    final receiptId = generateReceiptId();
    final saleRef = _firestore
        .collection(AppConstants.posSalesCollection)
        .doc();
    final now = DateTime.now();

    final sale = PosSaleModel(
      id: saleRef.id,
      receiptId: receiptId,
      branchId: branchId,
      branchName: branchName,
      cashierUid: cashierUid,
      cashierName: cashierName,
      cashierEmail: cashierEmail,
      customerName: customerName,
      customerPhone: customerPhone,
      items: cartItems.map((e) => e.toMap()).toList(),
      subtotal: subtotal,
      discountValue: discountValue,
      discountType: discountType,
      discountReason: discountReason,
      finalTotal: finalTotal,
      paymentMethod: paymentMethod,
      mixedPayment: mixedPayment,
      amountTendered: amountTendered,
      changeGiven: changeGiven,
      saleChannel: 'physical_shop',
      createdAt: now,
      status: 'completed',
    );

    // ── Atomic batch write ────────────────────────────────────────────────
    final batch = _firestore.batch();

    // 1. Save sale document
    batch.set(saleRef, sale.toMap());

    // 2. Save receipt document — keyed by receiptId
    final receiptRef = _firestore
        .collection(AppConstants.posReceiptsCollection)
        .doc(receiptId);
    batch.set(receiptRef, ReceiptModel.fromSale(sale).toMap());

    // 3. Reduce stockQuantity for each product in the cart
    //    stockQuantity is Int in ProductModel — uses FieldValue.increment
    for (final item in cartItems) {
      final productRef = _firestore
          .collection(AppConstants.productsCollection)
          .doc(item.productId);
      batch.update(productRef, {
        // ── Matches ProductModel field name ──────────────────────────────
        'stockQuantity':
            FieldValue.increment(-item.quantity),
        'updatedAt': now.toIso8601String(),
      });
    }

    // 4. Update / create daily analytics aggregate
    final dateKey = _dateKey(now);
    final analyticsRef = _firestore
        .collection(AppConstants.posAnalyticsCollection)
        .doc('physical_shop')
        .collection('daily')
        .doc(dateKey);

    batch.set(
      analyticsRef,
      {
        'date': dateKey,
        'channel': 'physical_shop',
        'branchId': branchId,
        'branchName': branchName,
        'totalRevenue': FieldValue.increment(finalTotal),
        'totalTransactions': FieldValue.increment(1),
        'totalDiscounts':
            FieldValue.increment(discountAmount),
        'updatedAt': now.toIso8601String(),
      },
      SetOptions(merge: true),
    );

    // 5. Update cashier performance document
    final perfRef = _firestore
        .collection(AppConstants.adminPerformanceCollection)
        .doc(cashierUid);

    final totalItemsSold = cartItems.fold<int>(
      0,
      (sum, i) => sum + i.quantity,
    );
    final discountApplied =
        discountType != PosDiscountType.none ? 1 : 0;

    batch.set(
      perfRef,
      {
        'uid': cashierUid,
        'name': cashierName,
        'email': cashierEmail,
        'totalRevenue':
            FieldValue.increment(finalTotal),
        'totalTransactions': FieldValue.increment(1),
        'totalDiscountsApplied':
            FieldValue.increment(discountApplied),
        'totalProductsSold':
            FieldValue.increment(totalItemsSold),
        'updatedAt': now.toIso8601String(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();

    return sale;
  }

  // ── Sale Streams ──────────────────────────────────────────────────────────

  /// All POS sales — used by Super Admin Analytics
  Stream<List<PosSaleModel>> watchAllPosSales() {
    return _firestore
        .collection(AppConstants.posSalesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((doc) =>
                PosSaleModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Sales by branch — future multi-branch support
  Stream<List<PosSaleModel>> watchSalesByBranch(
      String branchId) {
    return _firestore
        .collection(AppConstants.posSalesCollection)
        .where('branchId', isEqualTo: branchId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((doc) =>
                PosSaleModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Sales by cashier — used for cashier performance view
  Stream<List<PosSaleModel>> watchSalesByCashier(
      String cashierUid) {
    return _firestore
        .collection(AppConstants.posSalesCollection)
        .where('cashierUid', isEqualTo: cashierUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((doc) =>
                PosSaleModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Today's sales — for dashboard quick view
  Stream<List<PosSaleModel>> watchTodaysSales() {
    final today = _dateKey(DateTime.now());
    return _firestore
        .collection(AppConstants.posSalesCollection)
        .where('createdAtDate', isEqualTo: today)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((doc) =>
                PosSaleModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // ── Revenue Summary ───────────────────────────────────────────────────────

  /// Used by PosAnalyticsBridge to feed Super Admin Analytics
  Future<Map<String, dynamic>> getRevenueSummary({
    required DateTime from,
    required DateTime to,
  }) async {
    final snapshot = await _firestore
        .collection(AppConstants.posSalesCollection)
        .where('createdAt',
            isGreaterThanOrEqualTo: from.toIso8601String())
        .where('createdAt',
            isLessThanOrEqualTo: to.toIso8601String())
        .where('status', isEqualTo: 'completed')
        .get();

    final sales = snapshot.docs
        .map((doc) =>
            PosSaleModel.fromMap(doc.id, doc.data()))
        .toList();

    double physicalTotal = 0;
    int transactionCount = 0;
    double totalDiscounts = 0;
    final Map<String, double> revenueByCategory = {};
    final Map<String, double> revenueByBranch = {};
    final Map<String, int> productSoldCount = {};

    for (final sale in sales) {
      physicalTotal += sale.finalTotal;
      transactionCount++;
      totalDiscounts += calculateDiscount(
        subtotal: sale.subtotal,
        discountValue: sale.discountValue,
        discountType: sale.discountType,
      );

      revenueByBranch[sale.branchName] =
          (revenueByBranch[sale.branchName] ?? 0) +
              sale.finalTotal;

      for (final item in sale.items) {
        final category =
            (item['category'] ?? 'Other').toString();
        final lineTotal =
            (item['lineTotal'] as num?)?.toDouble() ?? 0;
        final productName =
            (item['productName'] ?? '').toString();
        final qty =
            (item['quantity'] as num?)?.toInt() ?? 1;

        revenueByCategory[category] =
            (revenueByCategory[category] ?? 0) +
                lineTotal;
        productSoldCount[productName] =
            (productSoldCount[productName] ?? 0) + qty;
      }
    }

    final sortedProducts =
        productSoldCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final topProducts =
        sortedProducts.take(5).toList();

    return {
      'physicalShopRevenue': physicalTotal,
      'transactionCount': transactionCount,
      'totalDiscounts': totalDiscounts,
      'revenueByCategory': revenueByCategory,
      'revenueByBranch': revenueByBranch,
      'topProducts': topProducts
          .map((e) => {
                'name': e.key,
                'unitsSold': e.value,
              })
          .toList(),
      'averageTransactionValue': transactionCount > 0
          ? physicalTotal / transactionCount
          : 0,
    };
  }

  // ── Receipt Fetch ─────────────────────────────────────────────────────────

  Future<ReceiptModel?> getReceiptById(
      String receiptId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.posReceiptsCollection)
          .doc(receiptId)
          .get();
      if (!doc.exists) return null;
      return ReceiptModel.fromMap(doc.data()!);
    } catch (_) {
      return null;
    }
  }

  Stream<List<ReceiptModel>> watchRecentReceipts(
      {int limit = 20}) {
    return _firestore
        .collection(AppConstants.posReceiptsCollection)
        .orderBy('issuedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs
            .map((doc) =>
                ReceiptModel.fromMap(doc.data()))
            .toList());
  }

  // ── Admin Performance ─────────────────────────────────────────────────────

  Stream<Map<String, dynamic>?> watchAdminPerformance(
      String adminUid) {
    return _firestore
        .collection(
            AppConstants.adminPerformanceCollection)
        .doc(adminUid)
        .snapshots()
        .map((doc) => doc.data());
  }

  Stream<List<Map<String, dynamic>>>
      watchAllAdminPerformance() {
    return _firestore
        .collection(
            AppConstants.adminPerformanceCollection)
        .orderBy('totalRevenue', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((doc) => doc.data()).toList());
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}