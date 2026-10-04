import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/user_session.dart';
import '../../widgets/custom_button.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // ============================================================
  // LOGGED-IN USER / VEHICLE
  // ============================================================

  final int? userId = UserSession.userId;

  int? vehicleId;

  bool _isLoadingVehicle = true;

  // ============================================================
  // BOOKING DATA
  // ============================================================

  DateTime? selectedDate;
  String? selectedTime;

  final TextEditingController addressController =
  TextEditingController();

  final TextEditingController notesController =
  TextEditingController();

  // ============================================================
  // TIME SLOTS
  // ============================================================

  final List<String> timeSlots = [
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
    '06:00 PM',
  ];

  // ============================================================
  // LOAD USER VEHICLE
  // ============================================================

  Future<void> _loadUserVehicle() async {
    if (userId == null) {
      setState(() {
        _isLoadingVehicle = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User session not found. Please login again.'),
          ),
        );
      }

      return;
    }

    try {
      final response = await ApiService.getUserVehicle(userId!);

      debugPrint('Vehicle API Response: $response');

      int? foundVehicleId;

      // Case 1: API returns { "vehicles": [ {...} ] }
      if (response['vehicles'] is List &&
          (response['vehicles'] as List).isNotEmpty) {
        final vehicles = response['vehicles'] as List;

        final firstVehicle = vehicles.first;

        if (firstVehicle is Map && firstVehicle['id'] != null) {
          foundVehicleId = int.tryParse(
            firstVehicle['id'].toString(),
          );
        }
      }

      // Case 2: API returns { "vehicle": {...} }
      if (foundVehicleId == null &&
          response['vehicle'] is Map &&
          response['vehicle']['id'] != null) {
        foundVehicleId = int.tryParse(
          response['vehicle']['id'].toString(),
        );
      }

      // Case 3: API directly returns { "id": 6, ... }
      if (foundVehicleId == null && response['id'] != null) {
        foundVehicleId = int.tryParse(
          response['id'].toString(),
        );
      }

      if (foundVehicleId != null) {
        setState(() {
          vehicleId = foundVehicleId;
          _isLoadingVehicle = false;
        });

        debugPrint('Vehicle ID loaded successfully: $vehicleId');
      } else {
        setState(() {
          _isLoadingVehicle = false;
        });

        debugPrint('No vehicle ID found in response.');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Vehicle not found. Please add your vehicle first.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading vehicle: $e');

      setState(() {
        _isLoadingVehicle = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to load vehicle: $e',
            ),
          ),
        );
      }
    }
  }

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadUserVehicle();
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectDate() async {
    final DateTime today = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: today.add(
        const Duration(days: 30),
      ),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  // ============================================================
  // FORMAT DATE FOR DISPLAY
  // ============================================================

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // ============================================================
  // FORMAT DATE FOR API
  // ============================================================

  String _formatDateForApi(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // CONVERT TIME TO 24 HOUR FORMAT
  // ============================================================

  String _convertTimeTo24Hour(String time) {
    final parts = time.split(' ');

    final timePart = parts[0];
    final period = parts[1];

    final hourMinute = timePart.split(':');

    int hour = int.parse(hourMinute[0]);
    final int minute = int.parse(hourMinute[1]);

    if (period == 'AM' && hour == 12) {
      hour = 0;
    }

    if (period == 'PM' && hour != 12) {
      hour += 12;
    }

    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}:00';
  }

  // ============================================================
  // CONFIRM BOOKING
  // ============================================================

  Future<void> _confirmBooking() async {
    final String? selectedService =
    ModalRoute.of(context)?.settings.arguments as String?;

    // ----------------------------------------------------------
    // VALIDATE SERVICE
    // ----------------------------------------------------------

    if (selectedService == null ||
        selectedService.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Service information is missing.',
          ),
        ),
      );
      return;
    }

    // ----------------------------------------------------------
    // VALIDATE DATE
    // ----------------------------------------------------------

    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a service date.',
          ),
        ),
      );
      return;
    }

    // ----------------------------------------------------------
    // VALIDATE TIME
    // ----------------------------------------------------------

    if (selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a service time.',
          ),
        ),
      );
      return;
    }

    // ----------------------------------------------------------
    // VALIDATE ADDRESS
    // ----------------------------------------------------------

    if (addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your service address.',
          ),
        ),
      );
      return;
    }

    // ----------------------------------------------------------
    // CHECK USER
    // ----------------------------------------------------------

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'User session not found. Please login again.',
          ),
        ),
      );
      return;
    }

    // ----------------------------------------------------------
    // CHECK VEHICLE LOADING
    // ----------------------------------------------------------

    if (_isLoadingVehicle) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please wait while your vehicle information is loading.',
          ),
        ),
      );
      return;
    }

    // ----------------------------------------------------------
    // CHECK VEHICLE
    // ----------------------------------------------------------

    if (vehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vehicle not found. Please add your vehicle first.',
          ),
        ),
      );
      return;
    }

    // ----------------------------------------------------------
    // PREPARE DATA
    // ----------------------------------------------------------

    final String formattedDate =
    _formatDateForApi(selectedDate!);

    final String formattedTime =
    _convertTimeTo24Hour(selectedTime!);

    final String address =
    addressController.text.trim();

    final String notes =
    notesController.text.trim();

    // ----------------------------------------------------------
    // API CALL
    // ----------------------------------------------------------

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      debugPrint('Booking User ID: $userId');
      debugPrint('Booking Vehicle ID: $vehicleId');
      debugPrint('Booking Service: $selectedService');

      final response =
      await ApiService.createServiceRequest(
        userId: userId!,
        vehicleId: vehicleId!,
        serviceType: selectedService,
        preferredDate: formattedDate,
        preferredTime: formattedTime,
        address: address,
        notes: notes.isEmpty ? null : notes,
      );

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      debugPrint('Booking API Response: $response');

      // --------------------------------------------------------
      // SUCCESS
      // --------------------------------------------------------

      if (response['service_request'] != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text(
                'Booking Confirmed',
              ),
              content: Text(
                'Your $selectedService has been successfully '
                    'booked for ${_formatDate(selectedDate!)} '
                    'at $selectedTime.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      } else {
        // ------------------------------------------------------
        // API ERROR
        // ------------------------------------------------------

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ??
                  response['error'] ??
                  'Unable to complete booking.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context);

      debugPrint('Booking API Error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Booking failed: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    addressController.dispose();
    notesController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final String? selectedService =
    ModalRoute.of(context)?.settings.arguments as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Service'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // ------------------------------------------------
              // HEADER ICON
              // ------------------------------------------------

              const Icon(
                Icons.calendar_month_outlined,
                color: AppColors.primary,
                size: 65,
              ),

              const SizedBox(height: 15),

              const Text(
                'Schedule Your Service',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Choose a convenient date and time for '
                    'the mechanic to visit you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 30),

              // ------------------------------------------------
              // SELECTED SERVICE
              // ------------------------------------------------

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                        BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.build_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selected Service',
                            style: TextStyle(
                              fontSize: 13,
                              color:
                              AppColors.textSecondary,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            selectedService ??
                                'Home Vehicle Service',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                              AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ------------------------------------------------
              // DATE
              // ------------------------------------------------

              const Text(
                'Select Date',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                    BorderRadius.circular(16),
                    border: Border.all(
                      color: selectedDate != null
                          ? AppColors.primary
                          : AppColors.border,
                      width:
                      selectedDate != null ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.primary,
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Text(
                          selectedDate == null
                              ? 'Choose service date'
                              : _formatDate(
                            selectedDate!,
                          ),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                            selectedDate != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color:
                            selectedDate != null
                                ? AppColors.textPrimary
                                : AppColors
                                .textSecondary,
                          ),
                        ),
                      ),

                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color:
                        AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ------------------------------------------------
              // TIME
              // ------------------------------------------------

              const Text(
                'Select Time',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: timeSlots.map(
                      (time) {
                    final bool isSelected =
                        selectedTime == time;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedTime = time;
                        });
                      },
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius:
                          BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          time,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                            FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ).toList(),
              ),

              const SizedBox(height: 30),

              // ------------------------------------------------
              // ADDRESS
              // ------------------------------------------------

              const Text(
                'Service Address',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText:
                  'Enter the address where the mechanic should visit',
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.border,
                    ),
                  ),
                  enabledBorder:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.border,
                    ),
                  ),
                  focusedBorder:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ------------------------------------------------
              // NOTES
              // ------------------------------------------------

              const Text(
                'Additional Notes',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                  'Example: Please check engine oil, brakes, battery, etc.',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(
                      bottom: 65,
                    ),
                    child: Icon(
                      Icons.notes_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.border,
                    ),
                  ),
                  enabledBorder:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.border,
                    ),
                  ),
                  focusedBorder:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 35),

              // ------------------------------------------------
              // CONFIRM BOOKING
              // ------------------------------------------------

              CustomButton(
                text: 'Confirm Booking',
                icon: Icons.check_circle_outline,
                onPressed: _confirmBooking,
              ),

              const SizedBox(height: 20),

              const Text(
                'Your booking will be saved to MotoMate '
                    'and a notification will be generated automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}