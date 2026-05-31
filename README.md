# flutter_application_1

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
Exacto. El proceso completo para un cliente nuevo es:
1 — El cliente instala el APK y abre la app
2 — Inicia sesión con su Google
3 — Vos vas a Firebase Console → Authentication y ves el email y el UID del nuevo usuario
4 — Vas a Firestore → colección licenses y creás un documento nuevo:
CampoTipoValoractivebooleantruedeviceIdstring(vacío)deviceModelstring(vacío)
5 — El cliente vuelve a abrir la app → entra directo, y automáticamente registra su dispositivo.

reglas de seguridad firebase:

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /licenses/{uid} {
      // El usuario puede leer su licencia
      allow read: if request.auth != null && request.auth.uid == uid;
      // El usuario puede actualizar SOLO los campos de dispositivo
      allow update: if request.auth != null 
                    && request.auth.uid == uid
                    && request.resource.data.active == resource.data.active;
      allow create, delete: if false;
    }

    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }

    match /{document=**} {
      allow read, write: if false;
    }
  }
}

+++++++++++++++++++++++++++++++++++++++++++++++++++

