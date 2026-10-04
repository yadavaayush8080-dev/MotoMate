class MechanicSession {
  static int? mechanicId;
  static String? name;
  static String? email;
  static String? phone;
  static String? shopName;
  static String? address;
  static double? rating;
  static bool? isAvailable;

  static void setMechanic(Map<String, dynamic> mechanic) {
    mechanicId = int.tryParse(
      mechanic['id']?.toString() ?? '',
    );

    name = mechanic['name']?.toString();
    email = mechanic['email']?.toString();
    phone = mechanic['phone']?.toString();
    shopName = mechanic['shop_name']?.toString();
    address = mechanic['address']?.toString();

    rating = double.tryParse(
      mechanic['rating']?.toString() ?? '',
    );

    final available = mechanic['is_available'];

    if (available is bool) {
      isAvailable = available;
    } else if (available != null) {
      isAvailable = available.toString().toLowerCase() == 'true';
    }
  }

  static void clear() {
    mechanicId = null;
    name = null;
    email = null;
    phone = null;
    shopName = null;
    address = null;
    rating = null;
    isAvailable = null;
  }
}