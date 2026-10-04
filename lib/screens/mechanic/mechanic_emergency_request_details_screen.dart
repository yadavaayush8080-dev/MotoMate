import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/mechanic_session.dart';

class MechanicEmergencyRequestDetailsScreen extends StatefulWidget {
  final int requestId;

  const MechanicEmergencyRequestDetailsScreen({
    super.key,
    required this.requestId,
  });

  @override
  State<MechanicEmergencyRequestDetailsScreen> createState() =>
      _MechanicEmergencyRequestDetailsScreenState();
}

class _MechanicEmergencyRequestDetailsScreenState
    extends State<MechanicEmergencyRequestDetailsScreen> {
  Map<String, dynamic>? _request;

  bool _isLoading = true;
  bool _isUpdating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    final mechanicId = MechanicSession.mechanicId;

    if (mechanicId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Mechanic session expired. Please log in again.';
      });
      return;
    }

    try {
      final response =
          await ApiService.getMechanicEmergencyRequests(mechanicId);

      if (!mounted) return;

      if (response['requests'] is List) {
        final requests = response['requests'] as List;

        Map<String, dynamic>? foundRequest;

        for (final request in requests) {
          if (request is Map<String, dynamic> &&
              request['id'].toString() == widget.requestId.toString()) {
            foundRequest = request;
            break;
          }
        }

        if (foundRequest != null) {
          setState(() {
            _request = foundRequest;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Emergency request not found.';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to load emergency request.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to connect to server. Please try again.';
      });
    }
  }

  Future<void> _updateRequestStatus(String status) async {
    final mechanicId = MechanicSession.mechanicId;
    if (mechanicId == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final response = await ApiService.updateMechanicEmergencyRequestStatus(
        requestId: widget.requestId,
        mechanicId: mechanicId,
        status: status,
      );

      if (!mounted) return;

      if (response['status'] == status || response['message'] != null) {
        setState(() {
          if (_request != null) {
            _request!['status'] = status;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'accepted'
                  ? '✅ Emergency request accepted.'
                  : 'Emergency request rejected.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Unable to update request status.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update request. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('SOS Ticket #${widget.requestId}'),
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
                size: 55,
                color: AppColors.emergency,
              ),
              const SizedBox(height: 15),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: _loadRequest,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_request == null) {
      return const Center(child: Text('Emergency request not found.'));
    }

    final customerName = _request!['customer_name']?.toString() ?? 'Customer';
    final customerPhone =
        _request!['customer_phone']?.toString() ?? 'Not available';
    final vehicleBrand = _request!['vehicle_brand']?.toString() ?? '';
    final vehicleModel = _request!['vehicle_model']?.toString() ?? '';
    final registrationNumber =
        _request!['registration_number']?.toString() ?? '';
    final problem = _request!['problem_description']?.toString() ??
        'Emergency roadside breakdown';
    final status = _request!['status']?.toString() ?? 'assigned';
    final latitude = _request!['latitude']?.toString() ?? 'N/A';
    final longitude = _request!['longitude']?.toString() ?? 'N/A';
    final vehicleName = '$vehicleBrand $vehicleModel'.trim();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // TICKET STATUS BANNER
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.heroCardGradient,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withOpacity(0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TICKET #00${widget.requestId}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Roadside SOS Dispatch',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                _statusBadge(status),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // CUSTOMER CONTACT CARD
          _infoCard(
            title: 'Customer Contact',
            icon: Icons.person_pin_rounded,
            color: AppColors.primary,
            child: Column(
              children: [
                _detailRow('Customer Name', customerName),
                const SizedBox(height: 8),
                _detailRow('Phone Number', customerPhone),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // VEHICLE PROFILE CARD
          _infoCard(
            title: 'Vehicle Information',
            icon: Icons.directions_car_rounded,
            color: AppColors.secondary,
            child: Column(
              children: [
                _detailRow(
                  'Make & Model',
                  vehicleName.isNotEmpty ? vehicleName : 'Vehicle Specs',
                ),
                const SizedBox(height: 8),
                _detailRow(
                  'Registration Plate',
                  registrationNumber.isNotEmpty
                      ? registrationNumber.toUpperCase()
                      : 'Unavailable',
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // PROBLEM CARD
          _infoCard(
            title: 'Reported Breakdown Issue',
            icon: Icons.warning_rounded,
            color: AppColors.emergency,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                problem,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF991B1B),
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // GPS LOCATION CARD
          _infoCard(
            title: 'Customer Coordinates',
            icon: Icons.near_me_rounded,
            color: AppColors.info,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Latitude: $latitude',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Longitude: $longitude',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.map_rounded, size: 14, color: AppColors.info),
                      SizedBox(width: 4),
                      Text(
                        'GPS Tracked',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ACTION BUTTONS (Accept / Reject)
          if (status == 'assigned' || status == 'pending') ...[
            ElevatedButton.icon(
              onPressed: _isUpdating
                  ? null
                  : () => _updateRequestStatus('accepted'),
              icon: _isUpdating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded),
              label: Text(
                _isUpdating ? 'Updating...' : 'Accept & Start Dispatch',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isUpdating
                  ? null
                  : () => _updateRequestStatus('rejected'),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Decline Request'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.emergency,
                side: const BorderSide(color: AppColors.emergency, width: 1.5),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;

    switch (status.toLowerCase()) {
      case 'accepted':
        bg = AppColors.successLight;
        fg = AppColors.success;
        break;
      case 'rejected':
        bg = AppColors.emergencyLight;
        fg = AppColors.emergency;
        break;
      case 'assigned':
        bg = AppColors.warningLight;
        fg = const Color(0xFFD97706);
        break;
      default:
        bg = AppColors.infoLight;
        fg = AppColors.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}