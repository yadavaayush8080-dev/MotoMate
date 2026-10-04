import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/mechanic_session.dart';

class MechanicServiceRequestsScreen extends StatefulWidget {
  const MechanicServiceRequestsScreen({super.key});

  @override
  State<MechanicServiceRequestsScreen> createState() =>
      _MechanicServiceRequestsScreenState();
}

class _MechanicServiceRequestsScreenState
    extends State<MechanicServiceRequestsScreen> {
  List<dynamic> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<int> _processingRequests = {};

  @override
  void initState() {
    super.initState();
    _loadServiceRequests();
  }

  Future<void> _loadServiceRequests() async {
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
          await ApiService.getMechanicServiceRequests(mechanicId);

      if (!mounted) return;

      if (response['service_requests'] is List) {
        setState(() {
          _requests = List<Map<String, dynamic>>.from(
            response['service_requests'],
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              response['message'] ?? 'Unable to load service requests.';
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

  Future<void> _updateServiceRequestStatus(
    int requestId,
    String status,
  ) async {
    final mechanicId = MechanicSession.mechanicId;

    if (mechanicId == null || _processingRequests.contains(requestId)) {
      return;
    }

    setState(() {
      _processingRequests.add(requestId);
    });

    try {
      final response = await ApiService.updateMechanicServiceRequestStatus(
        requestId: requestId,
        mechanicId: mechanicId,
        status: status,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message'] ?? 'Service request status updated.',
          ),
        ),
      );

      await _loadServiceRequests();
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
          _processingRequests.remove(requestId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Doorstep Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadServiceRequests,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadServiceRequests,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          children: [
            // HEADER BANNER
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withOpacity(0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.home_repair_service_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Scheduled Maintenance',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_requests.length} total customer home service appointments',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              _errorWidget()
            else if (_requests.isEmpty)
              _emptyRequestsWidget()
            else ...[
              ..._requests.map((request) {
                return _serviceRequestCard(request as Map<String, dynamic>);
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _serviceRequestCard(Map<String, dynamic> request) {
    final int? requestId = int.tryParse(request['id']?.toString() ?? '');
    final String status = request['status']?.toString() ?? 'booked';
    final String customerName =
        request['customer_name']?.toString() ?? 'Customer';
    final String customerPhone =
        request['customer_phone']?.toString() ?? 'Not available';
    final String vehicleBrand = request['vehicle_brand']?.toString() ?? '';
    final String vehicleModel = request['vehicle_model']?.toString() ?? '';
    final String registrationNumber =
        request['registration_number']?.toString() ?? '';
    final String serviceType =
        request['service_type']?.toString() ?? 'Regular Maintenance';
    final String preferredDate =
        request['preferred_date']?.toString() ?? 'Scheduled';
    final String preferredTime =
        request['preferred_time']?.toString() ?? 'Anytime';
    final String address = request['address']?.toString() ?? 'Customer Address';
    final String notes = request['notes']?.toString() ?? '';
    final String vehicleName = '$vehicleBrand $vehicleModel'.trim();

    final bool canRespond =
        status.toLowerCase() == 'booked' || status.toLowerCase() == 'pending';
    final bool isProcessing =
        requestId != null && _processingRequests.contains(requestId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Booking #${request['id'] ?? '--'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      serviceType,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                _statusBadge(status),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: AppColors.divider),
            ),

            // Schedule Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDCFCE7)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Date: $preferredDate',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF166534),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.access_time_rounded,
                    size: 15,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    preferredTime,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF166534),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Customer Details
            _detailRow(Icons.person_rounded, 'Customer', customerName),
            const SizedBox(height: 6),
            _detailRow(Icons.phone_rounded, 'Phone', customerPhone),
            const SizedBox(height: 6),
            _detailRow(
              Icons.directions_car_rounded,
              'Vehicle',
              vehicleName.isNotEmpty
                  ? '$vehicleName ${registrationNumber.isNotEmpty ? '($registrationNumber)' : ''}'
                  : 'Vehicle details pending',
            ),
            const SizedBox(height: 6),
            _detailRow(Icons.location_on_rounded, 'Location', address),

            if (notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Note: $notes',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],

            if (canRespond && requestId != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => _updateServiceRequestStatus(
                                requestId,
                                'accepted',
                              ),
                      icon: isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Accept Booking'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => _updateServiceRequestStatus(
                                requestId,
                                'rejected',
                              ),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.emergency,
                        side: const BorderSide(
                          color: AppColors.emergency,
                          width: 1.2,
                        ),
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$title: ',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
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
      case 'completed':
        bg = const Color(0xFFCCFBF1);
        fg = const Color(0xFF0F766E);
        break;
      default:
        bg = AppColors.warningLight;
        fg = const Color(0xFFD97706);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
        ),
      ),
    );
  }

  Widget _emptyRequestsWidget() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 44,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 12),
          Text(
            'No Doorstep Bookings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'New doorstep appointments assigned to your shop will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _errorWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.emergencyLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 38,
            color: AppColors.emergency,
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.emergency,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _loadServiceRequests,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergency,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}