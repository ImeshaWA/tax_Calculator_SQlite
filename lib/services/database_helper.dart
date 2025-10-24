//services/database_helper.dart
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../models/user_model.dart';

class DatabaseHelper {
  static const _databaseName = "TaxCalculator.db";
  static const _databaseVersion = 2;

  // --- Users Table ---
  static const tableUsers = 'users';
  static const columnId = 'id';
  static const columnUsername = 'username';
  static const columnPassword = 'password';

  // --- NEW: Tax Data Table ---
  static const tableTaxData = 'tax_data';
  static const columnDataId = 'id';
  static const columnUserId = 'userId';
  static const columnTaxYear = 'taxYear';
  static const columnData = 'data'; // Will store all tax data as a JSON string

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future _initDatabase() async {
  Directory documentsDirectory = await getApplicationDocumentsDirectory();
  String path = join(documentsDirectory.path, _databaseName);
  return await openDatabase(
    path,
    version: _databaseVersion,
    onCreate: _onCreate,
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await db.execute('''
          CREATE TABLE $tableTaxData (
            $columnDataId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnUserId INTEGER NOT NULL,
            $columnTaxYear TEXT NOT NULL,
            $columnData TEXT NOT NULL,
            FOREIGN KEY ($columnUserId) REFERENCES $tableUsers($columnId),
            UNIQUE ($columnUserId, $columnTaxYear)
          )
        ''');
        print('Tax_data table added in upgrade');
      }
    },
  );
}

  Future _onCreate(Database db, int version) async {
    try {
      await db.execute('''
      CREATE TABLE $tableUsers (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnUsername TEXT NOT NULL UNIQUE,
        $columnPassword TEXT NOT NULL
      )
    ''');
      print('Users table created successfully');

      await db.execute('''
      CREATE TABLE $tableTaxData (
        $columnDataId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnUserId INTEGER NOT NULL,
        $columnTaxYear TEXT NOT NULL,
        $columnData TEXT NOT NULL,
        FOREIGN KEY ($columnUserId) REFERENCES $tableUsers($columnId),
        UNIQUE ($columnUserId, $columnTaxYear)
      )
    ''');
      print('Tax_data table created successfully');
    } catch (e) {
      print('Error creating tables: $e');
    }
  }

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // --- User Management Methods (Unchanged) ---
  Future<int?> signUp(User user) async {
    try {
      Database db = await instance.database;
      final hashedPassword = _hashPassword(user.password);
      User newUser = User(username: user.username, password: hashedPassword);
      return await db.insert(tableUsers, newUser.toMap());
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<User?> login(String username, String password) async {
    Database db = await instance.database;
    final hashedPassword = _hashPassword(password);
    List<Map<String, dynamic>> maps = await db.query(tableUsers,
        where: '$columnUsername = ? AND $columnPassword = ?',
        whereArgs: [username, hashedPassword]);
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // --- NEW: Tax Data Methods ---

  // Save (or update) tax data for a user and year.
  Future<int> saveTaxData(int userId, String taxYear, String jsonData) async {
    Database db = await instance.database;
    Map<String, dynamic> row = {
      columnUserId: userId,
      columnTaxYear: taxYear,
      columnData: jsonData,
    };
    // Using `insert` with `conflictAlgorithm.replace` acts as an "upsert".
    // If a row for this user/year exists, it's updated. If not, it's created.
    return await db.insert(tableTaxData, row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Load tax data for a user and year.
  Future<String?> loadTaxData(int userId, String taxYear) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(tableTaxData,
        columns: [columnData],
        where: '$columnUserId = ? AND $columnTaxYear = ?',
        whereArgs: [userId, taxYear]);
    if (maps.isNotEmpty) {
      return maps.first[columnData] as String?;
    }
    return null; // No data found
  }
}
