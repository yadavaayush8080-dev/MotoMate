import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/user_session.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Temporary user ID for backend testing.
  // Later this will come from the logged-in user.
  int? get userId => UserSession.userId;

  late Future<Map<String, dynamic>> notificationsFuture;

  @override
  void initState() {
    super.initState();

    if (UserSession.userId != null) {
      notificationsFuture =
          ApiService.getNotifications(UserSession.userId!);
    } else {
      notificationsFuture = Future.error(
        Exception('User ID is required!'),
      );
    }
  }

  Future<void> _refreshNotifications() async {
    final int? currentUserId = UserSession.userId;

    if (currentUserId == null) {
      return;
    }

    setState(() {
      notificationsFuture =
          ApiService.getNotifications(currentUserId);
    });

    await notificationsFuture;
  }
  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'service_booking':
        return Icons.car_repair;

      case 'service_reminder':
        return Icons.build_circle_outlined;

      case 'insurance':
        return Icons.description_outlined;

      case 'puc':
        return Icons.verified_outlined;

      case 'vehicle_health':
        return Icons.health_and_safety_outlined;

      default:
        return Icons.notifications_outlined;
    }
  }

  bool _isImportant(String type) {
    return type == 'service_reminder' ||
        type == 'insurance' ||
        type == 'puc';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications marked as read.'),
                ),
              );
            },
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
          ),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshNotifications,
          child: FutureBuilder<Map<String, dynamic>>(
            future: notificationsFuture,

            builder: (context, snapshot) {

              // Loading
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              // Error
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: AppColors.primary,
                        ),

                        const SizedBox(height: 15),

                        const Text(
                          'Unable to load notifications.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'Please make sure the Django server is running.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 20),

                        ElevatedButton(
                          onPressed: _refreshNotifications,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // API response
              final data = snapshot.data;

              final List notifications =
                  data?['notifications'] ?? [];

              // No notifications
              if (notifications.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: const [
                    SizedBox(height: 100),

                    Icon(
                      Icons.notifications_none,
                      size: 70,
                      color: AppColors.primary,
                    ),

                    SizedBox(height: 20),

                    Text(
                      'No notifications yet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    SizedBox(height: 8),

                    Text(
                      'You will see vehicle updates and service notifications here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                );
              }

              // Notifications available
              return RefreshIndicator(
                onRefresh: _refreshNotifications,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [

                    const Text(
                      'Your Notifications',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 15),

                    ...notifications.map((notification) {

                      final String title =
                          notification['title'] ?? 'Notification';

                      final String message =
                          notification['message'] ?? '';

                      final String type =
                          notification['notification_type'] ?? '';

                      final bool isRead =
                          notification['is_read'] ?? false;

                      final String createdAt =
                          notification['created_at'] ?? '';

                      return _notificationCard(
                        icon: _getNotificationIcon(type),
                        title: title,
                        message: message,
                        time: createdAt,
                        isImportant:
                        !isRead || _isImportant(type),
                      );
                    }),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.border,
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                            size: 25,
                          ),

                          SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              'MotoMate automatically generates notifications for important vehicle and service updates.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _notificationCard({
    required IconData icon,
    required String title,
    required String message,
    required String time,
    required bool isImportant,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isImportant
              ? AppColors.primary.withOpacity(0.4)
              : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 27,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                    if (isImportant)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}