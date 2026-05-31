import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/license_service.dart';
import 'clients_screen.dart';
import 'no_license_screen.dart';
import 'transfer_license_screen.dart';

class LoginScreen extends StatefulWidget {
  final int daysRemaining;
  const LoginScreen({super.key, this.daysRemaining = 0});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _error = null; });

    final user = await AuthService.signInWithGoogle();
    if (!mounted) return;

    if (user == null) {
      setState(() { _loading = false; _error = 'No se pudo iniciar sesión con Google'; });
      return;
    }

    final result = await LicenseService.checkLicense();
    if (!mounted) return;
    setState(() => _loading = false);

    switch (result.status) {
      case LicenseStatus.active:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const ClientsScreen()));
        break;
      case LicenseStatus.otherDevice:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => TransferLicenseScreen(
                deviceModel: result.activeDeviceModel ?? 'otro dispositivo')));
        break;
      case LicenseStatus.noLicense:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const NoLicenseScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.ac_unit, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text('Mantenimiento Preventivo',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const Text('Equipos de Refrigeración',
                  style: TextStyle(fontSize: 15, color: Colors.grey)),
              const SizedBox(height: 48),

              if (widget.daysRemaining <= 1)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(children: [
                    const Icon(Icons.warning_amber, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      widget.daysRemaining == 0
                          ? 'Tu período de prueba vence hoy'
                          : 'Queda 1 día de prueba',
                      style: const TextStyle(
                          color: Colors.orange, fontWeight: FontWeight.w600),
                    )),
                  ]),
                ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.login),
                  label: Text(_loading ? 'Iniciando...' : 'Continuar con Google',
                      style: const TextStyle(fontSize: 16)),
                  onPressed: _loading ? null : _signInWithGoogle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
