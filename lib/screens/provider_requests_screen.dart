import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/service.dart';

class ProviderRequestsScreen extends StatefulWidget {
  const ProviderRequestsScreen({super.key});

  static const routeName = '/provider-requests';

  @override
  State<ProviderRequestsScreen> createState() => _ProviderRequestsScreenState();
}

class _ProviderRequestsScreenState extends State<ProviderRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _statuses = ['pending', 'accepted', 'rejected'];

  final Map<String, Color> _statusColor = {
    'pending': Colors.orange,
    'accepted': Colors.green,
    'rejected': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  // ------------ FORMATADORES ------------

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '---';
    if (ts is Timestamp) {
      final dt = ts.toDate();
      return DateFormat('dd/MM/yyyy • HH:mm').format(dt);
    }
    if (ts is DateTime) {
      return DateFormat('dd/MM/yyyy • HH:mm').format(ts);
    }
    return ts.toString();
  }

  String _formatPrice(double value) {
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    ).format(value);
  }

  // ------------ FIRESTORE ------------

  Stream<QuerySnapshot> _query(String status) {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('status', isEqualTo: status)
        .orderBy('dateTime')
        .snapshots();
  }

  Stream<int> _countStream(String status) {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> _updateStatus(
    BuildContext context,
    String bookingId,
    String status,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            status == 'accepted' ? 'Chamado aceito.' : 'Chamado recusado.',
          ),
        ),
      );

      if (status == 'accepted') _tabController.animateTo(1);
      if (status == 'rejected') _tabController.animateTo(2);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao atualizar chamado: $e')),
      );
    }
  }

  // ------------ UI ------------

  Widget _tabWithBadge({
    required String status,
    required String label,
    required IconData icon,
  }) {
    final color = _statusColor[status] ?? Colors.teal;

    return StreamBuilder<int>(
      stream: _countStream(status),
      builder: (context, snap) {
        final count = snap.data ?? 0;

        return Tab(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 6),
                Text(label),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: color.withOpacity(0.35)),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
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
  }

  Widget _buildList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: _query(status),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return Center(child: Text('Erro: ${snap.error}'));
        }

        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(
            child: Text(
              status == 'pending'
                  ? 'Nenhum chamado pendente no momento.\nVolte mais tarde.'
                  : status == 'accepted'
                      ? 'Nenhum chamado aceito ainda.'
                      : 'Nenhum chamado recusado.',
              textAlign: TextAlign.center,
            ),
          );
        }

        final docs = snap.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final raw = docs[i].data() as Map<String, dynamic>;
            final bookingId = docs[i].id;

            final service = Service(
              id: raw['serviceId'] ?? '',
              name: raw['serviceName'] ?? 'Serviço',
              description: raw['serviceDescription'] ?? '',
              basePrice: (raw['price'] ?? 0).toDouble(),
              icon: raw['serviceIcon'] ?? '🛠️',
              active: raw['serviceActive'] ?? true,
              order: raw['serviceOrder'] ?? 0,
            );

            final clientName = raw['clientName'] ?? 'Cliente';
            final formattedDate = _formatTimestamp(raw['dateTime']);
            final formattedPrice = _formatPrice(service.basePrice);

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("Cliente: $clientName"),
                    const SizedBox(height: 2),
                    Text("Data: $formattedDate"),
                    const SizedBox(height: 6),
                    Text(
                      "Valor: $formattedPrice",
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (status == 'pending') ...[
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.close,
                                color: Colors.redAccent),
                            label: const Text('Recusar'),
                            onPressed: () =>
                                _updateStatus(context, bookingId, 'rejected'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text('Aceitar'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () =>
                                _updateStatus(context, bookingId, 'accepted'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = _statuses[_tabController.index];
    final currentColor = _statusColor[currentStatus] ?? Colors.teal;

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
      child: Column(
        children: [
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            labelColor: currentColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: currentColor,
            tabs: [
              _tabWithBadge(
                status: 'pending',
                label: 'Pendentes',
                icon: Icons.schedule,
              ),
              _tabWithBadge(
                status: 'accepted',
                label: 'Aceitos',
                icon: Icons.check_circle,
              ),
              _tabWithBadge(
                status: 'rejected',
                label: 'Recusados',
                icon: Icons.cancel,
              ),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _statuses.map(_buildList).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
