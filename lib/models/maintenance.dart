class Maintenance {
  final int? id;
  final int clientId;
  final int equipmentId;
  final String technician;
  final String date;

  // Checklist (1 = OK, 0 = No OK, -1 = N/A)
  final int filterCleaning;
  final int interiorCoilCleaning;
  final int exteriorCoilCleaning;

  // Mediciones eléctricas
  final double? voltageL1L2;
  final double? voltageL2L3;
  final double? voltageL3L1;
  final double? compressorCurrentL1;
  final double? compressorCurrentL2;
  final double? compressorCurrentL3;
  final double? fanCurrentL1;
  final double? fanCurrentL2;
  final double? fanCurrentL3;

  // Presiones y temperaturas
  final double? lowPressure;
  final double? highPressure;
  final double? ambientTemperature;
  final double? evaporatorTemperature;

  // Gas y extras
  final double? gasCharge;
  final String observations;
  final String? signaturePath;
  final String? photosPaths; // JSON string con lista de paths

  Maintenance({
    this.id,
    required this.clientId,
    required this.equipmentId,
    required this.technician,
    required this.date,
    this.filterCleaning = -1,
    this.interiorCoilCleaning = -1,
    this.exteriorCoilCleaning = -1,
    this.voltageL1L2,
    this.voltageL2L3,
    this.voltageL3L1,
    this.compressorCurrentL1,
    this.compressorCurrentL2,
    this.compressorCurrentL3,
    this.fanCurrentL1,
    this.fanCurrentL2,
    this.fanCurrentL3,
    this.lowPressure,
    this.highPressure,
    this.ambientTemperature,
    this.evaporatorTemperature,
    this.gasCharge,
    this.observations = '',
    this.signaturePath,
    this.photosPaths,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'client_id': clientId,
        'equipment_id': equipmentId,
        'technician': technician,
        'date': date,
        'filter_cleaning': filterCleaning,
        'interior_coil_cleaning': interiorCoilCleaning,
        'exterior_coil_cleaning': exteriorCoilCleaning,
        'voltage_l1_l2': voltageL1L2,
        'voltage_l2_l3': voltageL2L3,
        'voltage_l3_l1': voltageL3L1,
        'compressor_current_l1': compressorCurrentL1,
        'compressor_current_l2': compressorCurrentL2,
        'compressor_current_l3': compressorCurrentL3,
        'fan_current_l1': fanCurrentL1,
        'fan_current_l2': fanCurrentL2,
        'fan_current_l3': fanCurrentL3,
        'low_pressure': lowPressure,
        'high_pressure': highPressure,
        'ambient_temperature': ambientTemperature,
        'evaporator_temperature': evaporatorTemperature,
        'gas_charge': gasCharge,
        'observations': observations,
        'signature_path': signaturePath,
        'photos_paths': photosPaths,
      };

  factory Maintenance.fromMap(Map<String, dynamic> map) => Maintenance(
        id: map['id'],
        clientId: map['client_id'],
        equipmentId: map['equipment_id'],
        technician: map['technician'] ?? '',
        date: map['date'] ?? '',
        filterCleaning: map['filter_cleaning'] ?? -1,
        interiorCoilCleaning: map['interior_coil_cleaning'] ?? -1,
        exteriorCoilCleaning: map['exterior_coil_cleaning'] ?? -1,
        voltageL1L2: map['voltage_l1_l2'],
        voltageL2L3: map['voltage_l2_l3'],
        voltageL3L1: map['voltage_l3_l1'],
        compressorCurrentL1: map['compressor_current_l1'],
        compressorCurrentL2: map['compressor_current_l2'],
        compressorCurrentL3: map['compressor_current_l3'],
        fanCurrentL1: map['fan_current_l1'],
        fanCurrentL2: map['fan_current_l2'],
        fanCurrentL3: map['fan_current_l3'],
        lowPressure: map['low_pressure'],
        highPressure: map['high_pressure'],
        ambientTemperature: map['ambient_temperature'],
        evaporatorTemperature: map['evaporator_temperature'],
        gasCharge: map['gas_charge'],
        observations: map['observations'] ?? '',
        signaturePath: map['signature_path'],
        photosPaths: map['photos_paths'],
      );

  Maintenance copyWith({
    int? id,
    int? clientId,
    int? equipmentId,
    String? technician,
    String? date,
    int? filterCleaning,
    int? interiorCoilCleaning,
    int? exteriorCoilCleaning,
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
    String? signaturePath,
    String? photosPaths,
  }) {
    return Maintenance(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      equipmentId: equipmentId ?? this.equipmentId,
      technician: technician ?? this.technician,
      date: date ?? this.date,
      filterCleaning: filterCleaning ?? this.filterCleaning,
      interiorCoilCleaning: interiorCoilCleaning ?? this.interiorCoilCleaning,
      exteriorCoilCleaning: exteriorCoilCleaning ?? this.exteriorCoilCleaning,
      voltageL1L2: voltageL1L2 ?? this.voltageL1L2,
      voltageL2L3: voltageL2L3 ?? this.voltageL2L3,
      voltageL3L1: voltageL3L1 ?? this.voltageL3L1,
      compressorCurrentL1: compressorCurrentL1 ?? this.compressorCurrentL1,
      compressorCurrentL2: compressorCurrentL2 ?? this.compressorCurrentL2,
      compressorCurrentL3: compressorCurrentL3 ?? this.compressorCurrentL3,
      fanCurrentL1: fanCurrentL1 ?? this.fanCurrentL1,
      fanCurrentL2: fanCurrentL2 ?? this.fanCurrentL2,
      fanCurrentL3: fanCurrentL3 ?? this.fanCurrentL3,
      lowPressure: lowPressure ?? this.lowPressure,
      highPressure: highPressure ?? this.highPressure,
      ambientTemperature: ambientTemperature ?? this.ambientTemperature,
      evaporatorTemperature:
          evaporatorTemperature ?? this.evaporatorTemperature,
      gasCharge: gasCharge ?? this.gasCharge,
      observations: observations ?? this.observations,
      signaturePath: signaturePath ?? this.signaturePath,
      photosPaths: photosPaths ?? this.photosPaths,
    );
  }
}
