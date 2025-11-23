import 'package:intl/intl.dart';

import 'service.dart';

enum BookingStatus { pending, confirmed, done, canceled }

class Booking {
  final String id;
  final Service service;
  final DateTime dateTime;
  final String address;
  final String notes;
  final double price;
  final BookingStatus status;

  Booking({
    required this.id,
    required this.service,
    required this.dateTime,
    required this.address,
    required this.notes,
    required this.price,
    this.status = BookingStatus.pending,
  });

  String get formattedDate => DateFormat('dd/MM/yyyy HH:mm').format(dateTime);

  Map<String, dynamic> toMap() {
    return {
      // guardamos um "snapshot" do serviço no momento do agendamento
      'serviceId': service.id,
      'serviceName': service.name,
      'serviceDescription': service.description,
      'serviceBasePrice': service.basePrice,
      'serviceIcon': service.icon,

      'dateTime': dateTime.toIso8601String(),
      'address': address,
      'notes': notes,
      'price': price,
      'status': status.name,
    };
  }

  /// Constrói a partir de um documento Firestore
  factory Booking.fromMap(String id, Map<String, dynamic> map) {
    final service = Service(
      id: (map['serviceId'] ?? '-') as String,
      name: (map['serviceName'] ?? '') as String,
      description: (map['serviceDescription'] ?? '') as String,
      basePrice: _toDouble(map['serviceBasePrice']),
      icon: (map['serviceIcon'] ?? '🛠️') as String,
      active: true,
      order: 0,
    );

    return Booking(
      id: id,
      service: service,
      dateTime:
          DateTime.tryParse((map['dateTime'] ?? '') as String) ??
          DateTime.now(),
      address: (map['address'] ?? '') as String,
      notes: (map['notes'] ?? '') as String,
      price: _toDouble(map['price']),
      status: _parseStatus(map['status']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v is int) return v.toDouble();
    if (v is double) return v;
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static BookingStatus _parseStatus(dynamic v) {
    if (v is String) {
      switch (v) {
        case 'pending':
          return BookingStatus.pending;
        case 'confirmed':
          return BookingStatus.confirmed;
        case 'done':
          return BookingStatus.done;
        case 'canceled':
          return BookingStatus.canceled;
      }
    }
    return BookingStatus.pending;
  }
}
