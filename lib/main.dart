import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

void main() {
  runApp(const QuizApp());
}

const Color primaryTeal = Color(0xFF06665D);
const Color bgColor = Color(0xFFF5F5F5);
const Color textColor = Color(0xFF3F4654);

class SlidePageRoute extends PageRouteBuilder {
  final Widget page;
  SlidePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.1);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quizze',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bgColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryTeal,
          primary: primaryTeal,
          background: bgColor,
        ),
        fontFamily: 'Nunito',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
            backgroundColor: primaryTeal,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? '';
    });
  }

  Future<void> _saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Fix UI overflow when keyboard pops up
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // App Icon Graphic
              Container(
                height: 250,
                width: 250,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 2)
                  ]
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/icon.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 50),
              const Text(
                'Quizze',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _nameController,
                  textAlign: TextAlign.center,
                  onChanged: _saveName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 18),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Save name just in case before navigating
                    _saveName(_nameController.text);
                    Navigator.push(
                      context,
                      SlidePageRoute(page: const CategoriesScreen()),
                    );
                  },
                  child: const Text('GET STARTED', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late Future<List<Category>> _categoriesFuture;
  final List<Color> _cardColors = [
    const Color(0xFFC5DAFF), // Blue
    const Color(0xFFC2F1CB), // Green
    const Color(0xFFFDF0B9), // Yellow
    const Color(0xFFF2CAFF), // Purple
    const Color(0xFFFFC3C6), // Red
    const Color(0xFFFFE3B9), // Orange
  ];

  @override
  void initState() {
    super.initState();
    _categoriesFuture = ApiService.getCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quizze',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'choose a category to focus on:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Category>>(
                future: _categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No categories found.'));
                  }

                  final categories = snapshot.data!;
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final color = _cardColors[index % _cardColors.length];
                      
                      IconData iconData = Icons.category;
                      String lowerName = category.name.toLowerCase();
                      if (lowerName.contains('general')) iconData = Icons.public;
                      else if (lowerName.contains('book')) iconData = Icons.menu_book;
                      else if (lowerName.contains('film')) iconData = Icons.movie;
                      else if (lowerName.contains('music')) iconData = Icons.music_note;
                      else if (lowerName.contains('television')) iconData = Icons.tv;
                      else if (lowerName.contains('video game')) iconData = Icons.sports_esports;
                      else if (lowerName.contains('science')) iconData = Icons.biotech;
                      else if (lowerName.contains('computer')) iconData = Icons.computer;
                      else if (lowerName.contains('sport')) iconData = Icons.sports_soccer;
                      else if (lowerName.contains('geography')) iconData = Icons.map;
                      else if (lowerName.contains('history')) iconData = Icons.history_edu;
                      else if (lowerName.contains('politic')) iconData = Icons.gavel;
                      else if (lowerName.contains('art')) iconData = Icons.palette;
                      else if (lowerName.contains('animal')) iconData = Icons.pets;
                      else if (lowerName.contains('vehicle')) iconData = Icons.directions_car;

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            SlidePageRoute(
                              page: ConfigScreen(category: category, color: color),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Center(
                                  child: Icon(iconData, size: 70, color: Colors.black54),
                                ),
                              ),
                              Text(
                                category.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConfigScreen extends StatefulWidget {
  final Category category;
  final Color color;
  
  const ConfigScreen({super.key, required this.category, required this.color});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  int _amount = 10;
  String _difficulty = 'Any Difficulty';
  String _type = 'Multiple Choice';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top illustration placeholder
              Center(
                child: Container(
                  height: 140,
                  width: 160,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Center(
                    child: Icon(Icons.tune_rounded, size: 80, color: Colors.black54),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Quizze',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: textColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Configuration',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                widget.category.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              
              // Number of Questions
              Row(
                children: [
                  const Icon(Icons.format_list_numbered, color: primaryTeal, size: 24),
                  const SizedBox(width: 8),
                  const Text('Number of Questions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: primaryTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text('$_amount', style: const TextStyle(color: primaryTeal, fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: primaryTeal,
                  inactiveTrackColor: Colors.grey.shade200,
                  thumbColor: primaryTeal,
                  trackHeight: 6,
                  overlayShape: SliderComponentShape.noOverlay,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                ),
                child: Slider(
                  value: _amount.toDouble(),
                  min: 5,
                  max: 50,
                  divisions: 9,
                  onChanged: (value) {
                    setState(() {
                      _amount = value.toInt();
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              
              // Difficulty Level
              Row(
                children: [
                  const Icon(Icons.speed, color: primaryTeal, size: 24),
                  const SizedBox(width: 8),
                  const Text('Difficulty Level', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _difficulty,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: textColor),
                    dropdownColor: Colors.white,
                    items: ['Any Difficulty', 'Easy', 'Medium', 'Hard'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: textColor)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _difficulty = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Question Type
              Row(
                children: [
                  const Icon(Icons.fact_check_outlined, color: primaryTeal, size: 24),
                  const SizedBox(width: 8),
                  const Text('Question Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _type,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: textColor),
                    dropdownColor: Colors.white,
                    items: ['Multiple Choice', 'True / False'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: textColor)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _type = value);
                    },
                  ),
                ),
              ),
              
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    String diffParam = _difficulty == 'Any Difficulty' ? '' : _difficulty.toLowerCase();
                    String typeParam = _type == 'True / False' ? 'boolean' : 'multiple';
                    Navigator.push(
                      context,
                      SlidePageRoute(
                        page: QuizScreen(
                          categoryId: widget.category.id,
                          amount: _amount,
                          difficulty: diffParam,
                          type: typeParam,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryTeal, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: Colors.white,
                  ),
                  child: const Text('START', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: primaryTeal, letterSpacing: 1.0)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class QuizScreen extends StatefulWidget {
  final int categoryId;
  final int amount;
  final String difficulty;
  final String type;

  const QuizScreen({super.key, required this.categoryId, required this.amount, required this.difficulty, required this.type});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late Future<List<Question>> _questionsFuture;
  int _currentIndex = 0;
  int _score = 0;
  bool _answered = false;
  String _selectedAnswer = '';
  final HtmlUnescape _unescape = HtmlUnescape();

  @override
  void initState() {
    super.initState();
    _questionsFuture = ApiService.getQuestions(widget.amount, widget.categoryId, widget.difficulty, widget.type);
  }

  void _submitAnswer(String answer, Question question) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      if (answer == question.correctAnswer) {
        _score++;
      }
    });
  }

  void _nextQuestion(List<Question> questions) {
    if (_currentIndex < questions.length - 1) {
      setState(() {
        _currentIndex++;
        _answered = false;
        _selectedAnswer = '';
      });
    } else {
      Navigator.pushReplacement(
        context,
        SlidePageRoute(
          page: ResultsScreen(score: _score, total: questions.length),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<Question>>(
          future: _questionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              String errorMsg = snapshot.error.toString().replaceAll('Exception: ', '');
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 80, color: Colors.redAccent),
                      const SizedBox(height: 24),
                      Text(
                        errorMsg, 
                        textAlign: TextAlign.center, 
                        style: const TextStyle(fontSize: 18, color: textColor, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 32),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: primaryTeal, width: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: const Text('GO BACK', style: TextStyle(color: primaryTeal, fontWeight: FontWeight.w900)),
                      )
                    ]
                  )
                )
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No questions available for this configuration.'));
            }

            final questions = snapshot.data!;
            final question = questions[_currentIndex];
            final decodedQuestionText = _unescape.convert(question.question);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 60), // Spacer for centering
                      Text('${_currentIndex + 1}/${questions.length}', style: const TextStyle(fontWeight: FontWeight.w900, color: textColor, fontSize: 16)),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        child: const Row(
                          children: [
                            Text('EXIT', style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 14)),
                            SizedBox(width: 4),
                            Icon(Icons.logout, color: textColor, size: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Progress Bar
                  LinearProgressIndicator(
                    value: (_currentIndex + 1) / questions.length,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    borderRadius: BorderRadius.circular(10),
                    minHeight: 6,
                  ),
                  const SizedBox(height: 32),
                  
                  // Question Card
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                              ]
                            ),
                            child: Text(
                              decodedQuestionText,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.5, color: textColor),
                            ),
                          ),
                          const SizedBox(height: 40),
                          
                          // Answers
                          ...question.allAnswers.map((answer) {
                            final decodedAnswer = _unescape.convert(answer);
                            
                            Color cardColor = Colors.white;
                            Color answerTextColor = textColor;
                            Widget trailingIcon = const Icon(Icons.circle_outlined, color: Colors.black54, size: 24);

                            if (_answered) {
                              if (answer == question.correctAnswer && answer == _selectedAnswer) {
                                cardColor = const Color(0xFFABCDBE); // Green
                                answerTextColor = const Color(0xFF0F5A4F);
                                trailingIcon = const Icon(Icons.check_circle, color: Color(0xFF0F5A4F), size: 24);
                              } else if (answer == _selectedAnswer) {
                                cardColor = const Color(0xFFF19E9E); // Red
                                answerTextColor = const Color(0xFFB71C1C);
                                trailingIcon = const Icon(Icons.cancel, color: Color(0xFFD32F2F), size: 24);
                              }
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => _submitAnswer(answer, question),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          decodedAnswer,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: answerTextColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      trailingIcon,
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  
                  // Next Button
                  if (_answered)
                    ElevatedButton(
                      onPressed: () => _nextQuestion(questions),
                      child: Text(
                        _currentIndex < questions.length - 1 ? 'Next' : 'Results',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                      ),
                    )
                  else
                    const SizedBox(height: 60), // Maintain space for button
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class ResultsScreen extends StatelessWidget {
  final int score;
  final int total;

  const ResultsScreen({super.key, required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    final percentage = (score / total) * 100;
    final isSuccess = percentage >= 50; 
    
    final String title = isSuccess ? "Congratulation" : "Keep Trying!";
    final String message = isSuccess 
        ? "You've got a great foundation. Ready to try a\ndifferent category?"
        : "Dont give up! Practice makes perfect. Try\nagain to improve your score";
        
    final Color boxBgColor = isSuccess ? const Color(0xFF7DE199) : const Color(0xFFFF4800);
    final Color boxBorderColor = isSuccess ? const Color(0xFFE4F7EA) : const Color(0xFFFFC9B8);
    final Color percentageTextColor = isSuccess ? textColor : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Top illustration placeholder
              Center(
                child: Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    color: isSuccess ? Colors.pink.shade100 : Colors.blue.shade100,
                    shape: isSuccess ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: isSuccess ? null : BorderRadius.circular(32),
                  ),
                  child: Center(
                    child: Icon(
                      isSuccess ? Icons.celebration : Icons.tune_rounded,
                      size: 100,
                      color: isSuccess ? Colors.pink : Colors.black54,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: textColor),
              ),
              const SizedBox(height: 32),
              
              // Score Box
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: boxBorderColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: boxBgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '${percentage.toInt()}%',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: percentageTextColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      SlidePageRoute(page: const CategoriesScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('PLAY AGAIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
