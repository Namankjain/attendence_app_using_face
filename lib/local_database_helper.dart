import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart'; // For debugPrint

// ============================================================================
// Data Model: Faculty
// ============================================================================
class Faculty {
  final int? id;
  final String name;
  final String facultyId;
  final List<double> embeddings;
  final DateTime registrationDate;

  Faculty({
    this.id,
    required this.name,
    required this.facultyId,
    required this.embeddings,
    required this.registrationDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'facultyId': facultyId,
      'embeddings': jsonEncode(embeddings),
      'registrationDate': registrationDate.toIso8601String(),
    };
  }

  factory Faculty.fromMap(Map<String, dynamic> map) {
    return Faculty(
      id: map['id'] as int?,
      name: map['name'] as String,
      facultyId: map['facultyId'] as String,
      embeddings: List<double>.from(jsonDecode(map['embeddings'] as String)),
      registrationDate: DateTime.parse(map['registrationDate'] as String),
    );
  }

  @override
  String toString() {
    return 'Faculty(id: $id, name: $name, facultyId: $facultyId, embeddings: [${embeddings.length} elements], registrationDate: $registrationDate)';
  }
}

// ============================================================================
// Data Model: AttendanceRecord
// ============================================================================
class AttendanceRecord {
  final int? id;
  final String facultyId;
  final DateTime timestamp;
  final String status;

  AttendanceRecord({
    this.id,
    required this.facultyId,
    required this.timestamp,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'facultyId': facultyId,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] as int?,
      facultyId: map['facultyId'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      status: map['status'] as String,
    );
  }

  @override
  String toString() {
    return 'AttendanceRecord(id: $id, facultyId: $facultyId, timestamp: $timestamp, status: $status)';
  }
}

// ============================================================================
// Data Model: AttendanceRecordWithFacultyName
// ============================================================================
class AttendanceRecordWithFacultyName {
  final int? id;
  final String facultyId;
  final String facultyName;
  final DateTime timestamp;
  final String status;

  AttendanceRecordWithFacultyName({
    this.id,
    required this.facultyId,
    required this.facultyName,
    required this.timestamp,
    required this.status,
  });

