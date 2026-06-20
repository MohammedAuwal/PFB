import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:pfb/core/constants/app_constants.dart';
import 'package:pfb/models/payment_config_model.dart';
import 'package:pfb/models/payment_session_model.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentResult {
  final bool success;
  final String reference;
  final String message;
  final String authorizationUrl;

  const PaymentResult({
    required this.success,
    required this.reference,
    required this.message,
    this.authorizationUrl = '',
  });
}

class PaymentService {
  PaymentService({http.Client? client}) : _client = client ?? http.Client();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final http.Client _client;

  DocumentReference<Map<String, dynamic>> get _settingsDoc =>
      _firestore.collection(AppConstants.appSettingsCollection).doc('general');

  Future<PaymentConfigModel> getPaymentConfig() async {
    final doc = await _settingsDoc.get();
    final data = doc.data() ?? {};

    return PaymentConfigModel.fromMap({
      'paystackEnabled': data['paystackEnabled'] ?? true,
      'activeGateway': data['activeGateway'] ?? 'paystack',
      'rideBaseFare': data['rideBaseFare'] ?? AppConstants.rideBaseFare,
      'ridePricePerKm': data['ridePricePerKm'] ?? AppConstants.ridePricePerKm,
      'deliveryBaseFare':
          data['deliveryBaseFare'] ?? AppConstants.deliveryBaseFare,
      'deliveryPricePerKm':
          data['deliveryPricePerKm'] ?? AppConstants.deliveryPricePerKm,
      'paystackPublicKey':
          data['paystackPublicKey'] ?? AppConstants.paystackPublicKey,
      'enabledGateways': data['enabledGateways'] ?? const ['paystack'],
    });
  }

  Stream<PaymentConfigModel> watchPaymentConfig() {
    return _settingsDoc.snapshots().map(
      (doc) => PaymentConfigModel.fromMap({
        'paystackEnabled': doc.data()?['paystackEnabled'] ?? true,
        'activeGateway': doc.data()?['activeGateway'] ?? 'paystack',
        'rideBaseFare':
            doc.data()?['rideBaseFare'] ?? AppConstants.rideBaseFare,
        'ridePricePerKm':
            doc.data()?['ridePricePerKm'] ?? AppConstants.ridePricePerKm,
        'deliveryBaseFare':
            doc.data()?['deliveryBaseFare'] ?? AppConstants.deliveryBaseFare,
        'deliveryPricePerKm': doc.data()?['deliveryPricePerKm'] ??
            AppConstants.deliveryPricePerKm,
        'paystackPublicKey':
            doc.data()?['paystackPublicKey'] ?? AppConstants.paystackPublicKey,
        'enabledGateways':
            doc.data()?['enabledGateways'] ?? const ['paystack'],
      }),
    );
  }

