import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import 'windows_quiz_result_screen.dart';

class WindowsQuizScreen extends StatefulWidget {
  const WindowsQuizScreen({super.key});

  @override
  State<WindowsQuizScreen> createState() => _WindowsQuizScreenState();
}

class _WindowsQuizScreenState extends State<WindowsQuizScreen> with TickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _startTimer();
    _slideController.forward();
  }

  void _startTimer() {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && quizProvider.remainingTime > 0) {
        quizProvider.updateRemainingTime(quizProvider.remainingTime - 1);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  void _handleNextQuestion() {
    _slideController.reset();
    _slideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Consumer<QuizProvider>(
        builder: (context, quizProvider, _) {
          if (!quizProvider.isTestStarted) {
            return _buildNotStartedState(theme);
          }
          final question = quizProvider.questions[quizProvider.currentQuestionIndex];
          final progressValue = (quizProvider.currentQuestionIndex + 1) / quizProvider.totalQuestions;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: theme.brightness == Brightness.dark
                    ? [Colors.grey[900]!, Colors.grey[850]!, Colors.grey[900]!]
                    : [Colors.white, const Color(0xFFF8FAFF), Colors.white],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                children: [
                  _buildSidebar(theme, quizProvider, progressValue),
                  const SizedBox(width: 32),
                  Expanded(
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildQuestionCard(theme, quizProvider, question),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotStartedState(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primary.withOpacity(0.2),
            theme.colorScheme.secondary.withOpacity(0.2),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.3),
                    theme.colorScheme.secondary.withOpacity(0.3),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.quiz_outlined,
                size: 72,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ready to Test Your Knowledge?',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
                fontSize: 28,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Start the quiz to challenge yourself!',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(ThemeData theme, QuizProvider quizProvider, double progressValue) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quiz Progress',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Question ${quizProvider.currentQuestionIndex + 1} of ${quizProvider.totalQuestions}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progressValue,
            backgroundColor: theme.colorScheme.outlineVariant,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 24),
          Text(
            'Time Remaining:',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatTime(quizProvider.remainingTime),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: quizProvider.remainingTime <= 10 ? theme.colorScheme.error : theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_rounded),
            label: const Text('Exit Quiz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainer,
              foregroundColor: theme.colorScheme.onSurface,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(ThemeData theme, QuizProvider quizProvider, Map question) {
    final hasAnswer = quizProvider.userAnswers[quizProvider.currentQuestionIndex] != null;
    final isLastQuestion = quizProvider.currentQuestionIndex >= quizProvider.questions.length - 1;
    final timeProgressValue = quizProvider.remainingTime / quizProvider.timePerQuestion;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Time for this question',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                formatTime(quizProvider.remainingTime),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: quizProvider.remainingTime <= 10 ? theme.colorScheme.error : theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: timeProgressValue,
            backgroundColor: theme.colorScheme.outlineVariant.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              quizProvider.remainingTime <= 10 ? theme.colorScheme.error : theme.colorScheme.primary,
            ),
            minHeight: 4,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 24),
          Text(
            'Question ${quizProvider.currentQuestionIndex + 1}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            question['question'],
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 3.0,
              ),
              itemCount: question['shuffled_options'].length,
              itemBuilder: (context, index) {
                final option = question['shuffled_options'][index];
                final isSelected = quizProvider.userAnswers[quizProvider.currentQuestionIndex] == option;
                final optionLabels = ['A', 'B', 'C', 'D'];

                return InkWell(
                  onTap: () {
                    quizProvider.answerQuestion(option);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: isSelected
                          ? LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.3),
                          theme.colorScheme.secondary.withOpacity(0.3),
                        ],
                      )
                          : null,
                      color: isSelected ? null : theme.colorScheme.surfaceContainer,
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: isSelected
                                ? LinearGradient(
                              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                            )
                                : null,
                            border: Border.all(
                              color: isSelected ? Colors.transparent : theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              optionLabels[index],
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface.withOpacity(0.7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: hasAnswer
                  ? LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
              )
                  : null,
              color: hasAnswer ? null : theme.colorScheme.outlineVariant.withOpacity(0.3),
            ),
            child: ElevatedButton(
              onPressed: hasAnswer
                  ? () {
                if (isLastQuestion) {
                  quizProvider.submitTest();
                  _timer?.cancel();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const WindowsQuizResultScreen()),
                  );
                } else {
                  quizProvider.nextQuestion();
                  _handleNextQuestion();
                }
              }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLastQuestion ? 'Submit Quiz' : 'Next Question',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: hasAnswer
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface.withOpacity(0.4),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isLastQuestion ? Icons.check_circle : Icons.arrow_forward_rounded,
                    color: hasAnswer
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface.withOpacity(0.4),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}