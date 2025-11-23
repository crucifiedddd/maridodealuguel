import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  static const routeName = '/bookings';

  String _formatDate(dynamic ts) {
    if (ts == null) return '—';
    if (ts is Timestamp) {
      return DateFormat('dd/MM/yyyy • HH:mm').format(ts.toDate());
    }
    if (ts is DateTime) {
      return DateFormat('dd/MM/yyyy • HH:mm').format(ts);
    }
    return ts.toString();
  }

  String _formatPrice(dynamic value) {
    final v = (value ?? 0).toDouble();
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(v);
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'accepted':
        return 'Aceito';
      case 'rejected':
        return 'Recusado';
      case 'done':
        return 'Concluído';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'done':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(child: Text('Usuário não autenticado.'));
    }

    // ✅ OPÇÃO A APLICADA: usando userId
    final stream = FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: uid)
        .orderBy('dateTime', descending: true)
        .snapshots();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.teal.withOpacity(0.05),
            Colors.white,
            Colors.white,
          ],
        ),
      ),
      child: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Erro ao carregar agendamentos:\n${snap.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final docs = snap.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'Você ainda não possui agendamentos.',
                  textAlign: TextAlign.center,
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final raw = docs[i].data() as Map<String, dynamic>;

                final serviceName = raw['serviceName'] ?? 'Serviço';
                final dateTime = raw['dateTime'];
                final providerName = raw['providerName'] ?? 'Prestador';
                final address = raw['address'] ?? raw['clientAddress'] ?? '—';
                final price = raw['price'] ?? raw['basePrice'] ?? 0;
                final status = raw['status'] ?? 'pending';

                final statusColor = _statusColor(status);

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título + status
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                serviceName,
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.35),
                                ),
                              ),
                              child: Text(
                                _statusLabel(status),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Data
                        Row(
                          children: [
                            Icon(Icons.schedule,
                                size: 16, color: Colors.grey.shade700),
                            const SizedBox(width: 6),
                            Text(_formatDate(dateTime)),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Prestador
                        Row(
                          children: [
                            Icon(Icons.person_outline,
                                size: 16, color: Colors.grey.shade700),
                            const SizedBox(width: 6),
                            Expanded(child: Text(providerName)),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Endereço
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.place_outlined,
                                size: 16, color: Colors.grey.shade700),
                            const SizedBox(width: 6),
                            Expanded(child: Text(address)),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Valor
                        Row(
                          children: [
                            Icon(Icons.attach_money,
                                size: 16, color: Colors.grey.shade700),
                            const SizedBox(width: 4),
                            Text(
                              _formatPrice(price),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
