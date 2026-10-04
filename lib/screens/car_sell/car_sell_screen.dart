import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_button.dart';

class CarSellScreen extends StatefulWidget {
  const CarSellScreen({super.key});

  @override
  State<CarSellScreen> createState() => _CarSellScreenState();
}

class _CarSellScreenState extends State<CarSellScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // In a real app you would send this data to the backend.
      // For now we just show a confirmation dialog.
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
              SizedBox(width: 10),
              Text('Submission Received', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          content: const Text(
            'Thank you! Our team will review your car details and contact you shortly.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sell Your Car'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(_makeController, 'Make', Icons.directions_car_filled),
                const SizedBox(height: 12),
                _buildTextField(_modelController, 'Model', Icons.directions_car_filled),
                const SizedBox(height: 12),
                _buildTextField(_yearController, 'Year', Icons.calendar_today, keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _buildTextField(_priceController, 'Price (USD)', Icons.attach_money, keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _buildTextField(_descriptionController, 'Description', Icons.notes, maxLines: 4),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Submit',
                  onPressed: _submit,
                  gradient: AppColors.primaryGradient,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) => (value == null || value.isEmpty) ? 'Please enter $label' : null,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        labelText: label,
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
    );
  }
}
