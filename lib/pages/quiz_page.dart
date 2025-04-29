import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import '../config/theme_provider.dart';
import '../config/api_keys.dart';

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  bool isAnswered = false;
  int? selectedAnswerIndex;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
  });
}

class QuizPage extends StatefulWidget {
  final String topic;
  final String content;

  const QuizPage({
    super.key,
    required this.topic,
    required this.content,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late List<QuizQuestion> questions;
  int currentIndex = 0;
  int score = 0;
  bool showResults = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateQuestions();
  }

  Future<void> _generateQuestions() async {
    try {
      final apiKey = await ApiKeys.geminiApiKey;
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
      );

      final prompt =
          '''Create a quiz with 7 multiple choice questions based on this content:

Topic: ${widget.topic}

Content:
${widget.content}

Create questions with varying difficulty levels:
1. First 3 questions should be EASY:
   - Focus on basic concepts and definitions
   - Use straightforward language
   - Make correct answer more obvious
   - Keep options simple and clear

2. Next 2 questions should be MEDIUM:
   - Test understanding of key concepts
   - Include some analysis
   - Make options more challenging
   - Require some thinking

3. Last 2 questions should be HARD:
   - Test deep understanding
   - Include complex concepts
   - Make all options plausible
   - Require careful analysis

For each question:
1. Create a clear and concise question
2. Provide 4 options (A, B, C, D)
3. Mark the correct answer
4. Make sure options are relevant and plausible
5. Focus on key concepts and important details

Format the response as JSON:
{
  "questions": [
    {
      "question": "Question text",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correctAnswer": "Option A",
      "difficulty": "easy/medium/hard"
    }
  ]
}''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      final responseText = response.text ?? '';

      // Parse the response and create questions
      final questions = _parseGeminiResponse(responseText);
      setState(() {
        this.questions = questions;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        questions = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating questions: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<QuizQuestion> _parseGeminiResponse(String response) {
    try {
      // Extract JSON from the response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      if (jsonStart == -1 || jsonEnd == -1) return [];

      final jsonStr = response.substring(jsonStart, jsonEnd);
      final Map<String, dynamic> json = jsonDecode(jsonStr);
      final List<dynamic> questionsJson = json['questions'];

      return questionsJson.map((q) {
        final List<String> options = List<String>.from(q['options']);
        final String correctAnswer = q['correctAnswer'];
        final int correctIndex = options.indexOf(correctAnswer);

        return QuizQuestion(
          question: q['question'],
          options: options,
          correctAnswerIndex: correctIndex,
        );
      }).toList();
    } catch (e) {
      print('Error parsing response: $e');
      return [];
    }
  }

  void _answerQuestion(int selectedIndex) {
    if (questions[currentIndex].isAnswered) return;

    setState(() {
      questions[currentIndex].isAnswered = true;
      questions[currentIndex].selectedAnswerIndex = selectedIndex;
      if (selectedIndex == questions[currentIndex].correctAnswerIndex) {
        score++;
      }
    });
  }

  void _nextQuestion() {
    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
      });
    } else {
      setState(() {
        showResults = true;
      });
    }
  }

  void _restartQuiz() {
    setState(() {
      currentIndex = 0;
      score = 0;
      showResults = false;
      isLoading = true;
      _generateQuestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text('Quiz: ${widget.topic}'),
        backgroundColor: colorScheme.surface,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Generating questions...',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : questions.isEmpty
              ? Center(
                  child: Text(
                    'No questions generated',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 18,
                    ),
                  ),
                )
              : showResults
                  ? _buildResults(context, colorScheme)
                  : _buildQuestion(context, colorScheme),
    );
  }

  Widget _buildQuestion(BuildContext context, ColorScheme colorScheme) {
    final question = questions[currentIndex];

    return Column(
      children: [
        // Progress indicator
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: LinearProgressIndicator(
            value: (currentIndex + 1) / questions.length,
            backgroundColor: colorScheme.surface,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
        Text(
          'Question ${currentIndex + 1} of ${questions.length}',
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 20),

        // Question card
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.question,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...List.generate(
                        question.options.length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildOptionButton(
                            context,
                            colorScheme,
                            question,
                            index,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Next button
        if (question.isAnswered)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _nextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                currentIndex < questions.length - 1
                    ? 'Next Question'
                    : 'Show Results',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOptionButton(
    BuildContext context,
    ColorScheme colorScheme,
    QuizQuestion question,
    int index,
  ) {
    final isSelected = question.selectedAnswerIndex == index;
    final isCorrect = index == question.correctAnswerIndex;
    final showResult = question.isAnswered;

    Color backgroundColor;
    if (showResult) {
      if (isCorrect) {
        backgroundColor = Colors.green.withOpacity(0.1);
      } else if (isSelected) {
        backgroundColor = Colors.red.withOpacity(0.1);
      } else {
        backgroundColor = colorScheme.surface;
      }
    } else {
      backgroundColor = isSelected
          ? colorScheme.primary.withOpacity(0.1)
          : colorScheme.surface;
    }

    return InkWell(
      onTap: showResult ? null : () => _answerQuestion(index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: showResult
                ? (isCorrect
                    ? Colors.green
                    : (isSelected ? Colors.red : colorScheme.outline))
                : (isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withOpacity(0.5)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                question.options[index],
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),
            ),
            if (showResult)
              Icon(
                isCorrect
                    ? Icons.check_circle
                    : (isSelected ? Icons.cancel : null),
                color: isCorrect ? Colors.green : Colors.red,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Quiz Complete!',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your Score: $score/${questions.length}',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _restartQuiz,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Restart Quiz',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