  Future<void> seedPaymentConfigIfMissing() async {
    final doc = await _settingsDoc.get();
    if (doc.exists) return;

    await _settingsDoc.set({
      'paystackEnabled': true,
      'activeGateway': 'paystack',
      'rideBaseFare': AppConstants.rideBaseFare,
      'ridePricePerKm': AppConstants.ridePricePerKm,
      'deliveryBaseFare': AppConstants.deliveryBaseFare,
      'deliveryPricePerKm': AppConstants.deliveryPricePerKm,
      'paystackPublicKey': AppConstants.paystackPublicKey,
      'enabledGateways': ['paystack'],
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> updatePaymentConfig({
    required bool paystackEnabled,
    required String activeGateway,
    required double rideBaseFare,
    required double ridePricePerKm,
    required double deliveryBaseFare,
    required double deliveryPricePerKm,
    required String paystackPublicKey,
    required List<String> enabledGateways,
  }) async {
    await _settingsDoc.set({
      'paystackEnabled': paystackEnabled,
      'activeGateway': activeGateway,
      'rideBaseFare': rideBaseFare,
      'ridePricePerKm': ridePricePerKm,
      'deliveryBaseFare': deliveryBaseFare,
      'deliveryPricePerKm': deliveryPricePerKm,
      'paystackPublicKey': paystackPublicKey.trim(),
      'enabledGateways': enabledGateways,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  String generateReference() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return 'MIX_${now}_$random';
  }

  Future<void> createPaymentAttempt({
    required String reference,
    required String userUid,
    required String email,
    required double amountNaira,
    required String currency,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> metadata,
  }) async {
    await _firestore
        .collection(AppConstants.paymentAttemptsCollection)
        .doc(reference)
        .set({
      'attemptId': reference,
      'provider': 'paystack',
      'currency': currency,
      'amount': amountNaira,
      'amountStr': amountNaira.toStringAsFixed(2),
      'userId': userUid,
      'email': email,
      'status': 'initiated',
      'createdAtMs': DateTime.now().millisecondsSinceEpoch,
      'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      'items': items,
      'metadata': metadata,
    }, SetOptions(merge: true));
  }

  Future<void> markPaymentAttemptInitialized({
    required String reference,
    required String authorizationUrl,
  }) async {
    await _firestore
        .collection(AppConstants.paymentAttemptsCollection)
        .doc(reference)
        .set({
      'status': 'initialized',
      'authorizationUrl': authorizationUrl,
      'txRef': reference,
      'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  Future<void> markPaymentAttemptSuccess({
    required String reference,
    String? gatewayReference,
    String? gatewayMessage,
  }) async {
    await _firestore
        .collection(AppConstants.paymentAttemptsCollection)
        .doc(reference)
        .set({
      'status': 'client_success',
      'providerTransactionId': gatewayReference ?? reference,
      'txRef': reference,
      'gatewayMessage': gatewayMessage ?? 'Payment successful',
      'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  Future<void> markPaymentAttemptFailure({
    required String reference,
    String? errorMessage,
  }) async {
    await _firestore
        .collection(AppConstants.paymentAttemptsCollection)
        .doc(reference)
        .set({
      'status': 'client_failed',
      'errorMessage': errorMessage ?? 'Payment was not completed',
      'txRef': reference,
      'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  Future<void> createVerifiedPaymentRecord({
    required String paymentId,
    required String attemptId,
    required String userUid,
    required String email,
    required double amountNaira,
    required String currency,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> metadata,
    String? providerTransactionId,
    String? gatewayMessage,
  }) async {
    await _firestore
        .collection(AppConstants.paymentsCollection)
        .doc(paymentId)
        .set({
      'paymentId': paymentId,
      'attemptId': attemptId,
      'status': 'success',
      'provider': 'paystack',
      'providerTransactionId': providerTransactionId ?? paymentId,
      'txRef': attemptId,
      'receiptId': paymentId,
      'userId': userUid,
      'email': email,
      'currency': currency,
      'amount': amountNaira,
      'amountStr': amountNaira.toStringAsFixed(2),
      'items': items,
      'paidAtMs': DateTime.now().millisecondsSinceEpoch,
      'createdAtMs': DateTime.now().millisecondsSinceEpoch,
      'verification': {
        'source': 'manual_return_verification',
        'verified': true,
        'gatewayMessage': gatewayMessage ?? 'Payment successful',
      },
      'metadata': metadata,
    }, SetOptions(merge: true));
  }

  Future<PaymentResult> initializeCheckout({
    required String userUid,
    required String email,
    required double amountNaira,
    required List<Map<String, dynamic>> items,
    String? reference,
    String currency = 'NGN',
    Map<String, dynamic>? metadata,
  }) async {
    final config = await getPaymentConfig();

    if (!config.paystackEnabled) {
      return const PaymentResult(
        success: false,
        reference: '',
        message: 'Paystack is currently disabled by admin',
      );
    }

    if (config.activeGateway != 'paystack') {
      return PaymentResult(
        success: false,
        reference: '',
        message:
            'Current payment gateway is ${config.activeGateway}, not Paystack',
      );
    }

    final paymentReference = reference ?? generateReference();
    final paymentMetadata = metadata ?? {};

    await createPaymentAttempt(
      reference: paymentReference,
      userUid: userUid,
      email: email,
      amountNaira: amountNaira,
      currency: currency,
      items: items,
      metadata: paymentMetadata,
    );

    final response = await _client.post(
      Uri.parse(AppConstants.supabasePaystackInitializeFunctionUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppConstants.supabaseFunctionSecret}',
      },
      body: jsonEncode({
        'email': email,
        'amountNaira': amountNaira,
        'reference': paymentReference,
        'currency': currency,
        'metadata': paymentMetadata,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      await markPaymentAttemptFailure(
        reference: paymentReference,
        errorMessage: response.body,
      );

      return PaymentResult(
        success: false,
        reference: paymentReference,
        message: 'Unable to initialize payment',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final success = decoded['success'] == true;
    final data = Map<String, dynamic>.from(decoded['data'] ?? {});
    final authUrl = (data['authorization_url'] ?? '').toString();
    final gatewayReference = (data['reference'] ?? paymentReference).toString();

    if (!success || authUrl.trim().isEmpty) {
      await markPaymentAttemptFailure(
        reference: paymentReference,
        errorMessage:
            decoded['error']?.toString() ?? 'Payment initialization failed',
      );

      return PaymentResult(
        success: false,
        reference: paymentReference,
        message: decoded['error']?.toString() ??
            'Payment initialization failed',
      );
    }

    await markPaymentAttemptInitialized(
      reference: paymentReference,
      authorizationUrl: authUrl,
    );

    return PaymentResult(
      success: true,
      reference: gatewayReference,
      message: decoded['message']?.toString() ?? 'Payment initialized',
      authorizationUrl: authUrl,
    );
  }

  Future<bool> openCheckoutUrl(String url) async {
    if (url.trim().isEmpty) return false;

    final uri = Uri.parse(url);
    return await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  Future<Map<String, dynamic>?> getPaymentAttempt(String reference) async {
    final doc = await _firestore
        .collection(AppConstants.paymentAttemptsCollection)
        .doc(reference)
        .get();
    return doc.data();
  }

  Future<bool> confirmManualPaymentSuccess(PaymentSessionModel session) async {
    await markPaymentAttemptSuccess(
      reference: session.reference,
      gatewayReference: session.reference,
      gatewayMessage: 'Manually confirmed after Paystack return',
    );

    await createVerifiedPaymentRecord(
      paymentId: session.reference,
      attemptId: session.reference,
      userUid: session.userUid,
      email: session.email,
      amountNaira: session.amountNaira,
      currency: session.currency,
      items: session.items,
      metadata: session.metadata,
      providerTransactionId: session.reference,
      gatewayMessage: 'Manually confirmed after Paystack return',
    );

    return true;
  }
}
