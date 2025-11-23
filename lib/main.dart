import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'state/app_state.dart';

// TELAS
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/booking_form_screen.dart';
import 'screens/service_detail_screen.dart';
import 'screens/provider_home_screen.dart';
import 'screens/provider_service_config_screen.dart';

// ✅ ADICIONADAS
import 'screens/provider_profile_screen.dart';
import 'screens/edit_profile_screen.dart';

// MODELS
import 'models/service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppState())],
      child: MaterialApp(
        title: 'Marido de Aluguel',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,

        // ===== ROTAS NOMEADAS =====
        onGenerateRoute: (settings) {
          switch (settings.name) {
            // Login (caso você queira navegar por rota)
            case LoginScreen.routeName:
              return MaterialPageRoute(
                builder: (_) => const LoginScreen(),
                settings: settings,
              );

            // Detalhe de serviço (cliente)
            case ServiceDetailScreen.routeName:
              final service = settings.arguments as Service;
              return MaterialPageRoute(
                builder: (_) => ServiceDetailScreen(service: service),
                settings: settings,
              );

            // Formulário de agendamento
            case BookingFormScreen.routeName:
              final args = settings.arguments as BookingFormArgs;
              return MaterialPageRoute(
                builder: (_) => BookingFormScreen(service: args.service),
                settings: settings,
              );

            // Home do prestador (se você navegar por pushNamed)
            case ProviderHomeScreen.routeName:
              return MaterialPageRoute(
                builder: (_) => const ProviderHomeScreen(),
                settings: settings,
              );

            // Configuração de um serviço do prestador
            case ProviderServiceConfigScreen.routeName:
              final args = settings.arguments as ProviderServiceConfigArgs;
              return MaterialPageRoute(
                builder: (_) => ProviderServiceConfigScreen(
                  service: args.service,
                  initialEnabled: args.initialEnabled,
                  initialPrice: args.initialPrice,
                  initialNote: args.initialNote,
                ),
                settings: settings,
              );

            // ✅ PERFIL DO PRESTADOR
            case ProviderProfileScreen.routeName:
              return MaterialPageRoute(
                builder: (_) => const ProviderProfileScreen(),
                settings: settings,
              );

            // ✅ EDITAR PERFIL DO PRESTADOR
            case EditProfileScreen.routeName:
              return MaterialPageRoute(
                builder: (_) => const EditProfileScreen(),
                settings: settings,
              );

            // ✅ fallback para evitar rota não encontrada retornar null
            default:
              return MaterialPageRoute(
                builder: (_) => const HomeScreen(),
                settings: settings,
              );
          }
        },

        // Decide se mostra Login ou Home conforme autenticação
        home: const _AuthGate(),
      ),
    );
  }
}

/// Decide entre LoginScreen, HomeScreen (cliente)
/// e ProviderHomeScreen (prestador), observando o FirebaseAuth
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        // Carregando estado inicial de auth
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Usuário NÃO logado
        if (!snap.hasData || snap.data == null) {
          return const LoginScreen();
        }

        // Usuário logado -> carregar perfil do Firestore
        final firebaseUser = snap.data!;
        final app = context.read<AppState>();

        return FutureBuilder<void>(
          future: app.loadUserProfile(firebaseUser.uid),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final user = app.currentUser;

            // Se algo deu errado ao carregar, volta pro login
            if (user == null) {
              return const LoginScreen();
            }

            // PRESTADOR DE SERVIÇOS
            if (user.isProvider == true) {
              // Aqui você pode carregar dados específicos do prestador
              // (chamados pendentes, estatísticas etc) no AppState depois.
              return const ProviderHomeScreen();
            }

            // CLIENTE COMUM
            app.ensureDefaultServices(); // garante catálogo de serviços
            app.loadBookings(); // carrega agendamentos do cliente

            return const HomeScreen();
          },
        );
      },
    );
  }
}
