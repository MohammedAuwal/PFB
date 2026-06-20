import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pfb/config/routes/route_names.dart';
import 'package:pfb/core/constants/app_constants.dart';
import 'package:pfb/core/routing/app_router.dart';
import 'package:pfb/features/shared/presentation/widgets/empty_state_card.dart';
import 'package:pfb/models/app_notification_model.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/services/notification_navigation_service.dart';
import 'package:pfb/shared/widgets/app_page_scaffold.dart';
import 'package:pfb/shared/widgets/app_section_title.dart';
import 'package:pfb/shared/widgets/app_status_chip.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();
    final isGuest = FirebaseAuth.instance.currentUser == null;
    final colors = context.appColors;

    return AppPageScaffold(
      title: 'Notifications',
      actions: [
        if (!isGuest)
          StreamBuilder<int>(
            stream: firebaseService.watchUnreadNotificationCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;

              return TextButton(
                onPressed: unreadCount == 0
                    ? null
                    : () async {
                        await firebaseService.markAllNotificationsAsRead();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All notifications marked as read'),
                          ),
                        );
                      },
                child: Text(
                  'Mark all',
                  style: GoogleFonts.poppins(
                    color: unreadCount == 0
                        ? colors.textSecondary.withOpacity(0.5)
                        : colors.brandPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
      ],
      body: isGuest
          ? _GuestNotificationsState(
              onSignIn: () async {
                await AppRouter.clearAndGo(context, RouteNames.login);
              },
            )
          : StreamBuilder<List<AppNotificationModel>>(
              stream: firebaseService.watchNotifications(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: EmptyStateCard(
                      icon: Icons.error_outline_rounded,
                      title: 'Unable to load notifications',
                      subtitle: snapshot.error.toString(),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final notifications = snapshot.data ?? const [];

                if (notifications.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: EmptyStateCard(
                      icon: Icons.notifications_none_rounded,
                      title: 'No notifications yet',
                      subtitle:
                          'Order, ride, delivery, and account updates will show here.',
                    ),
                  );
                }

                final grouped = <String, List<AppNotificationModel>>{};
                for (final n in notifications) {
                  grouped.putIfAbsent(n.dateGroup, () => []).add(n);
                }

                final groupOrder = ['Today', 'Yesterday', 'This Week', 'Earlier'];
                final sortedKeys = grouped.keys.toList()
                  ..sort((a, b) =>
                      groupOrder.indexOf(a).compareTo(groupOrder.indexOf(b)));

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, sectionIndex) {
                    final groupLabel = sortedKeys[sectionIndex];
                    final items = grouped[groupLabel]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (sectionIndex > 0) const SizedBox(height: 18),
                        AppSectionTitle(
                          title: groupLabel,
                          spacingBottom: 10,
                        ),
                        ...items.map((notification) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _DismissibleNotificationCard(
                              notification: notification,
                              firebaseService: firebaseService,
                              onTap: () async {
                                await firebaseService.markNotificationAsRead(
                                  notification.id,
                                  recipientCollection:
                                      notification.recipientCollection,
                                );

                                await NotificationNavigationService.instance
                                    .handlePayload(
                                  {
                                    'type': notification.type,
                                    'targetScreen': notification.targetScreen,
                                    'targetId': notification.targetId,
                                    'notificationId': notification.id,
                                    'notificationCollection':
                                        notification.recipientCollection,
                                  },
                                );
                              },
                            ),
                          );
                        }),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}

class _GuestNotificationsState extends StatelessWidget {
  final VoidCallback onSignIn;

  const _GuestNotificationsState({
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const EmptyStateCard(
            icon: Icons.notifications_off_outlined,
            title: 'Sign in to view notifications',
            subtitle:
                'Notification history is available for signed-in users only.',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onSignIn,
              child: Text(
                'Sign In',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DismissibleNotificationCard extends StatelessWidget {
  final AppNotificationModel notification;
  final FirebaseService firebaseService;
  final VoidCallback onTap;

  const _DismissibleNotificationCard({
    required this.notification,
    required this.firebaseService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Dismissible(
      key: ValueKey('${notification.recipientCollection}_${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colors.error,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) {
                final dialogColors = ctx.appColors;

                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(
                    'Delete notification?',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: dialogColors.textPrimary,
                    ),
                  ),
                  content: Text(
                    'This notification will be permanently deleted.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: dialogColors.textSecondary,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dialogColors.error,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        'Delete',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ) ??
            false;
      },
      onDismissed: (_) async {
        await firebaseService.deleteNotification(
          notification.id,
          recipientCollection: notification.recipientCollection,
        );
      },
      child: _NotificationCard(
        notification: notification,
        onTap: onTap,
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  IconData _iconForType(String type) {
    final value = type.toLowerCase();

    if (value.contains('order')) return Icons.receipt_long_rounded;
    if (value.contains('delivery')) return Icons.delivery_dining_rounded;
    if (value.contains('ride')) return Icons.local_taxi_rounded;
    if (value.contains('escalation')) return Icons.warning_amber_rounded;
    if (value.contains('admin')) return Icons.admin_panel_settings_rounded;
    return Icons.notifications_active_outlined;
  }

  AppStatusChipTone _toneForType(String type) {
    final value = type.toLowerCase();

    if (value.contains('order')) return AppStatusChipTone.info;
    if (value.contains('delivery')) return AppStatusChipTone.success;
    if (value.contains('ride')) return AppStatusChipTone.warning;
    if (value.contains('escalation')) return AppStatusChipTone.error;
    if (value.contains('admin')) return AppStatusChipTone.primary;
    return AppStatusChipTone.neutral;
  }

  Color _iconBgForType(BuildContext context, String type) {
    final colors = context.appColors;
    final value = type.toLowerCase();

    if (value.contains('order')) return colors.paleBlue;
    if (value.contains('delivery')) return colors.paleGreen;
    if (value.contains('ride')) return colors.paleOrange;
    if (value.contains('escalation')) return colors.paleRed;
    if (value.contains('admin')) return colors.palePurple;
    return colors.surfaceAlt;
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final unread = !notification.isRead;
    final isAdminNotice =
        notification.recipientCollection == AppConstants.adminsCollection;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AppSurfaceCard(
          padding: const EdgeInsets.all(14),
          borderRadius: BorderRadius.circular(20),
          color: colors.card,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _iconBgForType(context, notification.type),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _iconForType(notification.type),
                  color: colors.iconPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.poppins(
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              fontSize: 13.5,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colors.brandPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.body,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        height: 1.45,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AppStatusChip(
                          label: notification.type.replaceAll('_', ' '),
                          tone: _toneForType(notification.type),
                        ),
                        if (isAdminNotice)
                          const AppStatusChip(
                            label: 'Admin',
                            tone: AppStatusChipTone.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatTime(notification.createdAt),
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '← swipe to delete',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: colors.textSecondary.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: colors.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
