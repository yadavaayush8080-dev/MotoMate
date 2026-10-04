import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // ============================================================
  // LOGIN
  // ============================================================

  static Future<Map<String, dynamic>> login(
      String email,
      String password,
      ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login/'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    debugPrint('Login Status: ${response.statusCode}');
    debugPrint('Login Response: ${response.body}');

    return jsonDecode(response.body);
  }

  // ============================================================
  // REGISTER
  // ============================================================

  static Future<Map<String, dynamic>> register(
      String name,
      String email,
      String phone,
      String password,
      ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/register/'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      }),
    );

    debugPrint('Register Status: ${response.statusCode}');
    debugPrint('Register Response: ${response.body}');

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateUserProfile({
    required int userId,
    required String name,
    required String email,
    required String phone,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/update/$userId/'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
      }),
    );

    debugPrint(
      'Update Profile Status: ${response.statusCode}',
    );

    debugPrint(
      'Update Profile Response: ${response.body}',
    );

    return jsonDecode(response.body);
  }

  // ============================================================
  // SAVE VEHICLE
  // ============================================================

  static Future<Map<String, dynamic>> saveVehicle({
    required int userId,
    required String brand,
    required String model,
    required String registrationNumber,
    required String fuelType,
    required int vehicleYear,
    required int currentKilometers,
    String? insuranceExpiry,
    String? pucExpiry,
    String? lastServiceDate,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/vehicle/'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
        'brand': brand,
        'model': model,
        'registration_number': registrationNumber,
        'fuel_type': fuelType,
        'vehicle_year': vehicleYear,
        'current_kilometers': currentKilometers,
        'insurance_expiry': insuranceExpiry,
        'puc_expiry': pucExpiry,
        'last_service_date': lastServiceDate,
      }),
    );

    debugPrint('Save Vehicle Status: ${response.statusCode}');
    debugPrint('Save Vehicle Response: ${response.body}');

    return jsonDecode(response.body);
  }

  // ============================================================
  // GET USER VEHICLE
  // ============================================================

  static Future<Map<String, dynamic>> getUserVehicle(
      int userId,
      ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/vehicle/$userId/'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    debugPrint('Vehicle Status: ${response.statusCode}');
    debugPrint('Vehicle API Response: ${response.body}');

    return jsonDecode(response.body);
  }

  // ============================================================
  // UPDATE VEHICLE
  // ============================================================

  static Future<Map<String, dynamic>> updateVehicle({
    required int vehicleId,
    required String brand,
    required String model,
    required String registrationNumber,
    required String fuelType,
    required int vehicleYear,
    required int currentKilometers,
    String? insuranceExpiry,
    String? pucExpiry,
    String? lastServiceDate,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/vehicle/update/$vehicleId/'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'brand': brand,
        'model': model,
        'registration_number': registrationNumber,
        'fuel_type': fuelType,
        'vehicle_year': vehicleYear,
        'current_kilometers': currentKilometers,
        'insurance_expiry': insuranceExpiry,
        'puc_expiry': pucExpiry,
        'last_service_date': lastServiceDate,
      }),
    );

    debugPrint('Update Vehicle Status: ${response.statusCode}');
    debugPrint('Update Vehicle Response: ${response.body}');

    return jsonDecode(response.body);
  }

  // ============================================================
  // EMERGENCY REPAIR
  // ============================================================

  static Future<Map<String, dynamic>> createEmergencyRequest({
    required int userId,
    required int vehicleId,
    required double latitude,
    required double longitude,
    required String problemDescription,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/emergency/'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
        'vehicle_id': vehicleId,
        'latitude': latitude,
        'longitude': longitude,
        'problem_description': problemDescription,
      }),
    );

    debugPrint('Emergency Status: ${response.statusCode}');
    debugPrint('Emergency Response: ${response.body}');

    return jsonDecode(response.body);
  }

  // ============================================================
  // GET EMERGENCY REQUEST
  // ============================================================

  static Future<Map<String, dynamic>> getEmergencyRequest(
      int requestId,
      ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/emergency/$requestId/'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    debugPrint('Emergency Request Status: ${response.statusCode}');
    debugPrint('Emergency Request Response: ${response.body}');

    return jsonDecode(response.body);
  }

  // ============================================================
  // HOME SERVICE BOOKING
  // ============================================================

  static Future<Map<String, dynamic>> createServiceRequest({
    required int userId,
    required int vehicleId,
    required String serviceType,
    String? preferredDate,
    String? preferredTime,
    String? address,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/service/'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
        'vehicle_id': vehicleId,
        'service_type': serviceType,
        'preferred_date': preferredDate,
        'preferred_time': preferredTime,
        'address': address,
        'notes': notes,
      }),
    );

    debugPrint('Service Status: ${response.statusCode}');
    debugPrint('Service Response: ${response.body}');

    return jsonDecode(response.body);
  }

  // ============================================================
  // GET NOTIFICATIONS
  // ============================================================

  static Future<Map<String, dynamic>> getNotifications(
      int userId,
      ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/$userId/'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    debugPrint('Notifications Status: ${response.statusCode}');
    debugPrint('Notifications Response: ${response.body}');

    return jsonDecode(response.body);
  }

  // ============================================================
  // GET VEHICLE HEALTH
  // ============================================================

  static Future<Map<String, dynamic>> getVehicleHealth(
      int userId,
      ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/vehicle-health/$userId/'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    debugPrint('Vehicle Health Status: ${response.statusCode}');
    debugPrint('Vehicle Health Response: ${response.body}');

    return jsonDecode(response.body);
  }

  // ============================================================
  // AI ASSISTANT
  // ============================================================

  static Future<Map<String, dynamic>> askAiAssistant({
    required int userId,
    required String question,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai-assistant/'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
        'message': question,
      }),
    );

    debugPrint('AI Status: ${response.statusCode}');
    debugPrint('AI Response: ${response.body}');

    return jsonDecode(response.body);
  }

  // ============================================================
  // MECHANIC LOGIN
  // ============================================================

  static Future<Map<String, dynamic>> mechanicLogin(
      String email,
      String password,
      ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mechanic-login/'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    debugPrint('Mechanic Login Status: ${response.statusCode}');
    debugPrint('Mechanic Login Response: ${response.body}');

    return jsonDecode(response.body);
  }
  // ============================================================
  // GET MECHANIC EMERGENCY REQUESTS
  // ============================================================

  static Future<Map<String, dynamic>> getMechanicEmergencyRequests(
      int mechanicId,
      ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/mechanic/$mechanicId/emergency-requests/'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    debugPrint(
      'Mechanic Emergency Requests Status: ${response.statusCode}',
    );
    debugPrint(
      'Mechanic Emergency Requests Response: ${response.body}',
    );

    return jsonDecode(response.body);
  }

  // ============================================================
  // UPDATE MECHANIC EMERGENCY REQUEST STATUS
  // ============================================================

  static Future<Map<String, dynamic>> updateMechanicEmergencyRequestStatus({
    required int requestId,
    required int mechanicId,
    required String status,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/emergency/$requestId/update-status/'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'mechanic_id': mechanicId,
        'status': status,
      }),
    );

    debugPrint(
      'Update Emergency Request Status: ${response.statusCode}',
    );
    debugPrint(
      'Update Emergency Request Response: ${response.body}',
    );

    return jsonDecode(response.body);
  }
  // ============================================================
  // GET MECHANIC HOME SERVICE REQUESTS
  // ============================================================

  static Future<Map<String, dynamic>> getMechanicServiceRequests(
      int mechanicId,
      ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/mechanic/$mechanicId/service-requests/'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    debugPrint(
      'Mechanic Service Requests Status: ${response.statusCode}',
    );

    debugPrint(
      'Mechanic Service Requests Response: ${response.body}',
    );

    return jsonDecode(response.body);
  }

  // ============================================================
  // UPDATE MECHANIC HOME SERVICE REQUEST STATUS
  // ============================================================

  static Future<Map<String, dynamic>> updateMechanicServiceRequestStatus({
    required int requestId,
    required int mechanicId,
    required String status,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/service/$requestId/update-status/'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'mechanic_id': mechanicId,
        'status': status,
      }),
    );

    debugPrint(
      'Update Service Request Status: ${response.statusCode}',
    );

    debugPrint(
      'Update Service Request Response: ${response.body}',
    );

    return jsonDecode(response.body);
  }

  // ============================================================
// GET MECHANIC NOTIFICATIONS
// ============================================================

  static Future<Map<String, dynamic>> getMechanicNotifications(
      int mechanicId,
      ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/mechanic/$mechanicId/notifications/'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    debugPrint(
      'Mechanic Notifications Status: ${response.statusCode}',
    );
    debugPrint(
      'Mechanic Notifications Response: ${response.body}',
    );

    return jsonDecode(response.body);
  }
}