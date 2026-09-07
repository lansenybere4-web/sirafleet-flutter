import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';

import 'screens/auth/login_screen.dart';
import 'screens/admin/dashboard_screen.dart';
import 'screens/responsable/dashboard_screen.dart';
import 'screens/chauffeur/home_screen.dart';

void main() {
  runApp(const SiraFleetApp());
}

class SiraFleetApp extends StatelessWidget {
  const SiraFleetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'SiraFleet',
        debugShowCheckedModeBanner: false,

        // ========================================================
        // LOCALISATION
        // ========================================================

        locale: const Locale('fr', 'FR'),

        supportedLocales: const [
          Locale('fr', 'FR'),
          Locale('en', 'US'),
        ],

        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        // ========================================================
        // THEME
        // ========================================================

        theme: ThemeData(
          useMaterial3: true,
          primaryColor: const Color(0xFF1D3557),
          fontFamily: 'Roboto',
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),

          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1D3557),
          ),
        ),

        // ========================================================
        // ÉCRAN DE DÉMARRAGE
        // ========================================================

        home: const AppStartupGate(),
      ),
    );
  }
}

class AppStartupGate extends StatefulWidget {
  const AppStartupGate({super.key});

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate> {
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();

    _initFuture = context
        .read<AuthProvider>()
        .tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,

      builder: (context, snapshot) {
        // ========================================================
        // CHARGEMENT
        // ========================================================

        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5F7FA),

            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1D3557),
              ),
            ),
          );
        }

        // ========================================================
        // AUTHENTIFICATION
        // ========================================================

        final auth = context.watch<AuthProvider>();

        // ========================================================
        // NON CONNECTÉ
        // ========================================================

        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }

        // ========================================================
        // ADMIN
        // ========================================================

        if (auth.isAdmin) {
          return const AdminDashboardScreen();
        }

        // ========================================================
        // RESPONSABLE DE FLOTTE
        // ========================================================

        if (auth.isResponsableFlotte) {
          return const ResponsableDashboardScreen();
        }

        // ========================================================
        // CHAUFFEUR
        // ========================================================

        if (auth.isChauffeur) {
          return const ChauffeurHomeScreen();
        }

        // ========================================================
        // RÔLE INCONNU
        // ========================================================

        return const LoginScreen();
      },
    );
  }
}