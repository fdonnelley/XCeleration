import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Initialize or open the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('runners.db');
    return _database!;
  }

  // Initialize database
  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // Create database tables
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE runners (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        grade INTEGER NOT NULL,
        school TEXT NOT NULL,
        bib_number TEXT NOT NULL UNIQUE
      )
    ''');
  }

  // Insert a runner into the database
  Future<void> insertRunner(String name, int grade, String school, String bibNumber) async {
    final db = await instance.database;

    await db.insert(
      'runners',
      {
        'name': name,
        'grade': grade,
        'school': school,
        'bib_number': bibNumber,
      },
      conflictAlgorithm: ConflictAlgorithm.replace, // Replace if bib number exists
    );
  }

  // Fetch all runners from the database
  Future<List<Map<String, dynamic>>> fetchAllRunners() async {
    final db = await instance.database;
    return await db.query('runners');
  }

  // Fetch a specific runner by bib number
  Future<Map<String, dynamic>?> fetchRunnerByBibNumber(String bibNumber) async {
    final db = await instance.database;
    final results = await db.query(
      'runners',
      where: 'bib_number = ?',
      whereArgs: [bibNumber],
    );

    return results.isNotEmpty ? results.first : null;
  }

  // Update a runner's information
  Future<void> updateRunner(int id, String name, int grade, String school, String bibNumber) async {
    final db = await instance.database;

    await db.update(
      'runners',
      {
        'name': name,
        'grade': grade,
        'school': school,
        'bib_number': bibNumber,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete a runner from the database
  Future<void> deleteRunner(String bibNumber) async {
    final db = await instance.database;
    await db.delete(
      'runners',
      where: 'bib_number = ?',
      whereArgs: [bibNumber],
    );
  }

  Future<void> deleteAllRunners() async {
    final db = await instance.database;
    await db.rawDelete('DELETE FROM runners');

  }

  Future<void> deleteDatabaseFile() async {
    // Get the path to the database file
    String path = join(await getDatabasesPath(), 'runners.db');
    
    // Delete the database
    await deleteDatabase(path);
    
    print("Database deleted successfully.");
  }

  // Close the database connection
  Future<void> close() async {
    final db = await instance.database;
    print("Closing databese connection");
    await db.close();
  }
}
