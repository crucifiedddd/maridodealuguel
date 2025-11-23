import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/service.dart';
import '../state/app_state.dart';

/// Args usados quando navegamos para a tela pela rota nomeada
class ProviderServiceConfigArgs {
  final Service service;
  final bool initialEnabled;
  final double initialPrice;
  final String? initialNote;

  const ProviderServiceConfigArgs({
    required this.service,
    required this.initialEnabled,
    required this.initialPrice,
    this.initialNote,
  });
}

class ProviderServiceConfigScreen extends StatefulWidget {
  static const routeName = '/provider/service-config';

  final Service service;
  final bool initialEnabled;
  final double initialPrice;
  final String? initialNote;

  const ProviderServiceConfigScreen({
    super.key,
    required this.service,
    required this.initialEnabled,
    required this.initialPrice,
    this.initialNote,
  });

  @override
  State<ProviderServiceConfigScreen> createState() =>
      _ProviderServiceConfigScreenState();
}

class _ProviderServiceConfigScreenState
    extends State<ProviderServiceConfigScreen> {
  late bool _enabled;
  late TextEditingController _priceCtrl;
  late TextEditingController _noteCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialEnabled;
    _priceCtrl = TextEditingController(
      text: widget.initialPrice.toStringAsFixed(2),
    );
    _noteCtrl = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    final user = app.currentUser;
    if (user == null) return;

    final uid = user.id;
    final service = widget.service;

    double price;
    try {
      price = double.parse(_priceCtrl.text.replaceAll(',', '.'));
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Informe um valor válido.')));
      return;
    }

    setState(() => _saving = true);
    try {
      final ref = FirebaseFirestore.instance
          .collection('providers')
          .doc(uid)
          .collection('skills')
          .doc(service.id);

      await ref.set({
        'enabled': _enabled,
        'customPrice': price,
        'note': _noteCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Competência atualizada com sucesso.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.service;

    return Scaffold(
      appBar: AppBar(title: Text('Configurar: ${s.name}')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho do serviço
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(s.icon, style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.description,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SwitchListTile.adaptive(
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
                title: const Text('Oferecer este serviço'),
                subtitle: const Text(
                  'Desligue se, por enquanto, você não estiver atendendo esse tipo de serviço.',
                ),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),

              Text(
                'Valor que você cobra',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  prefixText: 'R\$ ',
                  hintText: s.basePrice.toStringAsFixed(2),
                  helperText:
                      'Valor base do app: R\$ ${s.basePrice.toStringAsFixed(2)}',
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Observações para o cliente (opcional)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Ex.: Atendo somente em horário comercial...',
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: _saving
                    ? const Center(child: CircularProgressIndicator())
                    : FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.check),
                        label: const Text('Salvar alterações'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
