import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/service.dart';
import '../state/app_state.dart';
import '../repositories/service_repository.dart';

class ProviderSkillsScreen extends StatelessWidget {
  const ProviderSkillsScreen({super.key});

  static const routeName = '/provider/skills';

  @override
  Widget build(BuildContext context) {
    final repo = ServiceRepository();
    final app = context.watch<AppState>();
    final currentUser = app.currentUser;

    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

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
      child: StreamBuilder<List<Service>>(
        stream: repo.streamAll(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 50,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Erro ao carregar serviços.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snap.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            );
          }

          final services = snap.data ?? const <Service>[];

          if (services.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum serviço disponível no momento.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: services.length,
            itemBuilder: (_, index) {
              return _SkillCard(
                service: services[index],
                providerId: currentUser.id,
              );
            },
          );
        },
      ),
    );
  }
}

class _SkillCard extends StatefulWidget {
  const _SkillCard({required this.service, required this.providerId});

  final Service service;
  final String providerId;

  @override
  State<_SkillCard> createState() => _SkillCardState();
}

class _SkillCardState extends State<_SkillCard> {
  bool _loading = false;
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() => _loading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('provider_services')
          .doc('${widget.providerId}_${widget.service.id}')
          .get();

      if (doc.exists) {
        _enabled = (doc.data()?['enabled'] as bool?) ?? false;
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(bool value) async {
    setState(() {
      _enabled = value;
      _loading = true;
    });

    try {
      final ref = FirebaseFirestore.instance
          .collection('provider_services')
          .doc('${widget.providerId}_${widget.service.id}');

      await ref.set({
        'providerId': widget.providerId,
        'serviceId': widget.service.id,
        'serviceName': widget.service.name,
        'enabled': _enabled,
        'basePrice': widget.service.basePrice,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.service;

    return Opacity(
      opacity: _loading ? 0.55 : 1,
      child: Card(
        elevation: 0,
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preço
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'R\$ ${s.basePrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.teal,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Título + descrição
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.description,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.25,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Switch
              Switch(
                value: _enabled,
                activeColor: Colors.white,
                activeTrackColor: Colors.teal,
                inactiveTrackColor: Colors.grey.shade300,
                onChanged: _loading ? null : _toggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
