import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme_provider.dart';

class Flashcard {
  final String question;
  final String answer;

  Flashcard({required this.question, required this.answer});
}

class FlashcardPage extends StatefulWidget {
  final String topic;
  final String content;

  const FlashcardPage({
    super.key,
    required this.topic,
    required this.content,
  });

  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends State<FlashcardPage> {
  late List<Flashcard> flashcards;
  int currentIndex = 0;
  bool showAnswer = false;

  @override
  void initState() {
    super.initState();
    flashcards = _generateFlashcards();
  }

  List<Flashcard> _generateFlashcards() {
    final cards = <Flashcard>[];
    final lines = widget.content.split('\n');
    String currentQuestion = '';
    String currentAnswer = '';

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Check if line is a heading
      if (line.startsWith('#')) {
        // If we have a previous question and answer, add them to cards
        if (currentQuestion.isNotEmpty && currentAnswer.isNotEmpty) {
          cards.add(Flashcard(
            question: currentQuestion,
            answer: _cleanMarkdown(currentAnswer.trim()),
          ));
        }
        // Start new question
        currentQuestion = line.replaceAll('#', '').trim();
        currentAnswer = '';
      } else {
        // Add to current answer
        currentAnswer += line + '\n';
      }
    }

    // Add the last card if exists
    if (currentQuestion.isNotEmpty && currentAnswer.isNotEmpty) {
      cards.add(Flashcard(
        question: currentQuestion,
        answer: _cleanMarkdown(currentAnswer.trim()),
      ));
    }

    return cards;
  }

  String _cleanMarkdown(String text) {
    // Remove markdown formatting
    return text
        .replaceAll('**', '') // Remove bold
        .replaceAll('*', '') // Remove italic
        .replaceAll('`', '') // Remove code
        .replaceAll('```', '') // Remove code blocks
        .replaceAll('>', '') // Remove blockquotes
        .replaceAll('#', '') // Remove headings
        .replaceAll('-', '•') // Replace dashes with bullets
        .replaceAll(RegExp(r'\n{3,}'), '\n\n') // Remove extra newlines
        .trim();
  }

  void _nextCard() {
    setState(() {
      if (currentIndex < flashcards.length - 1) {
        currentIndex++;
        showAnswer = false;
      }
    });
  }

  void _previousCard() {
    setState(() {
      if (currentIndex > 0) {
        currentIndex--;
        showAnswer = false;
      }
    });
  }

  void _toggleAnswer() {
    setState(() {
      showAnswer = !showAnswer;
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
        title: Text('Flashcards: ${widget.topic}'),
        backgroundColor: colorScheme.surface,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: flashcards.isEmpty
          ? Center(
              child: Text(
                'No flashcards generated',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                ),
              ),
            )
          : Column(
              children: [
                // Progress indicator
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LinearProgressIndicator(
                    value: (currentIndex + 1) / flashcards.length,
                    backgroundColor: colorScheme.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                ),
                Text(
                  '${currentIndex + 1} / ${flashcards.length}',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),

                // Flashcard
                Expanded(
                  child: GestureDetector(
                    onTap: _toggleAnswer,
                    child: Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: MediaQuery.of(context).size.height * 0.6,
                        margin: const EdgeInsets.all(16),
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
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    showAnswer
                                        ? flashcards[currentIndex].answer
                                        : flashcards[currentIndex].question,
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontSize: showAnswer
                                          ? (flashcards[currentIndex]
                                                      .answer
                                                      .length >
                                                  200
                                              ? 18
                                              : 24)
                                          : 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    showAnswer
                                        ? 'Tap to hide answer'
                                        : 'Tap to show answer',
                                    style: TextStyle(
                                      color: colorScheme.onSurface
                                          .withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Navigation buttons
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back,
                            color: colorScheme.onSurface),
                        onPressed: _previousCard,
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_forward,
                            color: colorScheme.onSurface),
                        onPressed: _nextCard,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
