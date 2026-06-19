import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final String targetScreen;
  final String targetId;
  final bool isRead;
  final DateTime createdAt;
  final String source;
  final String recipientCollection;

  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.targetScreen,
    required this.targetId,
    required this.isRead,
    required this.createdAt,
    required this.source,
    required this.recipientCollection,
  });

  factory AppNotificationModel.fromMap(
    String id,
    Map<String, dynamic> map, {
    required String recipientCollection,
  }) {
    final rawCreatedAt = map['createdAt'];

    DateTime createdAt;
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else {
      createdAt = DateTime.tryParse((rawCreatedAt ?? '').toString()) ??
          DateTime.now();
    }

    return AppNotificationModel(
      id: id,
      title: (map['title'] ?? '').toString(),
      body: (map['body'] ?? '').toString(),
      type: (map['type'] ?? '').toString(),
      targetScreen: (map['targetScreen'] ?? '').toString(),
      targetId: (map['targetId'] ?? '').toString(),
      isRead: (map['isRead'] ?? false) == true,
      createdAt: createdAt,
      source: (map['source'] ?? 'system').toString(),
      recipientCollection: recipientCollection,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationId': id,
      'notificationCollection': recipientCollection,
      'title': title,
      'body': body,
      'type': type,
      'targetScreen': targetScreen,
      'targetId': targetId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'source': source,
    };
  }

  /// Returns a human-friendly date group label.
  String get dateGroup {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notifDay = DateTime(createdAt.year, createdAt.month, createdAt.day);

    if (notifDay == today) return 'Today';
    if (notifDay == yesterday) return 'Yesterday';
    if (now.difference(createdAt).inDays < 7) return 'This Week';
    return 'Earlier';
  }
}
