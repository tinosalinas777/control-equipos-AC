import 'package:flutter/material.dart';
import '../models/maintenance.dart';
import '../models/client.dart';
import '../models/equipment.dart';

/// Mantiene el estado del mantenimiento en progreso mientras el técnico
/// navega por el flujo: Checklist → Mediciones → Fotos → Firma → Resumen
class MaintenanceProvider extends ChangeNotifier {
  Client? selectedClient;
  Equipment? selectedEquipment;
  Maintenance? currentMaintenance;

  void startMaintenance(Client client, Equipment equipment, String technician) {
    selectedClient = client;
    selectedEquipment = equipment;
    final now = DateTime.now();
    final date =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    currentMaintenance = Maintenance(
      clientId: client.id!,
      equipmentId: equipment.id!,
      technician: technician,
      date: date,
    );
    notifyListeners();
  }

  void updateChecklist({
    int? filterCleaning,
    int? interiorCoilCleaning,
    int? exteriorCoilCleaning,
  }) {
    if (currentMaintenance == null) return;
    currentMaintenance = currentMaintenance!.copyWith(
      filterCleaning: filterCleaning,
      interiorCoilCleaning: interiorCoilCleaning,
      exteriorCoilCleaning: exteriorCoilCleaning,
    );
    notifyListeners();
  }

  void updateMeasurements({
    double? voltageL1L2,
    double? voltageL2L3,
    double? voltageL3L1,
    double? compressorCurrentL1,
    double? compressorCurrentL2,
    double? compressorCurrentL3,
    double? fanCurrentL1,
    double? fanCurrentL2,
    double? fanCurrentL3,
    double? lowPressure,
    double? highPressure,
    double? ambientTemperature,
    double? evaporatorTemperature,
    double? gasCharge,
    String? observations,
  }) {
    if (currentMaintenance == null) return;
    currentMaintenance = currentMaintenance!.copyWith(
      voltageL1L2: voltageL1L2,
      voltageL2L3: voltageL2L3,
      voltageL3L1: voltageL3L1,
      compressorCurrentL1: compressorCurrentL1,
      compressorCurrentL2: compressorCurrentL2,
      compressorCurrentL3: compressorCurrentL3,
      fanCurrentL1: fanCurrentL1,
      fanCurrentL2: fanCurrentL2,
      fanCurrentL3: fanCurrentL3,
      lowPressure: lowPressure,
      highPressure: highPressure,
      ambientTemperature: ambientTemperature,
      evaporatorTemperature: evaporatorTemperature,
      gasCharge: gasCharge,
      observations: observations,
    );
    notifyListeners();
  }

  void updatePhotos(String photosJson) {
    if (currentMaintenance == null) return;
    currentMaintenance =
        currentMaintenance!.copyWith(photosPaths: photosJson);
    notifyListeners();
  }

  void updateSignature(String signaturePath) {
    if (currentMaintenance == null) return;
    currentMaintenance =
        currentMaintenance!.copyWith(signaturePath: signaturePath);
    notifyListeners();
  }

  void reset() {
    selectedClient = null;
    selectedEquipment = null;
    currentMaintenance = null;
    notifyListeners();
  }
}
