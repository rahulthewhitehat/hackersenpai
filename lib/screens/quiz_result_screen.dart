import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/quiz_provider.dart';
import 'quiz_selection_screen.dart';

class QuizResultScreen extends StatefulWidget {
  const QuizResultScreen({super.key});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _listFadeAnimation;
  late Animation<Offset> _listSlideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Animation for the header section
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Animation for the question list and button
    _listFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    _listSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.brightness == Brightness.dark
                ? [Colors.black, theme.colorScheme.surface]
                : [Colors.white, theme.colorScheme.surfaceContainer],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Animated Header
                FadeTransition(
                  opacity: _headerFadeAnimation,
                  child: SlideTransition(
                    position: _headerSlideAnimation,
                    child: _buildResultHeader(theme, quizProvider),
                  ),
                ),
                const SizedBox(height: 24),
                // Animated Question Review List
                Expanded(
                  child: FadeTransition(
                    opacity: _listFadeAnimation,
                    child: SlideTransition(
                      position: _listSlideAnimation,
                      child: _buildQuestionReviewList(theme, quizProvider),
                    ),
                  ),
                ),
                // Animated Button
                FadeTransition(
                  opacity: _listFadeAnimation,
                  child: SlideTransition(
                    position: _listSlideAnimation,
                    child: _buildTryAnotherButton(context, quizProvider),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultHeader(ThemeData theme, QuizProvider quizProvider) {
    final percentage = (quizProvider.score / quizProvider.totalQuestions) * 100;

    return Column(
      children: [
        ScoreCircle(percentage: percentage),
        const SizedBox(height: 20),
        Text(
          percentage >= 50 ? 'Congratulations!' : 'Keep Practicing!',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You have completed the quiz',
          style: theme.textTheme.bodyLarge
              ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
        const SizedBox(height: 24),
        _buildStatsRow(theme, quizProvider),
      ],
    );
  }

  Widget _buildStatsRow(ThemeData theme, QuizProvider quizProvider) {
    final correct = quizProvider.score;
    final incorrect = quizProvider.questions
        .asMap()
        .entries
        .where((entry) {
      final userAnswer = quizProvider.userAnswers[entry.key];
      return userAnswer != null &&
          userAnswer != entry.value['correct_answer'];
    })
        .length;
    final unanswered = quizProvider.totalQuestions - correct - incorrect;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
              theme, Icons.check_rounded, 'Correct', correct, theme.colorScheme.primary),
          _buildStatItem(
              theme, Icons.close_rounded, 'Incorrect', incorrect, theme.colorScheme.error),
        ],
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, IconData icon, String label, int value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          '$value',
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildQuestionReviewList(ThemeData theme, QuizProvider quizProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            "Review Your Answers",
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: quizProvider.questions.length,
            padding: const EdgeInsets.only(bottom: 16),
            itemBuilder: (context, index) {
              final question = quizProvider.questions[index];
              final userAnswer = quizProvider.userAnswers[index];
              final isCorrect = userAnswer == question['correct_answer'];

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                  ),
                ),
                color: theme.colorScheme.surfaceContainer,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                      left: BorderSide(
                        color: isCorrect
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error,
                        width: 5,
                      ),
                    ),
                  ),
                  child: ExpansionTile(
                    tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      question['question'],
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Text(
                            'Your answer: ${userAnswer ?? "Not answered"}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isCorrect
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Correct answer: ${question['correct_answer']}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTryAnotherButton(BuildContext context, QuizProvider quizProvider) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          quizProvider.resetQuiz();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const QuizSelectionScreen()),
          );
        },
        style: theme.elevatedButtonTheme.style?.copyWith(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        child: Text(
          'Try Another Quiz',
          style: theme.textTheme.titleMedium
              ?.copyWith(color: theme.colorScheme.onPrimary),
        ),
      ),
    );
  }
}

// A custom widget to display the score in an animated circle.
class ScoreCircle extends StatefulWidget {
  final double percentage;
  const ScoreCircle({super.key, required this.percentage});

  @override
  State<ScoreCircle> createState() => _ScoreCircleState();
}

class _ScoreCircleState extends State<ScoreCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.percentage / 100)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: 1,
                strokeWidth: 10,
                backgroundColor: theme.colorScheme.surface,
                color: theme.colorScheme.surfaceContainer,
              ),
              CircularProgressIndicator(
                value: _animation.value,
                strokeWidth: 10,
                valueColor:
                AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                strokeCap: StrokeCap.round,
              ),
              Center(
                child: Text(
                  '${(_animation.value * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}