import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../services/user_session.dart';

class VehicleHealthScreen extends StatefulWidget {
  const VehicleHealthScreen({super.key});

  @override
  State<VehicleHealthScreen> createState() => _VehicleHealthScreenState();
}

class _VehicleHealthScreenState extends State<VehicleHealthScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  int _healthScore = 0;
  String _healthStatus = '';
  String _healthMessage = '';

  Map<String, dynamic> _components = {};

  @override
  void initState() {
    super.initState();
    _loadVehicleHealth();
  }

  Future<void> _loadVehicleHealth() async {
    final int? userId = UserSession.userId;

    if (userId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User session not found. Please log in again.';
      });
      return;
    }

    try {
      final response = await ApiService.getVehicleHealth(userId);
      final health = response['health'];
      final components = response['components'];

      if (health == null || components == null) {
        throw Exception('Invalid vehicle health response.');
      }

      setState(() {
        _healthScore = int.tryParse(health['score'].toString()) ?? 0;
        _healthStatus = health['status']?.toString() ?? 'Unknown';
        _healthMessage = health['message']?.toString() ?? '';
        _components = Map<String, dynamic>.from(components);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load vehicle health diagnostics.';
      });
    }
  }

  Map<String, dynamic> _component(String key) {
    final component = _components[key];
    if (component is Map<String, dynamic>) {
      return component;
    }
    return {'score': 0, 'status': 'Unknown'};
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.emergency;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vehicle Health'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Diagnostics',
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _loadVehicleHealth();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _errorMessage != null
                ? _buildErrorState()
                : _buildHealthContent(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: AppColors.emergencyLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 38,
                color: AppColors.emergency,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadVehicleHealth();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry Diagnostics'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthContent() {
    final engine = _component('engine');
    final battery = _component('battery');
    final brakes = _component('brakes');
    final tyres = _component('tyres');
    final engineOil = _component('engine_oil');

    final scoreColor = _getScoreColor(_healthScore);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // GAUGES HERO CARD
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.heroCardGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withOpacity(0.20),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Overall Health Score',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: scoreColor.withOpacity(0.6),
                        ),
                      ),
                      child: Text(
                        _healthStatus.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: scoreColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // Health Dial / Score Ring
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: (_healthScore / 100).clamp(0.0, 1.0),
                        strokeWidth: 10,
                        backgroundColor: Colors.white.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_healthScore',
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          'OUT OF 100',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.6),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Text(
                  _healthMessage.isNotEmpty
                      ? _healthMessage
                      : 'Telemetry data evaluated by MotoMate algorithms.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.80),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // QUICK ACTIONS (AI Diagnostic or Book Home Service)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.aiAssistant);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: Color(0xFF7C3AED),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Ask AI Assistant',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.homeService);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.home_repair_service_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Book Service',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 26),

          // SECTION TITLE
          const Text(
            'Component Diagnostics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 14),

          // Component Cards
          _modernComponentCard(
            icon: Icons.tune_rounded,
            title: 'Engine System',
            status: engine['status']?.toString() ?? 'Good',
            score: int.tryParse(engine['score'].toString()) ?? 85,
          ),
          _modernComponentCard(
            icon: Icons.battery_charging_full_rounded,
            title: 'Battery & Electrical',
            status: battery['status']?.toString() ?? 'Good',
            score: int.tryParse(battery['score'].toString()) ?? 90,
          ),
          _modernComponentCard(
            icon: Icons.disc_full_rounded,
            title: 'Braking System',
            status: brakes['status']?.toString() ?? 'Good',
            score: int.tryParse(brakes['score'].toString()) ?? 80,
          ),
          _modernComponentCard(
            icon: Icons.tire_repair_rounded,
            title: 'Tyres & Tread Wear',
            status: tyres['status']?.toString() ?? 'Good',
            score: int.tryParse(tyres['score'].toString()) ?? 75,
          ),
          _modernComponentCard(
            icon: Icons.water_drop_rounded,
            title: 'Engine Oil & Lubrication',
            status: engineOil['status']?.toString() ?? 'Good',
            score: int.tryParse(engineOil['score'].toString()) ?? 85,
          ),

          const SizedBox(height: 16),

          // RECOMMENDATION CARD
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.025),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.tips_and_updates_rounded,
                    color: Color(0xFFD97706),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Maintenance Advisory',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getRecommendation(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getRecommendation() {
    final tyres = _component('tyres');
    final engineOil = _component('engine_oil');

    final tyresScore = int.tryParse(tyres['score'].toString()) ?? 0;
    final oilScore = int.tryParse(engineOil['score'].toString()) ?? 0;

    if (tyresScore < 70) {
      return 'Tyre tread depth or pressure needs verification. Inspect tyre condition soon.';
    }
    if (oilScore < 70) {
      return 'Engine oil viscosity or schedule indicates service is due. Book an oil change.';
    }
    if (_healthScore < 80) {
      return 'Certain vehicle subsystems require attention. Schedule a checkup.';
    }
    return 'Your vehicle systems are performing within optimal parameters. Keep up regular maintenance!';
  }

  Widget _modernComponentCard({
    required IconData icon,
    required String title,
    required String status,
    required int score,
  }) {
    final color = _getScoreColor(score);
    final isAttention = status.toLowerCase().contains('attention') || score < 70;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isAttention ? AppColors.warning : color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '$score%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress track
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (score / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.surfaceSecondary,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}