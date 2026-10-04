class UserSession {
  static int? userId;
  static int? vehicleId; // Added vehicleId for emergency requests
  static String? name;
  static String? email;
  static String? phone;
  static String? role;

  static void setUser(Map<String, dynamic> user) {
    userId = user['id'];
    vehicleId = user['vehicle_id']; // Expect vehicle_id in user payload if available
    name = user['name'];
    email = user['email'];
    phone = user['phone'];
    role = user['role'];
  }

  static void clear() {
    userId = null;
    vehicleId = null;
    name = null;
    email = null;
    phone = null;
    role = null;
  }
}