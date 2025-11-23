import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../repositories/service_repository.dart';
import '../models/service.dart';
import '../widgets/service_card.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      // 🔹 garante que a coleção "services" tenha dados
      context.read<AppState>().ensureDefaultServices();
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ServiceRepository();

    return StreamBuilder<List<Service>>(
      stream: repo.streamAll(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Erro ao carregar serviços:\n${snap.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final data = snap.data ?? const <Service>[];

        if (data.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Nenhum serviço cadastrado.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: data.length,
          itemBuilder: (_, i) => ServiceCard(service: data[i]),
        );
      },
    );
  }
}
