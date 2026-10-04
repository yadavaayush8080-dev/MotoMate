import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/mechanic_session.dart';
import 'mechanic_emergency_request_details_screen.dart';

class MechanicNotificationsScreen extends StatefulWidget {
  const MechanicNotificationsScreen({super.key});

  @override
  State<MechanicNotificationsScreen> createState() =>
      _MechanicNotificationsScreenState();
}

class _MechanicNotificationsScreenState
    extends State<MechanicNotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final mechanicId = MechanicSession.mechanicId;

    if (mechanicId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Mechanic session expired. Please log in again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response =
          await ApiService.getMechanicNotifications(mechanicId);

      if (!mounted) return;

      if (response['notifications'] is List) {
        setState(() {
          _notifications = response['notifications'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              response['message'] ?? 'Unable to load notifications.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to connect to server. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 50,
                color: AppColors.emergency,
              ),
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _loadNotifications,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 60,
                color: AppColors.textMuted,
              ),
              SizedBox(height: 14),
              Text(
                'No Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Incoming roadside breakdown alerts and booking reminders will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification =
              _notifications[index] as Map<String, dynamic>;
          return _notificationCard(notification);
        },
      ),
    );
  }

  Widget _notificationCard(Map<String, dynamic> notification) {
    final String title =
        notification['title']?.toString() ?? 'Notification';
    final String message = notification['message']?.toString() ?? '';
    final String type = notification['notification_type']?.toString() ?? '';
    final bool isRead = notification['is_read'] == true;
    final int? requestId =
        int.tryParse(notification['request_id']?.toString() ?? '');

    IconData icon = Icons.notifications_rounded;
    Color iconColor = AppColors.primary;
    Color iconBg = AppColors.primary.withOpacity(0.12);

    if (type == 'emergency_request') {
      icon = Icons.emergency_rounded;
      iconColor = AppColors.emergency;
      iconBg = AppColors.emergencyLight;
    } else if (type == 'service_request') {
      icon = Icons.home_repair_service_rounded;
      iconColor = AppColors.secondary;
      iconBg = AppColors.warningLight;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isRead ? AppColors.border : AppColors.primaryLight.withOpacity(0.5),
          width: isRead ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: requestId == null
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MechanicEmergencyRequestDetailsScreen(
                        requestId: requestId,
                      ),
                    ),
                  );
                },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight:
                              isRead ? FontWeight.w600 : FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isRead)
                  Container(
                    margin: const EdgeInsets.only(left: 8, top: 4),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.emergency,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}