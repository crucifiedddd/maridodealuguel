// lib/models/service.dart
class Service {
  final String id;
  final String name;
  final String description;
  final double basePrice;
  final String icon;
  final bool active;
  final int order;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.icon,
    required this.active,
    required this.order,
  });

  factory Service.fromMap(String id, Map<String, dynamic> d) => Service(
    id: id,
    name: (d['name'] ?? '') as String,
    description: (d['description'] ?? '') as String,
    basePrice: (d['basePrice'] is int)
        ? (d['basePrice'] as int).toDouble()
        : (d['basePrice'] ?? 0.0) as double,
    icon: (d['icon'] ?? '🧰') as String,
    active: (d['active'] ?? true) as bool,
    order: (d['order'] ?? 0) as int,
  );
}
