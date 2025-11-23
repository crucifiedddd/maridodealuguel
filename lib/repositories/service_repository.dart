import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service.dart';

class ServiceRepository {
  final _col = FirebaseFirestore.instance.collection('services');

  /// Stream de TODOS os serviços, ordenados se o campo "order" existir
  Stream<List<Service>> streamAll() {
    // Se a coleção tiver o campo "order", essa query funciona;
    // se você ainda não criou índices, o Firestore vai pedir um.
    final query = _col.orderBy('order', descending: false);

    return query.snapshots().map((snap) {
      return snap.docs.map((d) => Service.fromMap(d.id, d.data())).toList();
    });
  }
}
