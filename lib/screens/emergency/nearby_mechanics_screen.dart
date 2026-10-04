import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/custom_button.dart';

class NearbyMechanicsScreen extends StatelessWidget {
  const NearbyMechanicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Temporary mechanic data.
    // Later this will come from the Django backend.
    final mechanics = [
      {
        'name': 'Sharma Auto Garage',
        'rating': '4.8',
        'distance': '1.2 km',
        'phone': '+91 98765 43210',
      },
      {
        'name': 'Mumbai Motor Works',
        'rating': '4.6',
        'distance': '2.1 km',
        'phone': '+91 98765 12345',
      },
      {
        'name': 'City Bike & Car Service',
        'rating': '4.5',
        'distance': '2.8 km',
        'phone': '+91 99887 66554',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Mechanics'),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // LOCATION HEADER
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 28,
                    ),

                    SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          SizedBox(height: 4),

                          Text(
                            'Location detected successfully',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Mechanics Near You',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Select a mechanic to request emergency assistance.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 20),

              // MECHANIC LIST
              ...mechanics.map(
                    (mechanic) => _mechanicCard(
                  context,
                  name: mechanic['name']!,
                  rating: mechanic['rating']!,
                  distance: mechanic['distance']!,
                  phone: mechanic['phone']!,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Mechanic availability and real-time distance will be connected to the MotoMate backend later.',
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
    );
  }

  Widget _mechanicCard(
      BuildContext context, {
        required String name,
        required String rating,
        required String distance,
        required String phone,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MECHANIC INFORMATION
          Row(
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.build_circle_outlined,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 17,
                        ),

                        const SizedBox(width: 4),

                        Text(
                          rating,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(width: 14),

                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.textSecondary,
                          size: 17,
                        ),

                        const SizedBox(width: 3),

                        Text(
                          distance,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          const Divider(),

          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(
                Icons.phone_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),

              const SizedBox(width: 8),

              Text(
                phone,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // REQUEST HELP BUTTON
          CustomButton(
            text: 'Request Emergency Help',
            icon: Icons.warning_amber_rounded,
            onPressed: () {
              _showRequestConfirmation(
                context,
                name,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showRequestConfirmation(
      BuildContext context,
      String mechanicName,
      ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Request Emergency Help?'),
          content: Text(
            'You are about to request emergency assistance from $mechanicName.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Emergency request sent to $mechanicName.',
                    ),
                  ),
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}