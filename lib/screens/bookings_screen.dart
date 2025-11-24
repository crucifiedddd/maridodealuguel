import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'chat_screen.dart';
import '../models/service.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  static const routeName = '/bookings';

  Future<void> _cancelBooking(
    BuildContext context,
    String bookingId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      messenger.showSnackBar(
        const SnackBar(content: Text('Agendamento cancelado.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao cancelar: $e')),
      );
    }
  }

  String _formatDate(dynamic rawDate) {
    try {
      DateTime dt;

      if (rawDate is Timestamp) {
        dt = rawDate.toDate();
      } else if (rawDate is DateTime) {
        dt = rawDate;
      } else if (rawDate is String) {
        dt = DateTime.parse(rawDate);
      } else {
        return '---';
      }

      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return '---';
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.redAccent;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.teal;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'accepted':
        return 'Aceito';
      case 'rejected':
        return 'Recusado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Pendente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final stream = FirebaseFirestore.instance
        .collection('bookings')
        .where('clientId', isEqualTo: uid)
        .orderBy('dateTime', descending: true)
        .snapshots();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal.withOpacity(0.08),
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
                  child: Text('Você ainda não possui agendamentos.'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final d = docs[i];
                  final raw = d.data() as Map<String, dynamic>;
                  final bookingId = d.id;

                  final status = (raw['status'] ?? 'pending') as String;
                  final statusColor = _statusColor(status);

                  final service = Service(
                    id: (raw['serviceId'] ?? '') as String,
                    name: (raw['serviceName'] ?? 'Serviço') as String,
                    description: (raw['serviceDescription'] ?? '') as String,
                    basePrice: (raw['price'] ?? 0).toDouble(),
                    icon: (raw['serviceIcon'] ?? '🛠️') as String,
                    active: (raw['serviceActive'] ?? true) as bool,
                    order: (raw['serviceOrder'] ?? 0) as int,
                  );

                  final dateLabel = _formatDate(raw['dateTime']);
                  final priceText = (raw['price'] ?? service.basePrice)
                      .toDouble()
                      .toStringAsFixed(2);

                  final providerId = (raw['providerId'] ?? '') as String;
                  final providerName =
                      (raw['providerName'] ?? 'Prestador') as String;

                  final canCancel = status == 'pending' || status == 'accepted';

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
                          // topo
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  service.name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _statusLabel(status),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 15, color: Colors.grey.shade700),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Data: $dateLabel',
                                  style: TextStyle(color: Colors.grey.shade800),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          Text(
                            'Valor: R\$ $priceText',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                            ),
                          ),

                          const SizedBox(height: 14),

                          if (canCancel)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _cancelBooking(context, bookingId),
                                icon: const Icon(Icons.block, size: 18),
                                label: const Text('Cancelar agendamento'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey.shade800,
                                  side: BorderSide(color: Colors.grey.shade400),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),

                          if (providerId.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        bookingId: bookingId,
                                        clientId: uid,
                                        providerId: providerId,
                                        otherName: providerName,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.chat_bubble_outline,
                                    size: 18),
                                label: const Text('Chat'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.teal,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