  factory AttendanceRecordWithFacultyName.fromMap(Map<String, dynamic> map) {
    return AttendanceRecordWithFacultyName(
      id: map['id'] as int?,
      facultyId: map['facultyId'] as String,
      facultyName: map['faculty_name'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      status: map['status'] as String,
    );
  }

  @override
  String toString() {
    return 'AttendanceRecordWithFacultyName(id: $id, facultyId: $facultyId, facultyName: $facultyName, timestamp: $timestamp, status: $status)';
  }
}

// ============================================================================
// DatabaseHelper Class - Manages database initialization and all CRUD operations
// ============================================================================
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'attendance_database.db');
    debugPrint('Database path: $path');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        debugPrint('Creating database tables for version $version...');
        await db.execute('''
          CREATE TABLE faculty(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            facultyId TEXT UNIQUE NOT NULL,
            embeddings TEXT NOT NULL,
            registrationDate TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE attendance(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            facultyId TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            status TEXT NOT NULL,
            FOREIGN KEY (facultyId) REFERENCES faculty(facultyId) ON DELETE CASCADE
          )
        ''');
        debugPrint('Tables created: faculty, attendance');
        // Removed _insertDummyData call from onCreate
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        debugPrint('Upgrading database from version $oldVersion to $newVersion...');
        if (oldVersion < 2) {
          debugPrint('Migrating to version 2: Adding ON DELETE CASCADE constraint.');
          await db.execute('ALTER TABLE attendance RENAME TO _attendance_old');
          await db.execute('''
            CREATE TABLE attendance(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              facultyId TEXT NOT NULL,
              timestamp TEXT NOT NULL,
              status TEXT NOT NULL,
              FOREIGN KEY (facultyId) REFERENCES faculty(facultyId) ON DELETE CASCADE
            )
          ''');
          await db.execute('''
            INSERT INTO attendance (id, facultyId, timestamp, status)
            SELECT id, facultyId, timestamp, status FROM _attendance_old
          ''');
          await db.execute('DROP TABLE _attendance_old');
          debugPrint('Migration to version 2 complete (ON DELETE CASCADE added).');
        }
      },
      onOpen: (db) {
        debugPrint('Database opened! Current version: ${db.getVersion()}');
      },
    );
  }

  // Removed _insertDummyData as it's no longer needed to insert default faculty.
  // If you need to add faculty for testing, consider doing it directly in the UI
  // or adding a dedicated development-only function.

  // --- Faculty Operations ---
  Future<void> registerFaculty(Faculty faculty) async {
    final db = await database;
    await db.insert(
      'faculty',
      faculty.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('Faculty registered/updated: ${faculty.name} (ID: ${faculty.facultyId})');
  }

  Future<void> updateFaculty(Faculty faculty) async {
    final db = await database;
    await db.update(
      'faculty',
      faculty.toMap(),
      where: 'facultyId = ?',
      whereArgs: [faculty.facultyId],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('Faculty updated: ${faculty.name} (ID: ${faculty.facultyId})');
  }

  Future<void> deleteFaculty(String facultyId) async {
    final db = await database;
    await db.delete(
      'faculty',
      where: 'facultyId = ?',
      whereArgs: [facultyId],
    );
    debugPrint('Faculty deleted: $facultyId');
  }

  Future<List<Faculty>> getAllFacultyWithEmbeddings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('faculty');
    return List.generate(maps.length, (i) {
      return Faculty.fromMap(maps[i]);
    });
  }

  Future<Faculty?> getFacultyByFacultyId(String facultyId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'faculty',
      where: 'facultyId = ?',
      whereArgs: [facultyId],
    );
    if (maps.isNotEmpty) {
      return Faculty.fromMap(maps.first);
    }
    return null;
  }

  // --- Attendance Operations ---
  Future<void> insertAttendance(AttendanceRecord record) async {
    final db = await database;
    final dateOnlyString = DateTime(record.timestamp.year, record.timestamp.month, record.timestamp.day)
        .toIso8601String().substring(0, 10);

    final existingRecords = await db.query(
      'attendance',
      where: 'facultyId = ? AND substr(timestamp, 1, 10) = ?',
      whereArgs: [record.facultyId, dateOnlyString],
    );

    if (existingRecords.isNotEmpty) {
      await db.update(
        'attendance',
        record.toMap(),
        where: 'facultyId = ? AND substr(timestamp, 1, 10) = ?',
        whereArgs: [record.facultyId, dateOnlyString],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('Updated attendance for ${record.facultyId} on $dateOnlyString: ${record.status}');
    } else {
      await db.insert(
        'attendance',
        record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('Inserted attendance for ${record.facultyId} on $dateOnlyString: ${record.status}');
    }
  }

  Future<List<AttendanceRecord>> getAttendanceForDate(DateTime date) async {
    final db = await database;
    final dateOnlyString = DateTime(date.year, date.month, date.day)
        .toIso8601String().substring(0, 10);

    final List<Map<String, dynamic>> maps = await db.query(
      'attendance',
      where: 'substr(timestamp, 1, 10) = ?',
      whereArgs: [dateOnlyString],
    );
    return List.generate(maps.length, (i) {
      return AttendanceRecord.fromMap(maps[i]);
    });
  }

  Future<void> markAttendance(String facultyId, DateTime date, String status) async {
    final db = await database;
    final dateOnlyString = DateTime(date.year, date.month, date.day)
        .toIso8601String().substring(0, 10);

    if (status == 'not_recorded') {
      await db.delete(
        'attendance',
        where: 'facultyId = ? AND substr(timestamp, 1, 10) = ?',
        whereArgs: [facultyId, dateOnlyString],
      );
      debugPrint('Deleted attendance for $facultyId on $dateOnlyString (status: not_recorded)');
    } else {
      final record = AttendanceRecord(
        facultyId: facultyId,
        timestamp: date,
        status: status,
      );
      await insertAttendance(record);
      debugPrint('Marked attendance for $facultyId on $dateOnlyString with status $status');
    }
  }

  Future<List<AttendanceRecord>> getAttendanceRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('attendance', orderBy: 'timestamp DESC');
    return List.generate(maps.length, (i) {
      return AttendanceRecord.fromMap(maps[i]);
    });
  }

  // Gets ALL attendance records, joined with faculty names.
  Future<List<AttendanceRecordWithFacultyName>> getAttendanceRecordsWithFacultyNames() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        A.id,
        A.facultyId,
        F.name AS faculty_name,
        A.timestamp,
        A.status
      FROM attendance A
      JOIN faculty F ON A.facultyId = F.facultyId
      ORDER BY A.timestamp DESC
    ''');

    return List.generate(maps.length, (i) {
      return AttendanceRecordWithFacultyName.fromMap(maps[i]);
    });
  }

  // --- NEW METHOD (REQUIRED FOR faculty_detail_page.dart) ---
  // Gets attendance records for a specific faculty, joined with faculty name.
  Future<List<AttendanceRecordWithFacultyName>> getAttendanceRecordsForFaculty(String facultyId) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        A.id,
        A.facultyId,
        F.name AS faculty_name,
        A.timestamp,
        A.status
      FROM attendance A
      JOIN faculty F ON A.facultyId = F.facultyId
      WHERE A.facultyId = ? -- Filter by the specific facultyId
      ORDER BY A.timestamp DESC
    ''', [facultyId]); // Pass facultyId as an argument to the raw query

    return List.generate(maps.length, (i) {
      return AttendanceRecordWithFacultyName.fromMap(maps[i]);
    });
  }
  // --- END NEW METHOD ---


  Future<void> markAbsentForUnmarkedFaculty() async {
    final db = await database;
    final today = DateTime.now();
    final todayString = DateTime(today.year, today.month, today.day).toIso8601String().substring(0, 10);

    final List<Map<String, dynamic>> facultyMaps = await db.query('faculty', columns: ['facultyId']);
    final List<String> allFacultyIds = facultyMaps.map((map) => map['facultyId'] as String).toList();

    final List<Map<String, dynamic>> attendedMaps = await db.query(
      'attendance',
      columns: ['facultyId'],
      where: 'substr(timestamp, 1, 10) = ?',
      whereArgs: [todayString],
    );
    final List<String> attendedFacultyIds = attendedMaps.map((map) => map['facultyId'] as String).toList();

    final List<String> unmarkedFacultyIds = allFacultyIds
        .where((id) => !attendedFacultyIds.contains(id))
        .toList();

    for (String facultyId in unmarkedFacultyIds) {
      final record = AttendanceRecord(
        facultyId: facultyId,
        timestamp: today,
        status: 'absent',
      );
      await insertAttendance(record);
      debugPrint('Marked absent: $facultyId for today ($todayString)');
    }
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('attendance');
    await db.delete('faculty');
    debugPrint('All data cleared from faculty and attendance tables.');
  }
}