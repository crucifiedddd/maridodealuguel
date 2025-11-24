import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/service.dart';
import '../models/booking.dart';
import '../state/app_state.dart';

/// Wrapper de argumentos para a rota de agendamento
class BookingFormArgs {
  final Service service;
  BookingFormArgs(this.service);
}

class BookingFormScreen extends StatefulWidget {
  static const routeName = '/booking';

  final Service service;

  const BookingFormScreen({super.key, required this.service});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime? _dateTime;
  bool _saving = false;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );

    if (time == null) return;

    setState(() {
      _dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    if (_dateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha a data e horário.')),
      );
      return;
    }

    setState(() => _saving = true);

    final app = context.read<AppState>();
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não logado.')),
      );
      return;
    }

    final clientId = firebaseUser.uid;
    final clientName = app.currentUser?.name ?? firebaseUser.email ?? 'Cliente';

    // 🔹 Monta o booking para salvar no Firestore
    final bookingData = {
      'clientId': clientId,
      'clientName': clientName,

      // providerId ainda não existe aqui (só quando aceitar)
      'providerId': '',
      'providerName': '',

      'serviceId': widget.service.id,
      'serviceName': widget.service.name,
      'serviceDescription': widget.service.description,
      'serviceIcon': widget.service.icon,
      'price': widget.service.basePrice,
      'status': 'pending',

      'address': _addressCtrl.text.trim(),
      'notes': _notesCtrl.text.trim(),
      'dateTime': Timestamp.fromDate(_dateTime!),

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      // ✅ 1) Salva booking
      final bookingRef = await FirebaseFirestore.instance
          .collection('bookings')
          .add(bookingData);

      final bookingId = bookingRef.id;

      // ✅ 2) Cria chat automaticamente usando o MESMO ID do booking
      // Como ainda não tem prestador, participants começa só com o cliente
      await FirebaseFirestore.instance.collection('chats').doc(bookingId).set({
        'bookingId': bookingId,
        'clientId': clientId,
        'providerId': '',
        'clientName': clientName,
        'providerName': '',
        'participants': [clientId],
        'lastMessage': '',
        'lastTimestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Atualiza lista local de agendamentos
      await app.loadBookings();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agendamento criado com sucesso!')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar agendamento: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final dateLabel = _dateTime == null
        ? 'Selecione data e horário'
        : DateFormat('dd/MM/yyyy HH:mm').format(_dateTime!);

    return Scaffold(
      appBar: AppBar(title: Text('Agendar: ${service.name}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              service.description,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Endereço
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Endereço completo'),
              validator: (v) => v == null || v.trim().length < 6
                  ? 'Informe um endereço válido'
                  : null,
            ),
            const SizedBox(height: 12),

            // Observações
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            // Data/hora
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Data e horário',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(dateLabel),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDateTime,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_saving ? 'Salvando...' : 'Confirmar agendamento'),
                onPressed: _saving ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
