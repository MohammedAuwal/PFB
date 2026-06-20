import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pfb/core/constants/app_constants.dart';

class SupabaseNotificationService {
  final http.Client _client;

  SupabaseNotificationService({http.Client? client})
      : _client = client ?? http.Client();

  Future<void> sendPush({
    required List<String> tokens,
    required String title,
    required String body,
    required String type,
    String? targetScreen,
    String? targetId,
    String? notificationId,
    String? notificationCollection,
  }) async {
    final cleanedTokens = tokens
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    if (cleanedTokens.isEmpty) return;

    final url = AppConstants.supabaseFcmFunctionUrl;
    final secret = AppConstants.supabaseFunctionSecret;

    if (url.isEmpty ||
        secret.isEmpty ||
        secret == 'REPLACE_WITH_EDGE_FUNCTION_SECRET') {
      return;
    }

    final response = await _client.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $secret',
      },
      body: jsonEncode({
        'tokens': cleanedTokens,
        'title': title,
        'body': body,
        'type': type,
        'targetScreen': targetScreen ?? '',
        'targetId': targetId ?? '',
        'notificationId': notificationId ?? '',
        'notificationCollection': notificationCollection ?? '',
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to send push notification: ${response.body}');
    }
  }
}
