import 'package:flutter/material.dart';

import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/home_service/home_service_screen.dart';
import '../../screens/home_service/booking_screen.dart';
import '../../screens/vehicle/vehicle_screen.dart';
import '../../screens/vehicle/vehicle_health_screen.dart';
import '../../screens/emergency/emergency_repair_screen.dart';
import '../../screens/emergency/location_test_screen.dart';
import '../../screens/emergency/nearby_mechanics_screen.dart';
import '../../screens/notifications/notification_screen.dart';
import '../../screens/ai/ai_assistant_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/auth/mechanic_login_screen.dart';
import '../../screens/mechanic/mechanic_dashboard_screen.dart';
import '../../screens/mechanic/mechanic_service_requests_screen.dart';
import '../../screens/car_sell/car_sell_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';

  static const String home = '/home';

  static const String vehicle = '/vehicle';
  static const String vehicleHealth = '/vehicle-health';

  static const String homeService = '/home-service';
  static const String booking = '/booking';

  static const String emergencyRepair = '/emergency-repair';
  static const String locationTest = '/location-test';
  static const String nearbyMechanics = '/nearby-mechanics';

  static const String notifications = '/notifications';

  static const String aiAssistant = '/ai-assistant';

  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';

  static const String mechanicLogin = '/mechanic-login';
  static const String mechanicDashboard = '/mechanic-dashboard';
  static const String mechanicServiceRequests = '/mechanic-service-requests';

  static const String carSell = '/car-sell';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    signup: (context) => const SignupScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    home: (context) => const HomeScreen(),
    vehicle: (context) => const VehicleScreen(),
    vehicleHealth: (context) => const VehicleHealthScreen(),
    homeService: (context) => const HomeServiceScreen(),
    booking: (context) => const BookingScreen(),
    emergencyRepair: (context) => const EmergencyRepairScreen(),
    locationTest: (context) => const LocationTestScreen(),
    nearbyMechanics: (context) => const NearbyMechanicsScreen(),
    notifications: (context) => const NotificationScreen(),
    aiAssistant: (context) => const AiAssistantScreen(),
    profile: (context) => const ProfileScreen(),
    editProfile: (context) => const EditProfileScreen(),
    mechanicLogin: (context) => const MechanicLoginScreen(),
    mechanicDashboard: (context) => const MechanicDashboardScreen(),
    mechanicServiceRequests: (context) => const MechanicServiceRequestsScreen(),
    carSell: (context) => const CarSellScreen(),
  };
}