import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/database_helper.dart';
import '../models/client.dart';
import '../models/equipment.dart';
import '../models/maintenance.dart';

class SyncService {
  static final _db  = FirebaseFirestore.instance;

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // ── Referencias ───────────────────────────────────────────────────────────
  static CollectionReference get _clients =>
      _db.collection('users').doc(_uid).collection('clients');

  static CollectionReference _equipments(String clientId) =>
      _clients.doc(clientId).collection('equipments');

  static CollectionReference _maintenances(String clientId, String equipmentId) =>
      _equipments(clientId).doc(equipmentId).collection('maintenances');

  // ── SUBIR a Firestore ─────────────────────────────────────────────────────
  static Future<void> uploadAll() async {
    final clients = await DatabaseHelper.instance.getClients();
    for (final c in clients) {
      await _clients.doc('${c.id}').set({
        'name':  c.name,
        'plant': c.plant,
        'localId': c.id,
      });

      final equipments = await DatabaseHelper.instance
          .getEquipmentsByClient(c.id!);
      for (final e in equipments) {
        await _equipments('${c.id}').doc('${e.id}').set({
          'number':     e.number,
          'location':   e.location,
          'capacity':   e.capacity,
          'type':       e.type,
          'refrigerant':e.refrigerant,
          'brand':      e.brand,
          'localId':    e.id,
        });

        final maintenances = await DatabaseHelper.instance
            .getMaintenancesByEquipment(e.id!);
        for (final m in maintenances) {
          final mm = await DatabaseHelper.instance.getMaintenance(
              (m['id'] as int));
          if (mm == null) continue;
          await _maintenances('${c.id}', '${e.id}')
              .doc('${mm.id}')
              .set(_maintenanceToMap(mm));
        }
      }
    }
  }

  // ── DESCARGAR de Firestore ────────────────────────────────────────────────
  static Future<void> downloadAll() async {
    final clientSnaps = await _clients.get();
    for (final cd in clientSnaps.docs) {
      final data = cd.data() as Map<String, dynamic>;
      final client = Client(
        name:  data['name']  ?? '',
        plant: data['plant'] ?? '',
      );
      final clientId = await DatabaseHelper.instance.insertClient(client);

      final eqSnaps = await _equipments(cd.id).get();
      for (final ed in eqSnaps.docs) {
        final ed2 = ed.data() as Map<String, dynamic>;
        final eq = Equipment(
          clientId:   clientId,
          number:     ed2['number']     ?? 0,
          location:   ed2['location']   ?? '',
          capacity:   ed2['capacity']   ?? '',
          type:       ed2['type']       ?? '',
          refrigerant:ed2['refrigerant']?? '',
          brand:      ed2['brand']      ?? '',
        );
        final eqId = await DatabaseHelper.instance.insertEquipment(eq);

        final mSnaps = await _maintenances(cd.id, ed.id).get();
        for (final md in mSnaps.docs) {
          final mm = _maintenanceFromMap(
              md.data() as Map<String, dynamic>, clientId, eqId);
          await DatabaseHelper.instance.insertMaintenance(mm);
        }
      }
    }
  }

  // ── Guardar mantenimiento individual ──────────────────────────────────────
  static Future<void> saveMaintenance(
      Maintenance m, int clientId, int equipmentId) async {
    await _maintenances('$clientId', '$equipmentId')
        .doc('${m.id}')
        .set(_maintenanceToMap(m));
  }

  // ── helpers ───────────────────────────────────────────────────────────────
  static Map<String, dynamic> _maintenanceToMap(Maintenance m) => {
        'technician':           m.technician,
        'date':                 m.date,
        'filterCleaning':       m.filterCleaning,
        'interiorCoilCleaning': m.interiorCoilCleaning,
        'exteriorCoilCleaning': m.exteriorCoilCleaning,
        'voltageL1L2':          m.voltageL1L2,
        'voltageL2L3':          m.voltageL2L3,
        'voltageL3L1':          m.voltageL3L1,
        'compressorCurrentL1':  m.compressorCurrentL1,
        'compressorCurrentL2':  m.compressorCurrentL2,
        'compressorCurrentL3':  m.compressorCurrentL3,
        'fanCurrentL1':         m.fanCurrentL1,
        'fanCurrentL2':         m.fanCurrentL2,
        'fanCurrentL3':         m.fanCurrentL3,
        'lowPressure':          m.lowPressure,
        'highPressure':         m.highPressure,
        'ambientTemperature':   m.ambientTemperature,
        'evaporatorTemperature':m.evaporatorTemperature,
        'gasCharge':            m.gasCharge,
        'observations':         m.observations,
        'syncedAt':             FieldValue.serverTimestamp(),
      };

  static Maintenance _maintenanceFromMap(
      Map<String, dynamic> m, int clientId, int equipmentId) =>
      Maintenance(
        clientId:             clientId,
        equipmentId:          equipmentId,
        technician:           m['technician']           ?? '',
        date:                 m['date']                 ?? '',
        filterCleaning:       m['filterCleaning']       ?? -1,
        interiorCoilCleaning: m['interiorCoilCleaning'] ?? -1,
        exteriorCoilCleaning: m['exteriorCoilCleaning'] ?? -1,
        voltageL1L2:          (m['voltageL1L2']         as num?)?.toDouble(),
        voltageL2L3:          (m['voltageL2L3']         as num?)?.toDouble(),
        voltageL3L1:          (m['voltageL3L1']         as num?)?.toDouble(),
        compressorCurrentL1:  (m['compressorCurrentL1'] as num?)?.toDouble(),
        compressorCurrentL2:  (m['compressorCurrentL2'] as num?)?.toDouble(),
        compressorCurrentL3:  (m['compressorCurrentL3'] as num?)?.toDouble(),
        fanCurrentL1:         (m['fanCurrentL1']        as num?)?.toDouble(),
        fanCurrentL2:         (m['fanCurrentL2']        as num?)?.toDouble(),
        fanCurrentL3:         (m['fanCurrentL3']        as num?)?.toDouble(),
        lowPressure:          (m['lowPressure']         as num?)?.toDouble(),
        highPressure:         (m['highPressure']        as num?)?.toDouble(),
        ambientTemperature:   (m['ambientTemperature']  as num?)?.toDouble(),
        evaporatorTemperature:(m['evaporatorTemperature']as num?)?.toDouble(),
        gasCharge:            (m['gasCharge']           as num?)?.toDouble(),
        observations:         m['observations']         ?? '',
      );
}
