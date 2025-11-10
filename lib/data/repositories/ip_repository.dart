import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/ip_info.dart';
import '../../core/constants/app_constants.dart';

class IpRepository {
  static final IpRepository instance = IpRepository._init();
  static Database? _database;

  IpRepository._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ip_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ipv4 TEXT,
        ipv6 TEXT,
        isp TEXT,
        country TEXT,
        city TEXT,
        latitude REAL,
        longitude REAL,
        timestamp TEXT,
        data TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_timestamp ON ip_history(timestamp)
    ''');
  }

  Future<int> insertIpHistory(IpInfo ipInfo) async {
    final db = await database;
    return await db.insert(
      'ip_history',
      {
        'ipv4': ipInfo.ipv4,
        'ipv6': ipInfo.ipv6,
        'isp': ipInfo.isp,
        'country': ipInfo.country,
        'city': ipInfo.city,
        'latitude': ipInfo.latitude,
        'longitude': ipInfo.longitude,
        'timestamp': ipInfo.timestamp?.toIso8601String(),
        'data': ipInfo.toJson().toString(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getAllIpHistory() async {
    final db = await database;
    return await db.query(
      'ip_history',
      orderBy: 'timestamp DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getIpHistoryByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    return await db.query(
      'ip_history',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [
        start.toIso8601String(),
        end.toIso8601String(),
      ],
      orderBy: 'timestamp DESC',
    );
  }

  Future<int> deleteIpHistory(int id) async {
    final db = await database;
    return await db.delete(
      'ip_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearAllHistory() async {
    final db = await database;
    return await db.delete('ip_history');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

