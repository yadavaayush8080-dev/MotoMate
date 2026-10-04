import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../services/api_service.dart';
import '../../services/user_session.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: UserSession.name ?? '',
    );

    emailController = TextEditingController(
      text: UserSession.email ?? '',
    );

    phoneController = TextEditingController(
      text: UserSession.phone ?? '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();

    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final int? userId = UserSession.userId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID is required!'),
        ),
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String name = nameController.text.trim();
      final String email = emailController.text.trim();
      final String phone = phoneController.text.trim();

      debugPrint('Updating Profile User ID: $userId');
      debugPrint('New Name: $name');
      debugPrint('New Email: $email');
      debugPrint('New Phone: $phone');

      final result = await ApiService.updateUserProfile(
        userId: userId,
        name: name,
        email: email,
        phone: phone,
      );

      if (!mounted) {
        return;
      }

      debugPrint('Profile Update Result: $result');

      if (result['message'] ==
          'Profile updated successfully!') {
        final user = result['user'];

        // Update the current Flutter session
        UserSession.setUser(user);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profile updated successfully!',
            ),
          ),
        );

        Navigator.pop(
          context,
          {
            'name': UserSession.name ?? '',
            'email': UserSession.email ?? '',
            'phone': UserSession.phone ?? '',
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message']?.toString() ??
                  'Failed to update profile.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      debugPrint('Profile Update Error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to connect to the server: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 15),

                // PROFILE ICON
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color:
                      AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 20),

                // NAME
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(
                      Icons.person_outline,
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter your name';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // EMAIL
                TextFormField(
                  controller: emailController,
                  keyboardType:
                  TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter your email';
                    }

                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // PHONE
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 30),

                // SAVE BUTTON
                _isLoading
                    ? const Center(
                  child: CircularProgressIndicator(),
                )
                    : CustomButton(
                  text: 'Save Changes',
                  icon: Icons.save_outlined,
                  onPressed: _saveProfile,
                ),

                const SizedBox(height: 20),

                const Text(
                  'Your profile information will be securely updated in the MotoMate backend.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
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