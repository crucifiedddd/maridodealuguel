import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.bookingId,
    required this.clientId,
    required this.providerId,
    required this.otherName,
  });

  /// bookingId continua vindo só para referência do serviço,
  /// mas NÃO é mais usado como id do chat.
  final String bookingId;
  final String clientId;
  final String providerId;
  final String otherName;

  static const routeName = '/chat';

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textCtrl = TextEditingController();
  bool _sending = false;

  String? get _myId => FirebaseAuth.instance.currentUser?.uid;

  /// ✅ ChatId único baseado nos dois UIDs (ordenado)
  String get _chatId {
    final ids = [widget.clientId, widget.providerId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  DocumentReference<Map<String, dynamic>> get _chatRef =>
      FirebaseFirestore.instance.collection('chats').doc(_chatId);

  CollectionReference<Map<String, dynamic>> get _messagesRef =>
      _chatRef.collection('messages');

  @override
  void initState() {
    super.initState();
    _ensureChatExists();
  }

  Future<void> _ensureChatExists() async {
    final doc = await _chatRef.get();
    if (doc.exists) return;

    await _chatRef.set({
      'bookingId': widget.bookingId,
      'clientId': widget.clientId,
      'providerId': widget.providerId,
      'participants': [widget.clientId, widget.providerId],
      'lastMessage': '',
      'lastTimestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _sendMessage() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    final myId = _myId;
    if (myId == null) return;

    setState(() => _sending = true);
    _textCtrl.clear();

    try {
      await _messagesRef.add({
        'senderId': myId,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _chatRef.set({
        'lastMessage': text,
        'lastTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar mensagem: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myId = _myId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherName),
        centerTitle: false,
      ),
      body: Container(
        // ✅ mesmo padrão do app
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
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _messagesRef
                    .orderBy('createdAt', descending: true)
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
                          'Erro ao carregar mensagens:\n${snap.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final docs = snap.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('Nenhuma mensagem ainda.'),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final data = docs[i].data();
                      final isMe = data['senderId'] == myId;
                      final text = (data['text'] ?? '') as String;

                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.teal : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: isMe
                                ? []
                                : [
                                    BoxShadow(
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                      color: Colors.black.withOpacity(0.05),
                                    ),
                                  ],
                            border: isMe
                                ? null
                                : Border.all(
                                    color: Colors.black.withOpacity(0.04),
                                  ),
                          ),
                          child: Text(
                            text,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                              fontSize: 14.5,
                              height: 1.25,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // ✅ Input seguindo estilo do app
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textCtrl,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Digite uma mensagem...',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.black.withOpacity(0.06),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.black.withOpacity(0.06),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Colors.teal),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      width: 48,
                      child: FilledButton(
                        onPressed: _sending ? null : _sendMessage,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          backgroundColor: Colors.teal,
                        ),
                        child: _sending
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded,
                                color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
