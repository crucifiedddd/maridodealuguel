// lib/models/app_user.dart
class AppUser {
  final String id;
  final String email;
  final String? name;
  final String? phone;
  final bool isProvider;
  final String role;

  AppUser({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.isProvider = false,
    this.role = 'client',
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      id: id,
      email: (map['email'] ?? '') as String,
      name: map['name'] as String?,
      phone: map['phone'] as String?,
      isProvider: map['isProvider'] as bool? ?? false,
      role:
          map['role'] as String? ??
          ((map['isProvider'] == true) ? 'provider' : 'client'),
    );
  }

  get rating => null;
}
