// lib/dev_seed.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Seed de desenvolvimento:
/// - Garante catálogo de serviços em `services`
/// - Marca o usuário atual como prestador (`isProvider: true`)
/// - Cria competências em `provider_services`
/// - Cria 2 bookings de exemplo em `bookings`
///
/// ⚠ Use apenas em ambiente de desenvolvimento.
Future<void> runDevSeed() async {
  final auth = FirebaseAuth.instance;
  final db = FirebaseFirestore.instance;

  final user = auth.currentUser;
  if (user == null) {
    throw Exception(
      'Nenhum usuário autenticado. Faça login antes de rodar o seed.',
    );
  }

  final uid = user.uid;

  // =========================
  // 1) Catálogo de serviços
  // =========================
  final services = <Map<String, dynamic>>[
    {
      'id': 'montagem_moveis',
      'name': 'Montagem de Móveis',
      'description': 'Montagem e desmontagem de móveis residenciais.',
      'basePrice': 100.0,
      'icon': '🛠️',
      'order': 1,
    },
    {
      'id': 'pintura',
      'name': 'Pintura',
      'description': 'Pintura interna/externa, retoques, massa corrida.',
      'basePrice': 150.0,
      'icon': '🎨',
      'order': 2,
    },
    {
      'id': 'encanador',
      'name': 'Encanador',
      'description':
          'Vazamentos, troca de registros, instalação de pias/torneiras.',
      'basePrice': 120.0,
      'icon': '🔧',
      'order': 3,
    },
    {
      'id': 'limpeza_pesada',
      'name': 'Limpeza Pesada',
      'description': 'Pós-obra, faxina pesada, organização.',
      'basePrice': 150.0,
      'icon': '🧹',
      'order': 4,
    },
    {
      'id': 'eletricista',
      'name': 'Eletricista',
      'description': 'Tomadas, luminárias, disjuntores e reparos.',
      'basePrice': 130.0,
      'icon': '🔌',
      'order': 5,
    },
  ];

  final batch = db.batch();
  final servicesCol = db.collection('services');

  for (final s in services) {
    final doc = servicesCol.doc(s['id'] as String);
    batch.set(doc, {
      'name': s['name'],
      'description': s['description'],
      'basePrice': s['basePrice'],
      'icon': s['icon'],
      'active': true,
      'order': s['order'],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // =========================
  // 2) Usuário logado como prestador
  // =========================
  final userDoc = db.collection('users').doc(uid);
  batch.set(userDoc, {
    'name': user.displayName ?? 'Prestador Demo',
    'email': user.email,
    'phone': user.phoneNumber ?? '',
    'isProvider': true,
    'role': 'provider',
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  // =========================
  // 3) Competências do prestador
  // =========================
  final providerServicesCol = db.collection('provider_services');

  final providerServices = [
    {
      'serviceId': 'montagem_moveis',
      'enabled': true,
      'customPrice': 110.0,
      'note': 'Montagem rápida e cuidadosa.',
    },
    {
      'serviceId': 'pintura',
      'enabled': true,
      'customPrice': 160.0,
      'note': 'Pintura interna e externa.',
    },
    {
      'serviceId': 'encanador',
      'enabled': false,
      'customPrice': 0.0,
      'note': '',
    },
  ];

  for (final ps in providerServices) {
    final serviceId = ps['serviceId'] as String;
    final docId = '${uid}_$serviceId';
    final doc = providerServicesCol.doc(docId);

    batch.set(doc, {
      'providerId': uid,
      'serviceId': serviceId,
      'enabled': ps['enabled'],
      'customPrice': ps['customPrice'],
      'note': ps['note'],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Aplica services + user + provider_services
  await batch.commit();

  // =========================
  // 4) Bookings de exemplo
  // =========================
  final bookingsCol = db.collection('bookings');

  // Chamado pendente
  await bookingsCol.add({
    'userId': 'demo_client_1',
    'clientName': 'Cliente Demo 1',
    'providerId': uid,
    'serviceId': 'montagem_moveis',
    'serviceName': 'Montagem de Móveis',
    'serviceDescription': 'Montagem e desmontagem de móveis residenciais.',
    'serviceIcon': '🛠️',
    'price': 110.0,
    'address': 'Rua das Flores, 123 - Centro',
    'notes': 'Montar guarda-roupa e rack.',
    'dateTime': DateTime.now().add(const Duration(days: 2)),
    'createdAt': FieldValue.serverTimestamp(),
    'acceptedAt': null,
    'status': 'pending',
  });

  // Chamado aceito
  await bookingsCol.add({
    'userId': 'demo_client_2',
    'clientName': 'Cliente Demo 2',
    'providerId': uid,
    'serviceId': 'pintura',
    'serviceName': 'Pintura',
    'serviceDescription': 'Pintura interna/externa, retoques, massa corrida.',
    'serviceIcon': '🎨',
    'price': 160.0,
    'address': 'Av. Brasil, 456 - Bairro Novo',
    'notes': 'Pintar sala e corredor.',
    'dateTime': DateTime.now().add(const Duration(days: 5)),
    'createdAt': FieldValue.serverTimestamp(),
    'acceptedAt': FieldValue.serverTimestamp(),
    'status': 'accepted',
  });

  // ignore: avoid_print
  print('✅ Seed de desenvolvimento concluído para o usuário $uid');
}
