import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum LicenseStatus {
  active,         // licencia activa en este dispositivo
  otherDevice,    // licencia activa en otro dispositivo
  noLicense,      // sin licencia
}

class LicenseResult {
  final LicenseStatus status;
  final String? activeDeviceModel; // modelo del dispositivo activo (si es otro)
  const LicenseResult(this.status, {this.activeDeviceModel});
}

class LicenseService {
  static final _db = FirebaseFirestore.instance;

  static Future<String> getDeviceId() async {
    final info = DeviceInfoPlugin();
    final android = await info.androidInfo;
    return android.id; // ID único del dispositivo Android
  }

  static Future<LicenseResult> checkLicense() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const LicenseResult(LicenseStatus.noLicense);

    final deviceId = await getDeviceId();
    final doc = await _db.collection('licenses').doc(user.uid).get();

    if (!doc.exists) {
      return const LicenseResult(LicenseStatus.noLicense);
    }

    final data = doc.data()!;
    final active  = data['active'] as bool? ?? false;
    final storedDevice = data['deviceId'] as String? ?? '';
    final deviceModel  = data['deviceModel'] as String? ?? 'otro dispositivo';

    if (!active) return const LicenseResult(LicenseStatus.noLicense);

    // Si deviceId esta vacio es la primera vez -> registra este dispositivo
    if (storedDevice.isEmpty) {
      final info    = DeviceInfoPlugin();
      final android = await info.androidInfo;
      await _db.collection('licenses').doc(user.uid).update({
        'deviceId':    android.id,
        'deviceModel': '\${android.brand} \${android.model}',
        'activatedAt': FieldValue.serverTimestamp(),
      });
      return const LicenseResult(LicenseStatus.active);
    }

    if (storedDevice == deviceId) {
      return const LicenseResult(LicenseStatus.active);
    }

    return LicenseResult(
      LicenseStatus.otherDevice,
      activeDeviceModel: deviceModel,
    );
  }

  /// Transfiere la licencia al dispositivo actual
  static Future<void> transferLicense() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final info = DeviceInfoPlugin();
    final android = await info.androidInfo;

    await _db.collection('licenses').doc(user.uid).update({
      'deviceId':    android.id,
      'deviceModel': '${android.brand} ${android.model}',
      'transferredAt': FieldValue.serverTimestamp(),
    });
  }

  /// Solo vos (admin) llamás esto para activar una licencia nueva
  /// Podés hacerlo desde la consola de Firestore también
  static Future<void> activateLicense(String userId) async {
    final ref = _db.collection('licenses').doc(userId);
    await ref.set({
      'active':      true,
      'deviceId':    '',
      'deviceModel': '',
      'activatedAt': FieldValue.serverTimestamp(),
      'transferredAt': null,
    }, SetOptions(merge: true));
  }
}
