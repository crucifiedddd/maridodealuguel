import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'chat_screen.dart';

class ProviderInboxScreen extends StatelessWidget {
  const ProviderInboxScreen({super.key});

  static const routeName = '/provider/inbox';

  String _formatTime(dynamic ts) {
    try {
      DateTime dt;
      if (ts is Timestamp) {
        dt = ts.toDate();
      } else if (ts is DateTime) {
        dt = ts;
      } else {
        return '';
      }
      return DateFormat('dd/MM HH:mm').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversas'),
      ),
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
            stream: FirebaseFirestore.instance
                .collection('chats')
                .where('participants', arrayContains: uid)
                .orderBy('lastTimestamp', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Erro ao carregar chats:\n${snap.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final docs = snap.data?.docs ?? [];

              if (docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Nenhuma conversa ainda.\n'
                      'Quando aceitar um chamado, o chat aparecerá aqui.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final d = docs[i];
                  final raw = d.data() as Map<String, dynamic>;
                  final chatId = d.id;

                  // Como prestador, o "outro" é o cliente
                  final otherName = (raw['clientName'] ??
                      raw['otherName'] ??
                      'Cliente') as String;

                  final lastMessage = (raw['lastMessage'] ?? '') as String;

                  final lastTime = _formatTime(raw['lastTimestamp']);

                  final bookingId = (raw['bookingId'] ?? chatId) as String;
                  final clientId = (raw['clientId'] ?? '') as String;
                  final providerId = (raw['providerId'] ?? uid) as String;

                  final unreadCount = (raw['unreadForProvider'] ?? 0) as int;

                  return _InboxTile(
                    otherName: otherName,
                    lastMessage: lastMessage,
                    lastTime: lastTime,
                    unreadCount: unreadCount,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            bookingId: bookingId,
                            clientId: clientId,
                            providerId: providerId,
                            otherName: otherName,
                          ),
                        ),
                      );
                    },
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

class _InboxTile extends StatelessWidget {
  const _InboxTile({
    required this.otherName,
    required this.lastMessage,
    required this.lastTime,
    required this.unreadCount,
    required this.onTap,
  });

  final String otherName;
  final String lastMessage;
  final String lastTime;
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(.10),
                child: const Icon(Icons.person, color: Colors.teal),
              ),
              const SizedBox(width: 12),

              // Nome + última msg
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMessage.isEmpty
                          ? 'Sem mensagens ainda.'
                          : lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Hora + badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    lastTime,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
