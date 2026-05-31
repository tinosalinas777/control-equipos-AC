import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class TrialService {
  static const _trialDays = 2;

  static Future<Database> _openDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'trial.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE trial (key TEXT PRIMARY KEY, value TEXT)',
        );
      },
    );
  }

  static Future<bool> isTrialActive() async {
    final db = await _openDb();
    final rows = await db.query(
      'trial',
      where: 'key = ?',
      whereArgs: ['first_launch'],
    );

    if (rows.isEmpty) {
      await db.insert('trial', {
        'key': 'first_launch',
        'value': DateTime.now().millisecondsSinceEpoch.toString(),
      });
      return true;
    }

    final firstMs = int.parse(rows.first['value'] as String);
    final first = DateTime.fromMillisecondsSinceEpoch(firstMs);
    final expiry = first.add(const Duration(days: _trialDays));
    return DateTime.now().isBefore(expiry);
  }

  static Future<int> daysRemaining() async {
    final db = await _openDb();
    final rows = await db.query(
      'trial',
      where: 'key = ?',
      whereArgs: ['first_launch'],
    );
    if (rows.isEmpty) return _trialDays;

    final firstMs = int.parse(rows.first['value'] as String);
    final first = DateTime.fromMillisecondsSinceEpoch(firstMs);
    final expiry = first.add(const Duration(days: _trialDays));
    final diff = expiry.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }
}
