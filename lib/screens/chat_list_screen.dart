import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  static const routeName = '/chats';

  /// ✅ Gera o mesmo chatId do ChatScreen (ordenado)
  String _buildChatId(String clientId, String providerId) {
    final ids = [clientId, providerId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversas'),
        centerTitle: false,
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
                      'Quando um chamado for aceito, o chat aparece aqui.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final raw = docs[i].data() as Map<String, dynamic>;

                  final clientId = (raw['clientId'] ?? '') as String;
                  final providerId = (raw['providerId'] ?? '') as String;

                  final clientName = (raw['clientName'] ?? 'Cliente') as String;
                  final providerName =
                      (raw['providerName'] ?? 'Prestador') as String;

                  final otherName = uid == clientId ? providerName : clientName;

                  final lastMessage = (raw['lastMessage'] ?? '') as String;

                  final ts = raw['lastTimestamp'];
                  final lastTime = ts is Timestamp ? ts.toDate() : null;

                  // ✅ bookingId agora é só referência (não id do chat)
                  final bookingId = (raw['bookingId'] ?? docs[i].id) as String;

                  // ✅ chatId compatível com o ChatScreen
                  final chatId = _buildChatId(clientId, providerId);

                  return _ChatTile(
                    otherName: otherName,
                    lastMessage: lastMessage,
                    lastTime: lastTime,
                    onTap: () {
                      Navigator.push(
                        context,
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

class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.otherName,
    required this.lastMessage,
    required this.lastTime,
    required this.onTap,
  });

  final String otherName;
  final String lastMessage;
  final DateTime? lastTime;
  final VoidCallback onTap;

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
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
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(.10),
                child: const Icon(Icons.person, color: Colors.teal),
              ),
              const SizedBox(width: 12),
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
                          ? 'Envie uma mensagem...'
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
              Text(
                _formatTime(lastTime),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
