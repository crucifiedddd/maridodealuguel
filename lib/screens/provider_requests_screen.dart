import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/service.dart';
import 'chat_screen.dart';

class ProviderRequestsScreen extends StatelessWidget {
  const ProviderRequestsScreen({super.key});

  static const routeName = '/provider-requests';

  /// Atualiza status do chamado (aceitar / recusar / cancelar)
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
            status == 'accepted'
                ? 'Chamado aceito.'
                : status == 'rejected'
                    ? 'Chamado recusado.'
                    : status == 'cancelled'
                        ? 'Chamado cancelado.'
                        : 'Status atualizado.',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao atualizar chamado: $e')),
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
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
            child: Column(
              children: [
                const SizedBox(height: 6),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Chamados',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ====== Tabs com contadores ======
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _RequestsTabs(),
                ),

                const SizedBox(height: 6),

                // ====== Conteúdo ======
                Expanded(
                  child: TabBarView(
                    children: [
                      _RequestsList(
                        status: 'pending',
                        showActions: true,
                        showCancel: false,
                        formatDate: _formatDate,
                        onUpdateStatus: _updateStatus,
                      ),
                      _RequestsList(
                        status: 'accepted',
                        showActions: false,
                        showCancel: true, // ✅ aqui aparece Cancelar
                        formatDate: _formatDate,
                        onUpdateStatus: _updateStatus,
                      ),
                      _RequestsList(
                        status: 'rejected',
                        showActions: false,
                        showCancel: false,
                        formatDate: _formatDate,
                        onUpdateStatus: _updateStatus,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Barra de abas com contadores (centralizada)
class _RequestsTabs extends StatelessWidget {
  const _RequestsTabs();

  Stream<int> _countByStatus(String status) {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('status', isEqualTo: status)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Widget _tabItem({
    required IconData icon,
    required String label,
    required Color color,
    required Stream<int> countStream,
  }) {
    return StreamBuilder<int>(
      stream: countStream,
      builder: (_, snap) {
        final count = snap.data ?? 0;

        return FittedBox(
          // ✅ evita overflow
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final teal = Colors.teal;
    final green = Colors.green;
    final red = Colors.redAccent;

    return TabBar(
      isScrollable: false,
      indicatorColor: teal,
      labelColor: teal,
      unselectedLabelColor: Colors.grey.shade600,
      tabs: [
        Tab(
          child: _tabItem(
            icon: Icons.hourglass_bottom_rounded,
            label: 'Pendentes',
            color: teal,
            countStream: _countByStatus('pending'),
          ),
        ),
        Tab(
          child: _tabItem(
            icon: Icons.check_circle_outline,
            label: 'Aceitos',
            color: green,
            countStream: _countByStatus('accepted'),
          ),
        ),
        Tab(
          child: _tabItem(
            icon: Icons.cancel_outlined,
            label: 'Recusados',
            color: red,
            countStream: _countByStatus('rejected'),
          ),
        ),
      ],
    );
  }
}

/// Lista por status
class _RequestsList extends StatelessWidget {
  const _RequestsList({
    required this.status,
    required this.showActions,
    required this.showCancel,
    required this.formatDate,
    required this.onUpdateStatus,
  });

  final String status;
  final bool showActions;
  final bool showCancel;
  final String Function(dynamic rawDate) formatDate;
  final Future<void> Function(
    BuildContext context,
    String bookingId,
    String newStatus,
  ) onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('bookings')
        .where('status', isEqualTo: status)
        .orderBy('dateTime')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
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
                'Erro ao carregar chamados:\n${snap.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                status == 'pending'
                    ? 'Nenhum chamado pendente.'
                    : status == 'accepted'
                        ? 'Nenhum chamado aceito.'
                        : 'Nenhum chamado recusado.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i];
            final raw = d.data() as Map<String, dynamic>;
            final bookingId = d.id;

            final service = Service(
              id: (raw['serviceId'] ?? '') as String,
              name: (raw['serviceName'] ?? 'Serviço') as String,
              description: (raw['serviceDescription'] ?? '') as String,
              basePrice: (raw['price'] ?? 0).toDouble(),
              icon: (raw['serviceIcon'] ?? '🛠️') as String,
              active: (raw['serviceActive'] ?? true) as bool,
              order: (raw['serviceOrder'] ?? 0) as int,
            );

            final clientName =
                (raw['clientName'] ?? 'Cliente') as String; // ✅ real
            final dateLabel = formatDate(raw['dateTime']);

            final providerId = (raw['providerId'] ?? '') as String;
            final clientId = (raw['clientId'] ?? '') as String;

            return _RequestCard(
              service: service,
              clientName: clientName,
              dateLabel: dateLabel,
              status: status,
              showActions: showActions,
              showCancel: showCancel,
              onReject: () => onUpdateStatus(context, bookingId, 'rejected'),
              onAccept: () => onUpdateStatus(context, bookingId, 'accepted'),
              onCancel: () => onUpdateStatus(context, bookingId, 'cancelled'),
              onChat: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      bookingId: bookingId,
                      clientId: clientId,
                      providerId: providerId,
                      otherName: clientName,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.service,
    required this.clientName,
    required this.dateLabel,
    required this.status,
    required this.showActions,
    required this.showCancel,
    required this.onReject,
    required this.onAccept,
    required this.onCancel,
    required this.onChat,
  });

  final Service service;
  final String clientName;
  final String dateLabel;
  final String status;
  final bool showActions;
  final bool showCancel;
  final VoidCallback onReject;
  final VoidCallback onAccept;
  final VoidCallback onCancel;
  final VoidCallback onChat;

  Color _statusColor() {
    switch (status) {
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

  String _statusLabel() {
    switch (status) {
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
    final priceText = service.basePrice.toStringAsFixed(2);
    final statusColor = _statusColor();

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
            // Topo com título + status chip
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
                    _statusLabel(),
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
                Icon(Icons.person_outline,
                    size: 16, color: Colors.grey.shade700),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Cliente: $clientName',
                    style: TextStyle(color: Colors.grey.shade800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

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
            const SizedBox(height: 8),

            Text(
              'Valor: R\$ $priceText',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
              ),
            ),

            const SizedBox(height: 14),

            if (showActions) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Recusar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onAccept,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Aceitar'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],

            if (showCancel) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.block, size: 18),
                  label: const Text('Cancelar chamado'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade800,
                    side: BorderSide(color: Colors.grey.shade400),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onChat,
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Chat'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.teal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
