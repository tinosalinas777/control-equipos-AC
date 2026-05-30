import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/client.dart';
import '../models/equipment.dart';
import '../models/maintenance.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('maintenance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        plant TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE equipments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id INTEGER NOT NULL,
        number INTEGER NOT NULL,
        location TEXT NOT NULL,
        capacity TEXT NOT NULL,
        type TEXT NOT NULL,
        refrigerant TEXT NOT NULL,
        brand TEXT NOT NULL,
        FOREIGN KEY (client_id) REFERENCES clients(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE maintenances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id INTEGER NOT NULL,
        equipment_id INTEGER NOT NULL,
        technician TEXT,
        date TEXT,
        filter_cleaning INTEGER DEFAULT -1,
        interior_coil_cleaning INTEGER DEFAULT -1,
        exterior_coil_cleaning INTEGER DEFAULT -1,
        voltage_l1_l2 REAL,
        voltage_l2_l3 REAL,
        voltage_l3_l1 REAL,
        compressor_current_l1 REAL,
        compressor_current_l2 REAL,
        compressor_current_l3 REAL,
        fan_current_l1 REAL,
        fan_current_l2 REAL,
        fan_current_l3 REAL,
        low_pressure REAL,
        high_pressure REAL,
        ambient_temperature REAL,
        evaporator_temperature REAL,
        gas_charge REAL,
        observations TEXT,
        signature_path TEXT,
        photos_paths TEXT,
        pdf_path TEXT,
        FOREIGN KEY (client_id) REFERENCES clients(id),
        FOREIGN KEY (equipment_id) REFERENCES equipments(id)
      )
    ''');

    // Seed: cliente principal
    final clientId = await db.insert('clients', {
      'name': 'Planta José L. Suárez',
      'plant': 'José L. Suárez',
    });

    // Seed: los 35 equipos del Excel
    final equipments = [
      [1, 'El Molino', '12000', 'Piso/Techo', 'R22', 'LG'],
      [2, 'Sala de Servidores', '2250', 'Split', 'R410', ''],
      [3, 'OF. Mejora Continua', '3000', 'Split', 'R410', 'LG'],
      [4, 'Recepción Oficina', '4500', 'Split', 'R410', 'Coventry'],
      [5, 'RRHH', '3000', 'Split', 'R410', 'Carrier'],
      [6, 'Gerente Financiero', '3000', 'Split', 'R410', 'Carrier'],
      [7, 'Oficina Contabilidad', '3000', 'Split', 'R410', 'Samsung'],
      [8, 'Comedor Oficina', '3000', 'Split', 'R410', 'LG'],
      [9, 'Costos', '3000', 'Split', 'R410', 'Alaska'],
      [10, 'Compras y Pagos', '3000', 'Split', 'R410', 'Samsung'],
      [11, 'Matricería', '18000', 'Piso/Techo', 'R410', 'BGH'],
      [12, 'Programación', '6000', 'Split', 'R410', 'BGH'],
      [13, 'Oficina de Diseño', '2000', 'Split', 'R410', 'York'],
      [14, 'Taller Fotoserigrafía', '6000', 'Split', 'R410', 'BGH'],
      [15, 'Coord. Seg. e Higiene', '3000', 'Split', 'R410', 'Coventry'],
      [17, 'Oficina Jefe de Matricería', '3000', 'Split', 'R22', 'Philco'],
      [18, 'Taller de Mant. (1)', '4500', 'Multisplit', 'R410', 'BGH'],
      [19, 'Taller de Mant. (2)', '4500', 'Multisplit', 'R410', 'BGH'],
      [20, 'Taller de Mant. (3)', '4500', 'Multisplit', 'R410', 'BGH'],
      [21, 'Jefe de Planta', '3000', 'Split', 'R22', 'Carrier'],
      [22, 'Vigilancia/Hall de Entrada', '2000', 'Split', 'R410', 'BGH'],
      [23, 'Comedor Empleados', '4500', 'Split', 'R410', 'Surrey'],
      [24, 'Gerente Comercial', '3000', 'Split', 'R410', 'York'],
      [25, 'Cuentas Especiales', '3000', 'Split', 'R410', 'York'],
      [26, 'Sala Comercial', '3000', 'Split', 'R410', 'York'],
      [27, 'Sala Administrativa', '3000', 'Split', 'R410', 'York'],
      [28, 'Ventas', '6000', 'Split', 'R410', 'York'],
      [29, 'Logística', '4500', 'Split', 'R410', 'Surrey'],
      [30, 'Oficina Jefa Calidad', '3000', 'Split', 'R22', 'Surrey'],
      [31, 'Oficina BPM Calidad', '3000', 'Split', 'R410', 'TCL'],
      [32, 'Secretaria Gerente General', '3000', 'Split', 'R410', 'BGH'],
      [33, 'Oficina Gerente Manufactura', '3000', 'Split', 'R410', ''],
      [34, 'Sector Calidad', '4500', 'Split', 'R410', ''],
      [35, 'Oficinas Munro', '4500', 'Split', 'R410', ''],
    ];

    for (final e in equipments) {
      await db.insert('equipments', {
        'client_id': clientId,
        'number': e[0],
        'location': e[1],
        'capacity': e[2],
        'type': e[3],
        'refrigerant': e[4],
        'brand': e[5],
      });
    }
  }

  // ── CLIENTS ──────────────────────────────────────────
  Future<List<Client>> getClients() async {
    final db = await database;
    final maps = await db.query('clients');
    return maps.map((m) => Client.fromMap(m)).toList();
  }

  Future<int> insertClient(Client client) async {
    final db = await database;
    return await db.insert('clients', client.toMap()..remove('id'));
  }

  // ── EQUIPMENTS ───────────────────────────────────────
  Future<List<Equipment>> getEquipmentsByClient(int clientId) async {
    final db = await database;
    final maps = await db.query(
      'equipments',
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'number ASC',
    );
    return maps.map((m) => Equipment.fromMap(m)).toList();
  }

  Future<Equipment?> getEquipment(int id) async {
    final db = await database;
    final maps =
        await db.query('equipments', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Equipment.fromMap(maps.first);
  }

  Future<int> insertEquipment(Equipment equipment) async {
    final db = await database;
    return await db.insert('equipments', equipment.toMap()..remove('id'));
  }

  Future<int> deleteEquipment(int id) async {
    final db = await database;
    // Borra también los mantenimientos asociados
    await db.delete('maintenances', where: 'equipment_id = ?', whereArgs: [id]);
    return await db.delete('equipments', where: 'id = ?', whereArgs: [id]);
  }

  // ── MAINTENANCES ─────────────────────────────────────
  Future<int> insertMaintenance(Maintenance maintenance) async {
    final db = await database;
    return await db.insert('maintenances', maintenance.toMap()..remove('id'));
  }

  Future<int> updateMaintenance(Maintenance maintenance) async {
    final db = await database;
    return await db.update(
      'maintenances',
      maintenance.toMap(),
      where: 'id = ?',
      whereArgs: [maintenance.id],
    );
  }

  Future<List<Map<String, dynamic>>> getMaintenancesWithDetails() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT m.*, 
             c.name as client_name, c.plant as client_plant,
             e.number as eq_number, e.location as eq_location,
             e.brand as eq_brand, e.type as eq_type
      FROM maintenances m
      LEFT JOIN clients c ON m.client_id = c.id
      LEFT JOIN equipments e ON m.equipment_id = e.id
      ORDER BY m.id DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getMaintenancesByEquipment(
      int equipmentId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT m.*, c.name as client_name, e.location as eq_location
      FROM maintenances m
      LEFT JOIN clients c ON m.client_id = c.id
      LEFT JOIN equipments e ON m.equipment_id = e.id
      WHERE m.equipment_id = ?
      ORDER BY m.id DESC
    ''', [equipmentId]);
  }

  Future<Maintenance?> getMaintenance(int id) async {
    final db = await database;
    final maps =
        await db.query('maintenances', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Maintenance.fromMap(maps.first);
  }

  Future<int> savePdfPath(int maintenanceId, String pdfPath) async {
    final db = await database;
    return await db.update(
      'maintenances',
      {'pdf_path': pdfPath},
      where: 'id = ?',
      whereArgs: [maintenanceId],
    );
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
