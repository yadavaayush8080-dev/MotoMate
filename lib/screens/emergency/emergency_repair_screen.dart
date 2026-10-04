import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/user_session.dart';
import '../../widgets/custom_button.dart';

class EmergencyRepairScreen extends StatefulWidget {
  const EmergencyRepairScreen({super.key});

  @override
  State<EmergencyRepairScreen> createState() => _EmergencyRepairScreenState();
}

class _EmergencyRepairScreenState extends State<EmergencyRepairScreen> {
  bool isLoading = false;
  bool isRequestingHelp = false;

  Position? currentPosition;
  String? locationError;

  // Selected breakdown symptom / issue
  String _selectedIssue = 'Engine Breakdown';

  final List<Map<String, dynamic>> _issueTypes = [
    {'title': 'Engine Breakdown', 'icon': Icons.car_crash_rounded},
    {'title': 'Flat Tyre', 'icon': Icons.tire_repair_rounded},
    {'title': 'Battery Dead', 'icon': Icons.battery_alert_rounded},
    {'title': 'Brake Issue', 'icon': Icons.warning_amber_rounded},
    {'title': 'Out of Fuel', 'icon': Icons.local_gas_station_rounded},
    {'title': 'Towing Needed', 'icon': Icons.rv_hookup_rounded},
  ];

  final int userId = UserSession.userId ?? 0;
  int? vehicleId; // Loaded from API on init

  @override
  void initState() {
    super.initState();
    // Auto-attempt location detection on entering emergency screen
    _getLocation();
    _loadVehicleId();
  }

  // ============================================================
  // LOAD VEHICLE ID FROM API
  // ============================================================
  Future<void> _loadVehicleId() async {
    if (userId == 0) return;
    try {
      final response = await ApiService.getUserVehicle(userId);

      int? found;

      if (response['vehicles'] is List &&
          (response['vehicles'] as List).isNotEmpty) {
        final first = (response['vehicles'] as List).first;
        if (first is Map && first['id'] != null) {
          found = int.tryParse(first['id'].toString());
        }
      }

      found ??= (response['vehicle'] is Map &&
              response['vehicle']['id'] != null)
          ? int.tryParse(response['vehicle']['id'].toString())
          : int.tryParse(response['id']?.toString() ?? '');

      if (found != null && mounted) {
        setState(() => vehicleId = found);
        UserSession.vehicleId = found; // cache for other screens
      }
    } catch (_) {
      // Silently ignore — error surfaces when user taps SOS
    }
  }

