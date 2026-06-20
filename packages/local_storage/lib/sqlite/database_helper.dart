import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Singleton helper for managing the local SQLite database.
///
/// Provides a single [Database] instance and stub table names for:
///   - `weather_cache`   — cached weather forecast data
///   - `scene_cache`     — cached scene/generation parameters
///   - `ai_images`       — metadata of AI-generated wallpaper images
///   - `settings`        — app settings stored relationally
///   - `favorites`       — user's favourite wallpapers
///
/// Usage:
/// ```dart
/// final db = await DatabaseHelper.instance.database;
/// final rows = await db.query('weather_cache');
/// ```
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  /// The lazily-initialized [Database] instance.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ai_weather_wallpaper.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// Creates all stub tables on first run.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE weather_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        city TEXT NOT NULL,
        data TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE scene_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scene_key TEXT NOT NULL UNIQUE,
        data TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ai_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_url TEXT NOT NULL,
        prompt TEXT,
        scene_label TEXT,
        created_at INTEGER NOT NULL,
        file_path TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_id INTEGER NOT NULL,
        added_at INTEGER NOT NULL,
        FOREIGN KEY (image_id) REFERENCES ai_images(id)
      )
    ''');
  }

  /// Close the database. Call when the app terminates.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
