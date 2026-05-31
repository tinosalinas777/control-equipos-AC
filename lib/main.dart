import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/clients_screen.dart';
import 'screens/trial_expired_screen.dart';
import 'services/maintenance_provider.dart';
import 'services/trial_service.dart';
import 'services/license_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (_) => MaintenanceProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mantenimiento Refrigeración',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const TrialGate(),
    );
  }
}

class TrialGate extends StatefulWidget {
  const TrialGate({super.key});
  @override
  State<TrialGate> createState() => _TrialGateState();
}

class _TrialGateState extends State<TrialGate> {
  bool _loading = true;
  bool _trialActive = false;
  int _daysLeft = 0;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final active = await TrialService.isTrialActive();
    final days = await TrialService.daysRemaining();
    setState(() {
      _trialActive = active;
      _daysLeft = days;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1565C0),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    if (!_trialActive) return const TrialExpiredScreen();
    return const SessionGate();
  }
}

/// Chequea si hay sesión activa guardada.
/// Si el usuario ya se logueó antes y tiene licencia → entra directo.
/// Si no hay sesión → muestra el login.
class SessionGate extends StatefulWidget {
  const SessionGate({super.key});
  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  bool _loading = true;
  Widget? _destination;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Sin sesión → va al login
      setState(() {
        _destination = const LoginScreen();
        _loading = false;
      });
      return;
    }

    // Hay sesión guardada → verifica licencia (puede fallar sin internet)
    try {
      final result = await LicenseService.checkLicense().timeout(
        const Duration(seconds: 5),
      );

      if (!mounted) return;

      switch (result.status) {
        case LicenseStatus.active:
          setState(() {
            _destination = const ClientsScreen();
            _loading = false;
          });
          break;
        case LicenseStatus.otherDevice:
        case LicenseStatus.noLicense:
          // Si la licencia cambió o fue revocada, manda al login
          setState(() {
            _destination = const LoginScreen();
            _loading = false;
          });
          break;
      }
    } catch (_) {
      // Sin internet → entra directo si ya tenía sesión
      // La licencia se verifica la próxima vez que haya conexión
      if (!mounted) return;
      setState(() {
        _destination = const ClientsScreen();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1565C0),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return _destination!;
  }
}
