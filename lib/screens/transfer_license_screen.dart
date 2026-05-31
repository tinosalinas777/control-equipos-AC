import 'package:flutter/material.dart';
import '../services/license_service.dart';
import '../services/auth_service.dart';
import 'clients_screen.dart';

class TransferLicenseScreen extends StatefulWidget {
  final String deviceModel;
  const TransferLicenseScreen({super.key, required this.deviceModel});

  @override
  State<TransferLicenseScreen> createState() => _TransferLicenseScreenState();
}

class _TransferLicenseScreenState extends State<TransferLicenseScreen> {
  bool _transferring = false;

  Future<void> _transfer() async {
    setState(() => _transferring = true);
    await LicenseService.transferLicense();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ClientsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smartphone, size: 72, color: Colors.white),
              ),
              const SizedBox(height: 32),
              const Text('Licencia en otro dispositivo',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(
                'Tu licencia está activa en:\n${widget.deviceModel}\n\n'
                '¿Querés transferirla a este dispositivo?',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 15, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: const Text(
                  'Al transferir, el dispositivo anterior quedará sin acceso.',
                  style: TextStyle(color: Colors.orange, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1565C0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _transferring ? null : _transfer,
                  child: _transferring
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Transferir a este dispositivo',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await AuthService.signOut();
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('Cancelar',
                    style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
