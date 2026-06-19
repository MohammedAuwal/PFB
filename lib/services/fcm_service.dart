import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:pfb/core/constants/app_constants.dart';
import 'package:pfb/services/local_notification_service.dart';
import 'package:pfb/services/notification_navigation_service.dart';

class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _initialized = false;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      ).timeout(const Duration(seconds: 8));
    } catch (_) {}

    try {
      await syncTokenForCurrentUser().timeout(const Duration(seconds: 8));
    } catch (_) {}

    try {
      _listenTokenRefresh();
    } catch (_) {}

    try {
      _listenForegroundMessages();
    } catch (_) {}

    try {
      _listenNotificationTapEvents();
    } catch (_) {}

    try {
      await _handleInitialMessage().timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    final title =
        message.notification?.title ?? (message.data['title'] ?? 'Mix');
    final body = message.notification?.body ??
        (message.data['body'] ?? 'You have a new update');

    final shouldShowLocal = _shouldShowLocalNotification(message);

    if (!shouldShowLocal) return;

    try {
      await LocalNotificationService.instance.show(
        title: title.toString(),
        body: body.toString(),
        payload: _encodePayload(message.data),
      );
    } catch (_) {}
  }

  Future<void> syncTokenForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken().timeout(const Duration(seconds: 8));
    if (token == null || token.trim().isEmpty) return;

    await _saveTokenForUser(user.uid, token.trim()).timeout(
      const Duration(seconds: 8),
    );
  }

  Future<void> removeCurrentDeviceTokenForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken().timeout(const Duration(seconds: 8));
    if (token == null || token.trim().isEmpty) return;

    await _removeTokenForUser(user.uid, token.trim()).timeout(
      const Duration(seconds: 8),
    );
  }

  void _listenTokenRefresh() {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) async {
      final user = _auth.currentUser;
      if (user == null) return;
      await _saveTokenForUser(user.uid, token.trim());
    });
  }

  void _listenForegroundMessages() {
    _foregroundSubscription?.cancel();
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) async {
      final title =
          message.notification?.title ?? (message.data['title'] ?? 'Mix');
      final body = message.notification?.body ??
          (message.data['body'] ?? 'You have a new update');

      try {
        await LocalNotificationService.instance.show(
          title: title.toString(),
          body: body.toString(),
          payload: _encodePayload(message.data),
        );
      } catch (_) {}
    });
  }

  void _listenNotificationTapEvents() {
    _messageOpenedSubscription?.cancel();
    _messageOpenedSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      try {
        await NotificationNavigationService.instance.handlePayload(message.data);
      } catch (_) {}
    });
  }

  Future<void> _handleInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage == null) return;

    await NotificationNavigationService.instance
        .handlePayload(initialMessage.data);
  }

  Future<void> _saveTokenForUser(String uid, String token) async {
    final now = DateTime.now().toIso8601String();

    final userRef = _firestore.collection(AppConstants.usersCollection).doc(uid);
    final userSnap = await userRef.get();
    final userData = userSnap.data() ?? {};
    final userTokens = List<String>.from(userData['fcmTokens'] ?? []);

    if (!userTokens.contains(token)) {
      userTokens.add(token);
    }

    await userRef.set({
      'fcmTokens': userTokens,
      'lastTokenUpdatedAt': now,
    }, SetOptions(merge: true));

    final adminRef =
        _firestore.collection(AppConstants.adminsCollection).doc(uid);
    final adminSnap = await adminRef.get();

    if (adminSnap.exists) {
      final adminData = adminSnap.data() ?? {};
      final adminTokens = List<String>.from(adminData['fcmTokens'] ?? []);

      if (!adminTokens.contains(token)) {
        adminTokens.add(token);
      }

      await adminRef.set({
        'fcmTokens': adminTokens,
        'lastTokenUpdatedAt': now,
      }, SetOptions(merge: true));
    }
  }

  Future<void> _removeTokenForUser(String uid, String token) async {
    final now = DateTime.now().toIso8601String();

    final userRef = _firestore.collection(AppConstants.usersCollection).doc(uid);
    final userSnap = await userRef.get();
    if (userSnap.exists) {
      final userData = userSnap.data() ?? {};
      final userTokens = List<String>.from(userData['fcmTokens'] ?? [])
        ..removeWhere((t) => t == token);

      await userRef.set({
        'fcmTokens': userTokens,
        'lastTokenUpdatedAt': now,
      }, SetOptions(merge: true));
    }

    final adminRef =
        _firestore.collection(AppConstants.adminsCollection).doc(uid);
    final adminSnap = await adminRef.get();
    if (adminSnap.exists) {
      final adminData = adminSnap.data() ?? {};
      final adminTokens = List<String>.from(adminData['fcmTokens'] ?? [])
        ..removeWhere((t) => t == token);

      await adminRef.set({
        'fcmTokens': adminTokens,
        'lastTokenUpdatedAt': now,
      }, SetOptions(merge: true));
    }
  }

  bool _shouldShowLocalNotification(RemoteMessage message) {
    if (message.notification != null) {
      return true;
    }

    final data = message.data;
    return data.containsKey('title') || data.containsKey('body');
  }

  String _encodePayload(Map<String, dynamic> data) {
    return jsonEncode(
      data.map((key, value) => MapEntry(key, value?.toString() ?? '')),
    );
  }
}
