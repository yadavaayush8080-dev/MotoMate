import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/user_session.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final TextEditingController brandController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController registrationController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController kilometersController = TextEditingController();

  // Fuel type
  String? selectedFuelType;

  final List<String> fuelTypes = [
    'Petrol',
    'Diesel',
    'CNG',
    'Electric',
    'Hybrid',
  ];

  // Dates
  DateTime? insuranceExpiryDate;
  DateTime? pucExpiryDate;
  DateTime? lastServiceDate;

  // Loading state
  bool _isLoading = false;

  @override
  void dispose() {
    brandController.dispose();
    modelController.dispose();
    registrationController.dispose();
    yearController.dispose();
    kilometersController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadVehicle();
  }

  // ------------------------------------------------------------
  // DATE PICKER
  // ------------------------------------------------------------
  Future<void> _selectDate(String dateType) async {
    DateTime initialDate = DateTime.now();

    if (dateType == 'insurance' && insuranceExpiryDate != null) {
      initialDate = insuranceExpiryDate!;
    } else if (dateType == 'puc' && pucExpiryDate != null) {
      initialDate = pucExpiryDate!;
    } else if (dateType == 'service' && lastServiceDate != null) {
      initialDate = lastServiceDate!;
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    setState(() {
      if (dateType == 'insurance') {
        insuranceExpiryDate = pickedDate;
      } else if (dateType == 'puc') {
        pucExpiryDate = pickedDate;
      } else if (dateType == 'service') {
        lastServiceDate = pickedDate;
      }
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _databaseDateFormat(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // ------------------------------------------------------------
  // SAVE VEHICLE
  // ------------------------------------------------------------
  Future<void> _saveVehicle() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    if (selectedFuelType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a fuel type.')),
      );
      return;
    }

    if (insuranceExpiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select insurance expiry date.')),
      );
      return;
    }

    if (pucExpiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select PUC expiry date.')),
      );
      return;
    }

    if (lastServiceDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select last service date.')),
      );
      return;
    }

    if (UserSession.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final existingResult = await ApiService.getUserVehicle(
        UserSession.userId!,
      );

      final vehicles = existingResult['vehicles'];
      Map<String, dynamic> result;

      if (vehicles != null && vehicles.isNotEmpty) {
        final int vehicleId = vehicles[0]['id'];
        result = await ApiService.updateVehicle(
          vehicleId: vehicleId,
          brand: brandController.text.trim(),
          model: modelController.text.trim(),
          registrationNumber: registrationController.text.trim(),
          fuelType: selectedFuelType!,
          vehicleYear: int.parse(yearController.text.trim()),
          currentKilometers: int.parse(kilometersController.text.trim()),
          insuranceExpiry: _databaseDateFormat(insuranceExpiryDate!),
          pucExpiry: _databaseDateFormat(pucExpiryDate!),
          lastServiceDate: _databaseDateFormat(lastServiceDate!),
        );
      } else {
        result = await ApiService.saveVehicle(
          userId: UserSession.userId!,
          brand: brandController.text.trim(),
          model: modelController.text.trim(),
          registrationNumber: registrationController.text.trim(),
          fuelType: selectedFuelType!,
          vehicleYear: int.parse(yearController.text.trim()),
          currentKilometers: int.parse(kilometersController.text.trim()),
          insuranceExpiry: _databaseDateFormat(insuranceExpiryDate!),
          pucExpiry: _databaseDateFormat(pucExpiryDate!),
          lastServiceDate: _databaseDateFormat(lastServiceDate!),
        );
      }

      if (!mounted) return;

      if (result['message'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'].toString())),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save vehicle: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // LOAD VEHICLE
  // ------------------------------------------------------------
  Future<void> _loadVehicle() async {
    if (UserSession.userId == null) return;

    try {
      final result = await ApiService.getUserVehicle(UserSession.userId!);
      final vehicles = result['vehicles'];

      if (vehicles != null && vehicles.isNotEmpty) {
        final vehicle = vehicles[0];

        setState(() {
          brandController.text = vehicle['brand'] ?? '';
          modelController.text = vehicle['model'] ?? '';
          registrationController.text = vehicle['registration_number'] ?? '';
          selectedFuelType = vehicle['fuel_type'];
          yearController.text = vehicle['vehicle_year']?.toString() ?? '';
          kilometersController.text =
              vehicle['current_kilometers']?.toString() ?? '';

          if (vehicle['insurance_expiry'] != null) {
            insuranceExpiryDate = DateTime.parse(vehicle['insurance_expiry']);
          }
          if (vehicle['puc_expiry'] != null) {
            pucExpiryDate = DateTime.parse(vehicle['puc_expiry']);
          }
          if (vehicle['last_service_date'] != null) {
            lastServiceDate = DateTime.parse(vehicle['last_service_date']);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading vehicle: $e');
    }
  }

  Widget _buildDateField({
    required String title,
    required String dateType,
    required DateTime? selectedDate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 7),
        InkWell(
          onTap: () => _selectDate(dateType),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.primary,
                  size: 19,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formatDate(selectedDate),
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: selectedDate == null
                          ? FontWeight.w400
                          : FontWeight.w600,
                      color: selectedDate == null
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Vehicle'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER HERO CARD
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroCardGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withOpacity(0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.20),
                          ),
                        ),
                        child: const Icon(
                          Icons.directions_car_filled_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              brandController.text.isNotEmpty
                                  ? '${brandController.text} ${modelController.text}'
                                  : 'Vehicle Profile',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              registrationController.text.isNotEmpty
                                  ? registrationController.text.toUpperCase()
                                  : 'Manage registration, fuel & maintenance dates',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.white.withOpacity(0.75),
                                fontWeight: registrationController.text.isNotEmpty
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // SECTION: SPECIFICATIONS
                const Text(
                  'Vehicle Specifications',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  controller: brandController,
                  label: 'Brand / Manufacturer',
                  hint: 'e.g. Honda, Hyundai, Tata',
                  prefixIcon: Icons.business_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),

                const SizedBox(height: 16),

                CustomTextField(
                  controller: modelController,
                  label: 'Vehicle Model',
                  hint: 'e.g. City, Creta, Nexon',
                  prefixIcon: Icons.directions_car_outlined,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),

                const SizedBox(height: 16),

                CustomTextField(
                  controller: registrationController,
                  label: 'Registration Number',
                  hint: 'e.g. MH 02 AB 1234',
                  prefixIcon: Icons.badge_outlined,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),

                const SizedBox(height: 16),

                // FUEL TYPE CHIPS
                const Text(
                  'Fuel Type',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: fuelTypes.map((fuel) {
                    final isSelected = selectedFuelType == fuel;
                    return ChoiceChip(
                      label: Text(fuel),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            selectedFuelType = fuel;
                          });
                        }
                      },
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: yearController,
                        label: 'Year',
                        hint: 'e.g. 2022',
                        prefixIcon: Icons.event_rounded,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (int.tryParse(v.trim()) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: CustomTextField(
                        controller: kilometersController,
                        label: 'Odometer (KM)',
                        hint: 'e.g. 25000',
                        prefixIcon: Icons.speed_rounded,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (int.tryParse(v.trim()) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),

                // SECTION: DOCUMENTS & SERVICE
                const Text(
                  'Compliance & Maintenance Dates',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 14),

                _buildDateField(
                  title: 'Insurance Expiry Date',
                  dateType: 'insurance',
                  selectedDate: insuranceExpiryDate,
                ),

                const SizedBox(height: 14),

                _buildDateField(
                  title: 'PUC Expiry Date',
                  dateType: 'puc',
                  selectedDate: pucExpiryDate,
                ),

                const SizedBox(height: 14),

                _buildDateField(
                  title: 'Last Full Service Date',
                  dateType: 'service',
                  selectedDate: lastServiceDate,
                ),

                const SizedBox(height: 28),

                CustomButton(
                  text: 'Save Vehicle Details',
                  icon: Icons.check_circle_outline_rounded,
                  isLoading: _isLoading,
                  onPressed: _saveVehicle,
                ),

                const SizedBox(height: 16),

                // Privacy hint
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your vehicle records are securely encrypted and used to calculate health diagnostics.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
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