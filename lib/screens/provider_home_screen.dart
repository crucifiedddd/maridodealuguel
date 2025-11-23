import 'package:flutter/material.dart';

import 'provider_skills_screen.dart';
import 'provider_requests_screen.dart';
import 'provider_profile_screen.dart';

/// Home do prestador: abas para competências, chamados e perfil.
class ProviderHomeScreen extends StatelessWidget {
  const ProviderHomeScreen({super.key});

  static const routeName = '/provider/home';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Prestador'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.build_rounded), text: 'Competências'),
              Tab(icon: Icon(Icons.calendar_month_rounded), text: 'Chamados'),
              Tab(icon: Icon(Icons.person_rounded), text: 'Perfil'),
            ],
          ),
        ),

        // ✅ IMPORTANTE: NÃO usar const aqui
        body: TabBarView(
          children: [
            ProviderSkillsScreen(),
            ProviderRequestsScreen(),
            ProviderProfileScreen(),
          ],
        ),
      ),
    );
  }
}
