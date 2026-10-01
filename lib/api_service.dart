import 'dart:convert';
import 'package:http/http.dart' as http;
import 'database_helper.dart';

class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Question {
  final String category;
  final String type;
  final String difficulty;
  final String question;
  final String correctAnswer;
  final List<String> incorrectAnswers;
  late final List<String> allAnswers;

  Question({
    required this.category,
    required this.type,
    required this.difficulty,
    required this.question,
    required this.correctAnswer,
    required this.incorrectAnswers,
  }) {
    allAnswers = List.from(incorrectAnswers)..add(correctAnswer);
    allAnswers.shuffle();
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      category: json['category'],
      type: json['type'],
      difficulty: json['difficulty'],
      question: json['question'],
      correctAnswer: json['correct_answer'],
      incorrectAnswers: List<String>.from(json['incorrect_answers']),
    );
  }
}

class ApiService {
  static Future<List<Category>> getCategories() async {
    final localCategories = await DatabaseHelper.instance.getLocalCategories();
    if (localCategories.isNotEmpty) {
      return localCategories;
    }
    throw Exception('No categories found in local database.');
  }

  static Future<List<Question>> getQuestions(int amount, int categoryId, String difficulty, String type) async {
    // 1. Try to get questions from the local SQLite database
    final localQuestions = await DatabaseHelper.instance.getLocalQuestions(categoryId, difficulty.toLowerCase(), type, amount);
    
    // 2. If we have enough questions locally, return them!
    if (localQuestions.length >= amount) {
      return localQuestions;
    }

    // 3. Otherwise, fetch them directly from OpenTDB API
    try {
      final url = Uri.parse('https://opentdb.com/api.php?amount=$amount&category=$categoryId&difficulty=${difficulty.toLowerCase()}&type=$type');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['response_code'] == 0) {
          final List<dynamic> results = data['results'];
          
          List<Question> fetchedQuestions = results.map((json) {
            // We override the category string to be the ID so our DB can query it easily
            json['category'] = categoryId.toString();
            return Question.fromJson(json);
          }).toList();

          // 4. Cache them in the local database for next time!
          await DatabaseHelper.instance.cacheQuestions(fetchedQuestions, categoryId, difficulty.toLowerCase(), type);

          return fetchedQuestions;
        } else {
           // Not enough questions in the API for this combo, return whatever we have locally
           if (localQuestions.isNotEmpty) return localQuestions;
           throw Exception("Not enough questions exist for this specific configuration.\n\nTry lowering the 'Number of Questions', or selecting 'Multiple Choice'.");
        }
      } else {
        throw Exception('Failed to connect to OpenTDB API');
      }
    } catch (e) {
      // If network fails (like your timeout), just return local questions if we have any
      if (localQuestions.isNotEmpty) return localQuestions;
      throw Exception('Network error and no local offline data available. Please check your VPN/connection.');
    }
  }
}
