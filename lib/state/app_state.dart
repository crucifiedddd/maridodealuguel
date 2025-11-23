import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/booking.dart';

class AppState extends ChangeNotifier {
  AppUser? currentUser;

  final List<Booking> _bookings = [];
  List<Booking> get bookings => List.unmodifiable(_bookings);

  bool _servicesChecked = false;

  // =========================
  // USUÁRIO
  // =========================
  void setCurrentUser(AppUser? user) {
    currentUser = user;
    notifyListeners();
  }

  Future<void> loadUserProfile(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (snap.exists && snap.data() != null) {
      currentUser = AppUser.fromMap(snap.id, snap.data()!);
    } else {
      currentUser = null;
    }

    notifyListeners();
  }

  // =========================
  // SERVIÇOS (SEED)
  // =========================

  Future<void> seedServices() async {
    final db = FirebaseFirestore.instance;
    final col = db.collection('services');

    final items = <Map<String, dynamic>>[
      {
        'id': 'montagem_moveis',
        'name': 'Montagem de Móveis',
        'description': 'Montagem e desmontagem de móveis residenciais.',
        'basePrice': 100.0,
        'icon': '🛠️',
        'active': true,
        'order': 1,
      },
      {
        'id': 'pintura',
        'name': 'Pintura',
        'description': 'Pintura interna/externa, retoques, massa corrida.',
        'basePrice': 150.0,
        'icon': '🎨',
        'active': true,
        'order': 2,
      },
      {
        'id': 'encanador',
        'name': 'Encanador',
        'description':
            'Vazamentos, troca de registros, instalação de pias/torneiras.',
        'basePrice': 120.0,
        'icon': '🔧',
        'active': true,
        'order': 3,
      },
      {
        'id': 'limpeza_pesada',
        'name': 'Limpeza Pesada',
        'description': 'Pós-obra, faxina pesada, organização.',
        'basePrice': 150.0,
        'icon': '🧹',
        'active': true,
        'order': 4,
      },
      {
        'id': 'eletricista',
        'name': 'Eletricista',
        'description': 'Tomadas, luminárias, disjuntores e reparos.',
        'basePrice': 130.0,
        'icon': '🔌',
        'active': true,
        'order': 5,
      },
    ];

    final batch = db.batch();

    for (final s in items) {
      final doc = col.doc(s['id'] as String);
      batch.set(doc, {
        'name': s['name'],
        'description': s['description'],
        'basePrice': s['basePrice'],
        'icon': s['icon'],
        'active': s['active'],
        'order': s['order'],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> ensureDefaultServices() async {
    if (_servicesChecked) return;
    _servicesChecked = true;
    await seedServices();
  }

  // =========================
  // BOOKINGS
  // =========================
  Future<void> loadBookings() async {
    if (currentUser == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: currentUser!.id)
        .orderBy('dateTime')
        .get();

    _bookings
      ..clear()
      ..addAll(snap.docs.map((d) => Booking.fromMap(d.id, d.data())));

    notifyListeners();
  }

  Future<void> addBooking(Booking booking) async {
    final data = booking.toMap()
      ..['userId'] = currentUser?.id
      ..['createdAt'] = FieldValue.serverTimestamp();

    final ref = FirebaseFirestore.instance.collection('bookings');
    final doc = await ref.add(data);

    _bookings.add(Booking.fromMap(doc.id, booking.toMap()));
    notifyListeners();
  }

  void clearBookings() {
    _bookings.clear();
    notifyListeners();
  }
}