  // ============================================================
  // GET CURRENT LOCATION
  // ============================================================
  Future<void> _getLocation() async {

    setState(() {
      isLoading = true;
      locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          isLoading = false;
          locationError = 'GPS is turned off. Please enable location services.';
        });
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            isLoading = false;
            locationError = 'Location permission was denied.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          isLoading = false;
          locationError =
              'Location permission is permanently denied. Please enable it in Settings.';
        });
        await Geolocator.openAppSettings();
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      ).timeout(
        const Duration(seconds: 20),
      );

      setState(() {
        currentPosition = position;
        isLoading = false;
        locationError = null;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        locationError = 'Unable to get location: $e';
      });
    }
  }

  // ============================================================
  // CREATE EMERGENCY REQUEST
  // ============================================================
  Future<void> _requestEmergencyHelp() async {
    if (currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please detect your location first before requesting SOS.'),
        ),
      );
      return;
    }

    if (vehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No vehicle found. Please add your vehicle in the app first.'),
        ),
      );
      return;
    }

    setState(() {
      isRequestingHelp = true;
    });

    try {
      final response = await ApiService.createEmergencyRequest(
        userId: userId,
        vehicleId: vehicleId!,
        latitude: currentPosition!.latitude,
        longitude: currentPosition!.longitude,
        problemDescription: '$_selectedIssue - Emergency roadside assistance required',
      );

      if (!mounted) return;

      setState(() {
        isRequestingHelp = false;
      });

      if (response['emergency_request'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your request has been received. Our team will contact you shortly.'),
          ),
        );
        _showAssignedMechanicModal(
          response['emergency_request'] as Map<String, dynamic>,
          response['mechanic'] as Map<String, dynamic>?,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Unable to create emergency request.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isRequestingHelp = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Emergency request failed: $e'),
        ),
      );
    }
  }

  void _showAssignedMechanicModal(
    Map<String, dynamic> request,
    Map<String, dynamic>? mechanic,
  ) {
    // Try to extract mechanic info from multiple possible response shapes
    final Map<String, dynamic> mech = mechanic ??
        (request['mechanic'] is Map
            ? Map<String, dynamic>.from(request['mechanic'] as Map)
            : request['assigned_mechanic'] is Map
                ? Map<String, dynamic>.from(request['assigned_mechanic'] as Map)
                : {});

    final String shopName =
        mech['shop_name']?.toString() ?? mech['name']?.toString() ?? 'Nearby Workshop';
    final String mechanicName = mech['mechanic_name']?.toString() ??
        mech['specialist']?.toString() ??
        'Certified Specialist';
    final String phone = mech['phone']?.toString() ?? mech['contact']?.toString() ?? '--';
    final String distance =
        mech['distance_km']?.toString() ?? mech['distance']?.toString() ?? '–';
    final String rating = mech['rating']?.toString() ?? '4.8';
    final String requestId = request['id']?.toString() ?? '--';
    final String status =
        (request['status'] ?? 'ASSIGNED').toString().toUpperCase();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Red accent top bar ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7F1D1D), Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.handyman_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Workshop Assigned!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A certified mechanic is on the way to you',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),

            // ── Workshop details ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  // Shop name row
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.store_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shopName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              mechanicName,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Rating badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 15, color: Color(0xFFD97706)),
                            const SizedBox(width: 3),
                            Text(
                              rating,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Info chips row
                  Row(
                    children: [
                      Expanded(
                        child: _infoTile(
                          Icons.near_me_rounded,
                          'Distance',
                          distance != '–' ? '$distance km away' : 'Nearby',
                          AppColors.infoLight,
                          AppColors.info,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _infoTile(
                          Icons.phone_rounded,
                          'Contact',
                          phone != '--' ? phone : 'In-app contact',
                          AppColors.successLight,
                          AppColors.success,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Request ID + status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Request ID  #$requestId',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Dismiss button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Got it, Track Mechanic',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(
    IconData icon,
    String label,
    String value,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: iconColor.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final bool locationFound = currentPosition != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Emergency Assistance'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Urgent Header Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7F1D1D), Color(0xFFDC2626)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emergency.withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.sos_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Emergency SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Stranded? Nearby certified mechanics will be dispatched immediately.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ISSUE TYPE SELECTOR
              const Text(
                'What is the issue?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _issueTypes.map((issue) {
                  final isSelected = _selectedIssue == issue['title'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIssue = issue['title'];
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            issue['icon'],
                            size: 18,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            issue['title'],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // LOCATION CARD
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: locationFound
                                    ? AppColors.successLight
                                    : AppColors.infoLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                locationFound
                                    ? Icons.my_location_rounded
                                    : Icons.location_searching_rounded,
                                color: locationFound
                                    ? AppColors.success
                                    : AppColors.info,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Live GPS Location',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),

                        // Re-detect button
                        TextButton.icon(
                          onPressed: isLoading ? null : _getLocation,
                          icon: isLoading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded, size: 16),
                          label: Text(
                            isLoading ? 'Locating...' : 'Refresh',
                            style: const TextStyle(fontSize: 12.5),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    if (locationFound) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.pin_drop_rounded,
                              color: AppColors.emergency,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Lat: ${currentPosition!.latitude.toStringAsFixed(5)}, Lon: ${currentPosition!.longitude.toStringAsFixed(5)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.successLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'High Accuracy',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (locationError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.emergencyLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.emergency,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                locationError!,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.emergency,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Acquiring your precise GPS coordinates...',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // SOS ACTION BUTTON
              CustomButton(
                text: isRequestingHelp
                    ? 'Dispatching Help...'
                    : 'Request Immediate Help',
                icon: Icons.emergency_rounded,
                isLoading: isRequestingHelp,
                gradient: AppColors.emergencyGradient,
                onPressed: locationFound && !isRequestingHelp
                    ? _requestEmergencyHelp
                    : () {
                        if (!locationFound) {
                          _getLocation();
                        } else {
                          _requestEmergencyHelp();
                        }
                      },
              ),

              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.security_rounded,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Direct connection to nearest verified mechanic',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}