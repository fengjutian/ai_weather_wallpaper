import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Singleton helper for managing the local SQLite database.
///
/// Provides a single [Database] instance and manages 5 tables:
///   - `weather_cache`   — cached weather forecast data
///   - `scene_cache`     — cached scene/generation parameters
///   - `ai_images`       — metadata of AI-generated wallpaper images
///   - `settings`        — app settings stored relationally
///   - `favorites`       — user's favourite wallpapers
///
/// Usage:
/// ```dart
/// final db = await DatabaseHelper.instance.database;
/// final rows = await DatabaseHelper.instance.query('weather_cache');
/// ```
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  /// The lazily-initialized [Database] instance.
  ///
  /// The database is created once on first access and reused thereafter.
  /// The file is stored at `getDatabasesPath()/ai_weather_wallpaper.db`.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Opens (or creates) the SQLite database file.
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ai_weather_wallpaper.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// Creates all tables on first run.
  ///
  /// Schema matches the definitions in [docs/database.md](https://github.com/...).
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE weather_cache (
        city_id     TEXT PRIMARY KEY,
        weather     TEXT NOT NULL,
        temp        REAL NOT NULL,
        humidity    INTEGER NOT NULL,
        forecast    TEXT,
        fetched_at  TEXT NOT NULL,
        expires_at  TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_weather_expires ON weather_cache(expires_at)
    ''');

    await db.execute('''
      CREATE TABLE scene_cache (
        scene_id    TEXT PRIMARY KEY,
        scene_type  TEXT NOT NULL,
        source_url  TEXT,
        local_path  TEXT,
        thumbnail   BLOB,
        metadata    TEXT,
        created_at  TEXT NOT NULL,
        expires_at  TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ai_images (
        image_id    TEXT PRIMARY KEY,
        prompt      TEXT NOT NULL,
        model       TEXT NOT NULL,
        source_url  TEXT,
        local_path  TEXT,
        width       INTEGER,
        height      INTEGER,
        seed        INTEGER,
        metadata    TEXT,
        created_at  TEXT NOT NULL,
        is_favorite INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_ai_images_fav ON ai_images(is_favorite)
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key         TEXT PRIMARY KEY,
        value       TEXT NOT NULL,
        updated_at  TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        favorite_id  TEXT PRIMARY KEY,
        scene_id     TEXT NOT NULL,
        scene_type   TEXT NOT NULL,
        added_at     TEXT NOT NULL,
        sort_order   INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_favorites_sort ON favorites(sort_order)
    ''');
  }

  /// Inserts a [row] into the specified [table].
  ///
  /// Throws a [DatabaseException] on constraint violation or other errors.
  Future<void> insert(String table, Map<String, dynamic> row) async {
    final db = await database;
    await db.insert(table, row);
  }

  /// Updates rows in [table] matching `[whereCol] = [whereVal]` with the
  /// values in [row].
  Future<void> update(
    String table,
    Map<String, dynamic> row,
    String whereCol,
    dynamic whereVal,
  ) async {
    final db = await database;
    await db.update(
      table,
      row,
      where: '$whereCol = ?',
      whereArgs: [whereVal],
    );
  }

  /// Queries rows from [table] with optional [where] clause, [whereArgs],
  /// and [orderBy].
  ///
  /// [whereArgs] can be a single value or a `List<dynamic>` for multiple
  /// placeholders. Returns an empty list when no rows match.
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    dynamic whereArgs,
    String? orderBy,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs != null
          ? (whereArgs is List ? whereArgs as List : [whereArgs])
          : null,
      orderBy: orderBy,
    );
  }

  /// Queries a single row from [table], or `null` if no row matches.
  ///
  /// This is a convenience wrapper around [query] that returns the first
  /// result (if any).
  Future<Map<String, dynamic>?> queryOne(
    String table, {
    String? where,
    dynamic whereArgs,
  }) async {
    final rows = await query(
      table,
      where: where,
      whereArgs: whereArgs,
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  /// Deletes rows from [table] matching the optional [where] clause.
  ///
  /// [whereArgs] can be a single value or a `List<dynamic>` for multiple
  /// placeholders.  When both [where] and [whereArgs] are omitted **all**
  /// rows are deleted — use with care.
  Future<void> delete(
    String table, {
    String? where,
    dynamic whereArgs,
  }) async {
    final db = await database;
    await db.delete(
      table,
      where: where,
      whereArgs: whereArgs != null
          ? (whereArgs is List ? whereArgs as List : [whereArgs])
          : null,
    );
  }

  /// Returns the total number of rows in [table].
  Future<int> count(String table) async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) AS cnt FROM $table');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Deletes all rows in [table] where `[expiresCol]` is earlier than now.
  ///
  /// [expiresCol] should store ISO-8601 timestamps (e.g. `'2025-06-18T12:00:00'`).
  Future<void> deleteExpired(String table, String expiresCol) async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.delete(
      table,
      where: '$expiresCol < ?',
      whereArgs: [now],
    );
  }

  /// Closes the database connection.
  ///
  /// After calling this method the singleton's internal reference is set to
  /// `null` so the next access to [database] will re-open the file.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
