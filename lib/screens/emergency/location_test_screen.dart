import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationTestScreen extends StatefulWidget {
  const LocationTestScreen({super.key});

  @override
  State<LocationTestScreen> createState() => _LocationTestScreenState();
}

class _LocationTestScreenState extends State<LocationTestScreen> {
  String locationMessage = 'Location not checked yet.';
  bool isLoading = false;

  Future<void> _getLocation() async {
    setState(() {
      isLoading = true;
      locationMessage = 'Checking location...';
    });

    try {
      // Check whether location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        setState(() {
          locationMessage = 'Location service is OFF.';
          isLoading = false;
        });
        return;
      }

      // Check permission
      LocationPermission permission =
      await Geolocator.checkPermission();

      // Request permission if not already granted
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // Permission denied
      if (permission == LocationPermission.denied) {
        setState(() {
          locationMessage = 'Location permission denied.';
          isLoading = false;
        });
        return;
      }

      // Permission permanently denied
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          locationMessage =
          'Location permission permanently denied.\n'
              'Please enable it from Android settings.';
          isLoading = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition();

      setState(() {
        locationMessage =
        'Location working successfully! 🎉\n\n'
            'Latitude: ${position.latitude}\n'
            'Longitude: ${position.longitude}\n\n'
            'Accuracy: ${position.accuracy.toStringAsFixed(2)} meters';

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        locationMessage = 'Error getting location:\n$e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.location_on,
              size: 80,
            ),

            const SizedBox(height: 30),

            const Text(
              'Test MotoMate Location',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              locationMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: isLoading ? null : _getLocation,
              icon: const Icon(Icons.my_location),
              label: Text(
                isLoading
                    ? 'Getting Location...'
                    : 'Get My Location',
              ),
            ),
          ],
        ),
      ),
    );
  }
}