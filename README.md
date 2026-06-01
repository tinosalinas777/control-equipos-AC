# Control AC - Guía de configuración Firebase

## 1. Crear proyecto en Firebase

1. Andá a [console.firebase.google.com](https://console.firebase.google.com)
2. Clic en **"Agregar proyecto"**
3. Nombre del proyecto: `Control AC` (o el que prefieras)
4. Desactivá Google Analytics (opcional)
5. Clic en **"Crear proyecto"**

---

## 2. Agregar app Android

1. En el proyecto → clic en el ícono **Android**
2. Completá los campos:
   - **Package name:** `com.example.flutter_application_1`
   - **Nombre de la app:** Control AC
3. Clic en **"Registrar app"**
4. Descargá el archivo `google-services.json`
5. Copialo en la carpeta `android/app/` del proyecto Flutter
6. Clic en **"Siguiente"** hasta llegar al final → **"Ir a la consola"**

---

## 3. Agregar SHA-1 del certificado

1. En Firebase Console → ⚙️ Configuración del proyecto → tu app Android
2. Clic en **"Agregar huella digital"**
3. Pegá el SHA-1 obtenido con este comando:

```
"C:\Program Files\Java\jre1.8.0_481\bin\keytool" -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

> Para el APK de release necesitás el SHA-1 del keystore de producción.

---

## 4. Habilitar Google Sign-In

1. Firebase Console → **Authentication** → **Sign-in method**
2. Clic en **Google** → habilitalo
3. Completá el **email de soporte** (obligatorio)
4. Clic en **Guardar**

---

## 5. Crear base de datos Firestore

1. Firebase Console → **Firestore Database** → **Crear base de datos**
2. Elegí **Modo producción**
3. Región: **southamerica-east1** (Brasil/Argentina)
4. Clic en **Listo**

---

## 6. Reglas de seguridad de Firestore

Firebase Console → **Firestore Database** → pestaña **Reglas**

Reemplazá todo el contenido con esto y hacé clic en **Publicar**:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Licencias: el usuario solo puede leer la suya
    // Solo el admin puede crear/eliminar desde la consola
    match /licenses/{uid} {
      allow read: if request.auth != null && request.auth.uid == uid;
      allow update: if request.auth != null
                    && request.auth.uid == uid
                    && request.resource.data.active == resource.data.active;
      allow create, delete: if false;
    }

    // Datos del usuario: solo él puede leer y escribir los suyos
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }

    // Todo lo demás: bloqueado
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 7. Activar licencia para un usuario nuevo

### Paso a paso cada vez que un cliente compra la app:

**1.** El cliente instala el APK e inicia sesión con su cuenta Google.

**2.** Vos vas a **Firebase Console → Authentication → Users** y copiás el **UID** del nuevo usuario (columna "User UID").

**3.** Vas a **Firestore → Datos → colección `licenses`** → **Agregar documento**:

| Campo | Tipo | Valor |
|-------|------|-------|
| ID del documento | — | (pegá el UID del usuario) |
| `active` | boolean | `true` |
| `deviceId` | string | (dejar vacío) |
| `deviceModel` | string | (dejar vacío) |

**4.** El cliente vuelve a abrir la app → entra directo y el dispositivo queda registrado automáticamente.

---

## 8. Transferencia de licencia (cambio de celular)

Cuando el cliente cambia de dispositivo:

1. Instala el APK en el celular nuevo
2. Inicia sesión con su Google
3. La app detecta que la licencia está en otro dispositivo
4. Le muestra una pantalla para transferir
5. El cliente toca **"Transferir a este dispositivo"**
6. El dispositivo anterior queda sin acceso

> Si el cliente tiene problemas, podés ir a Firestore → `licenses` → su documento y vaciar el campo `deviceId` manualmente para que se registre de nuevo.

---

## 9. Revocar licencia

Para dar de baja a un usuario:

1. Firestore → colección `licenses` → documento del usuario
2. Cambiá el campo `active` de `true` a `false`
3. La próxima vez que abra la app con internet verá la pantalla de "Sin licencia activa"

---

## 10. Estructura de Firestore

```
licenses/
  {uid}/
    active: true/false
    deviceId: "id_del_dispositivo"
    deviceModel: "Samsung Galaxy A04"
    activatedAt: timestamp
    transferredAt: timestamp (opcional)

users/
  {uid}/
    clients/
      {clientId}/
        name: "Nombre del cliente"
        plant: "Planta"
        equipments/
          {equipmentId}/
            number: 1
            location: "Sala de servidores"
            ...
            maintenances/
              {maintenanceId}/
                date: "01/06/2026"
                technician: "Juan Pérez"
                ...
```

---

## 11. Plan gratuito (Spark)

Límites diarios de Firestore en el plan gratuito:

| Operación | Límite diario |
|-----------|--------------|
| Lecturas | 50.000 |
| Escrituras | 20.000 |
| Eliminaciones | 20.000 |
| Almacenamiento | 1 GB |

Para el uso normal de la app (registro de mantenimientos) estos límites son más que suficientes.

---

## 12. Archivos de configuración en el proyecto

| Archivo | Ubicación | Descripción |
|---------|-----------|-------------|
| `google-services.json` | `android/app/` | Configuración Firebase para Android |
| `android/app/build.gradle.kts` | `android/app/` | Plugin de Google Services |
| `android/build.gradle.kts` | `android/` | Classpath de Google Services |

