import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class NoLicenseScreen extends StatelessWidget {
  const NoLicenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
                child: const Icon(Icons.verified_user,
                    size: 72, color: Colors.white),
              ),
              const SizedBox(height: 32),
              const Text('Sin licencia activa',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              const Text(
                'Tu cuenta no tiene una licencia activa.\n'
                'Contactate para adquirir la app.',
                style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (user != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Cuenta: ${user.email}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.phone, color: Color(0xFF1565C0)),
                    SizedBox(width: 8),
                    Text('+54 11 1234-5678',
                        style: TextStyle(
                            color: Color(0xFF1565C0),
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ]),
                  SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.email, color: Color(0xFF1565C0)),
                    SizedBox(width: 8),
                    Text('contacto@tuempresa.com',
                        style: TextStyle(
                            color: Color(0xFF1565C0), fontSize: 14)),
                  ]),
                ]),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () async {
                  await AuthService.signOut();
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('Cerrar sesión',
                    style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
