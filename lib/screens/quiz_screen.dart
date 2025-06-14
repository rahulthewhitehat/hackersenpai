import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startTimer();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
    _progressController.forward();
  }

  void _startTimer() {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (quizProvider.remainingTime > 0) {
        quizProvider.updateRemainingTime(quizProvider.remainingTime - 1);

        if (quizProvider.remainingTime <= 10) {
          _pulseController.repeat(reverse: true);
        }
      } else {
        timer.cancel();
        _pulseController.stop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _slideController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
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
          final timeProgressValue = quizProvider.remainingTime / quizProvider.timePerQuestion;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: theme.brightness == Brightness.dark
                    ? [
                  Colors.grey[900]!,
                  Colors.grey[850]!,
                  Colors.grey[900]!,
                ]
                    : [
                  Colors.white,
                  const Color(0xFFF8FAFF),
                  Colors.white,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(theme, quizProvider, progressValue),
                  Expanded(
                    child: _buildQuestionContent(theme, question, quizProvider, timeProgressValue),
                  ),
                  _buildBottomSection(theme, quizProvider),
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

  Widget _buildHeader(ThemeData theme, QuizProvider quizProvider, double progressValue) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.onPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back_ios_rounded,
                    color: theme.colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Quiz Mode',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimary.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${quizProvider.currentQuestionIndex + 1} of ${quizProvider.totalQuestions}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: quizProvider.remainingTime <= 10 ? _pulseAnimation.value : 1.0,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: quizProvider.remainingTime <= 10
                            ? theme.colorScheme.error.withOpacity(0.2)
                            : theme.colorScheme.onPrimary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: quizProvider.remainingTime <= 10
                              ? theme.colorScheme.error.withOpacity(0.5)
                              : theme.colorScheme.onPrimary.withOpacity(0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.timer_rounded,
                            color: quizProvider.remainingTime <= 10
                                ? theme.colorScheme.error
                                : theme.colorScheme.onPrimary,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatTime(quizProvider.remainingTime),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: quizProvider.remainingTime <= 10
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Overall Progress',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimary.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${(progressValue * 100).toInt()}%',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          value: progressValue * _progressAnimation.value,
                          backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(10),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent(ThemeData theme, Map question, QuizProvider quizProvider, double timeProgressValue) {
    return SlideTransition(
      position: _slideAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: theme.colorScheme.surface,
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.onSurface.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Time for this question',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        formatTime(quizProvider.remainingTime),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: quizProvider.remainingTime <= 10
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: timeProgressValue * _progressAnimation.value,
                        backgroundColor: theme.colorScheme.outlineVariant.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          quizProvider.remainingTime <= 10
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                        ),
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(6),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.surface,
                      theme.colorScheme.surfaceContainer,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.onSurface.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withOpacity(0.3),
                              theme.colorScheme.secondary.withOpacity(0.3),
                            ],
                          ),
                        ),
                        child: Text(
                          'Question ${quizProvider.currentQuestionIndex + 1}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        question['question'],
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: List.generate(question['shuffled_options'].length, (index) {
                          final option = question['shuffled_options'][index];
                          final isSelected = quizProvider.userAnswers[quizProvider.currentQuestionIndex] == option;
                          final optionLabels = ['A', 'B', 'C', 'D'];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
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
                                color: isSelected ? null : theme.colorScheme.surface,
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outlineVariant.withOpacity(0.5),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.onSurface.withOpacity(0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                onTap: () {
                                  quizProvider.answerQuestion(option);
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: isSelected
                                              ? LinearGradient(
                                            colors: [
                                              theme.colorScheme.primary,
                                              theme.colorScheme.secondary,
                                            ],
                                          )
                                              : null,
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.transparent
                                                : theme.colorScheme.outlineVariant,
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
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          option,
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            color: isSelected
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.onSurface,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                            fontSize: 16,
                                          ),
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
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(ThemeData theme, QuizProvider quizProvider) {
    final isLastQuestion = quizProvider.currentQuestionIndex >= quizProvider.questions.length - 1;
    final hasAnswer = quizProvider.userAnswers[quizProvider.currentQuestionIndex] != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: hasAnswer
                ? LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
            )
                : null,
            color: hasAnswer ? null : theme.colorScheme.outlineVariant.withOpacity(0.3),
            boxShadow: hasAnswer
                ? [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ]
                : null,
          ),
          child: ElevatedButton(
            onPressed: hasAnswer
                ? () {
              if (isLastQuestion) {
                quizProvider.submitTest();
                _timer?.cancel();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const QuizResultScreen()),
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
      ),
    );
  }

  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}