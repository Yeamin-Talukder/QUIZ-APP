import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'api_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('quiz_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      final path = filePath;
      return await openDatabase(
        path,
        version: 6,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );
    } else {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      return await openDatabase(
        path,
        version: 6,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );
    }
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    await db.execute('DROP TABLE IF EXISTS questions');
    await db.execute('DROP TABLE IF EXISTS categories');
    await _createDB(db, newVersion);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        question TEXT NOT NULL,
        correct_answer TEXT NOT NULL,
        incorrect_answers TEXT NOT NULL
      )
    ''');
    
    // Seed categories based on UI (15 categories)
    await db.insert('categories', {'id': 9, 'name': 'General Knowledge'});
    await db.insert('categories', {'id': 10, 'name': 'Books'});
    await db.insert('categories', {'id': 11, 'name': 'Film'});
    await db.insert('categories', {'id': 12, 'name': 'Music'});
    await db.insert('categories', {'id': 14, 'name': 'Television'});
    await db.insert('categories', {'id': 15, 'name': 'Video Games'});
    await db.insert('categories', {'id': 17, 'name': 'Science & Nature'});
    await db.insert('categories', {'id': 18, 'name': 'Computers'});
    await db.insert('categories', {'id': 21, 'name': 'Sports'});
    await db.insert('categories', {'id': 22, 'name': 'Geography'});
    await db.insert('categories', {'id': 23, 'name': 'History'});
    await db.insert('categories', {'id': 24, 'name': 'Politics'});
    await db.insert('categories', {'id': 25, 'name': 'Art'});
    await db.insert('categories', {'id': 27, 'name': 'Animals'});
    await db.insert('categories', {'id': 28, 'name': 'Vehicles'});
    
    // Load offline questions from JSON asset
    try {
      final String jsonString = await rootBundle.loadString('assets/questions.json');
      final List<dynamic> questionsList = json.decode(jsonString);
      
      Batch batch = db.batch();
      for (var q in questionsList) {
        batch.insert('questions', {
          'category': q['category_id'] ?? q['category'], // Fallback for old data
          'type': q['type'],
          'difficulty': q['difficulty'],
          'question': q['question'],
          'correct_answer': q['correct_answer'],
          'incorrect_answers': json.encode(q['incorrect_answers']),
        });
      }
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint("Error loading offline questions: $e");
    }
  }

  // --- Category Methods ---
  Future<void> cacheCategories(List<Category> categories) async {
    final db = await instance.database;
    Batch batch = db.batch();
    for (var category in categories) {
      batch.insert('categories', {
        'id': category.id,
        'name': category.name,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Category>> getLocalCategories() async {
    final db = await instance.database;
    final result = await db.query('categories');
    return result.map((json) => Category(
      id: json['id'] as int,
      name: json['name'] as String,
    )).toList();
  }

  // --- Question Methods ---
  Future<void> cacheQuestions(List<Question> questions, int categoryId, String difficulty, String type) async {
    final db = await instance.database;
    
    // Clear old questions for this category, difficulty and type
    if (difficulty.isEmpty) {
      await db.delete(
        'questions', 
        where: 'category = ? AND type = ?', 
        whereArgs: [categoryId.toString(), type]
      );
    } else {
      await db.delete(
        'questions', 
        where: 'category = ? AND difficulty = ? AND type = ?', 
        whereArgs: [categoryId.toString(), difficulty, type]
      );
    }

    Batch batch = db.batch();
    for (var q in questions) {
      batch.insert('questions', {
        'category': categoryId.toString(),
        'type': q.type,
        'difficulty': q.difficulty,
        'question': q.question,
        'correct_answer': q.correctAnswer,
        'incorrect_answers': json.encode(q.incorrectAnswers),
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<Question>> getLocalQuestions(int categoryId, String difficulty, String type, int limit) async {
    final db = await instance.database;
    List<Map<String, Object?>> result;
    
    if (difficulty.isEmpty) {
      result = await db.query(
        'questions',
        where: 'category = ? AND type = ?',
        whereArgs: [categoryId.toString(), type],
        limit: limit,
      );
    } else {
      result = await db.query(
        'questions',
        where: 'category = ? AND difficulty = ? AND type = ?',
        whereArgs: [categoryId.toString(), difficulty, type],
        limit: limit,
      );
    }
    
    return result.map((jsonMap) {
      return Question(
        category: jsonMap['category'] as String,
        type: jsonMap['type'] as String,
        difficulty: jsonMap['difficulty'] as String,
        question: jsonMap['question'] as String,
        correctAnswer: jsonMap['correct_answer'] as String,
        incorrectAnswers: List<String>.from(json.decode(jsonMap['incorrect_answers'] as String)),
      );
    }).toList();
  }
}
