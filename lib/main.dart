import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/trial_expired_screen.dart';
import 'services/maintenance_provider.dart';
import 'services/trial_service.dart';

void main() {
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
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
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
  int _daysRemaining = 0;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final active = await TrialService.isTrialActive();
    final days   = await TrialService.daysRemaining();
    setState(() {
      _trialActive    = active;
      _daysRemaining  = days;
      _loading        = false;
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

    // Si quedan pocos días muestra un banner en el login
    return LoginScreen(daysRemaining: _daysRemaining);
  }
}
