import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/service_detail_screen.dart';
import 'screens/booking_form_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'Marido de Aluguel',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        initialRoute: SplashScreen.routeName,
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case SplashScreen.routeName:
              return MaterialPageRoute(builder: (_) => const SplashScreen());

            case LoginScreen.routeName:
              return MaterialPageRoute(builder: (_) => const LoginScreen());

            case HomeScreen.routeName:
              return MaterialPageRoute(builder: (_) => const HomeScreen());

            case ServiceDetailScreen.routeName:
              final args = settings.arguments as ServiceDetailArgs;
              return MaterialPageRoute(
                builder: (_) => ServiceDetailScreen(service: args.service),
              );

            case BookingFormScreen.routeName:
              final args = settings.arguments as BookingFormArgs;
              return MaterialPageRoute(
                builder: (_) => BookingFormScreen(service: args.service),
              );

            default:
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Rota não encontrada')),
                ),
              );
          }
        },
      ),
    );
  }
}
