import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class QuizProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _chapters = [];
  List<String> _selectedChapterIds = [];
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  List<String?> _userAnswers = [];
  int _score = 0;
  bool _isLoading = false;
  String? _errorMessage;
  int _totalQuestions = 0;
  int _timePerQuestion = 120; // Default 2 minutes in seconds
  int _remainingTime = 0;
  bool _isTestStarted = false;
  bool _isTestCompleted = false;

  List<Map<String, dynamic>> get courses => _courses;
  List<Map<String, dynamic>> get chapters => _chapters;
  List<String> get selectedChapterIds => _selectedChapterIds;
  List<Map<String, dynamic>> get questions => _questions;
  int get currentQuestionIndex => _currentQuestionIndex;
  List<String?> get userAnswers => _userAnswers;
  int get score => _score;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalQuestions => _totalQuestions;
  int get timePerQuestion => _timePerQuestion;
  int get remainingTime => _remainingTime;
  bool get isTestStarted => _isTestStarted;
  bool get isTestCompleted => _isTestCompleted;

  Future<void> fetchCourses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('courses').get();
      _courses = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      _errorMessage = 'Failed to load courses: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchChapters(String courseId) async {
    _isLoading = true;
    _chapters = [];
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('chapters')
          .orderBy('order')
          .get();
      _chapters = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      _errorMessage = 'Failed to load chapters: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleChapterSelection(String chapterId) {
    if (_selectedChapterIds.contains(chapterId)) {
      _selectedChapterIds.remove(chapterId);
    } else {
      _selectedChapterIds.add(chapterId);
    }
    notifyListeners();
  }

  void setTotalQuestions(int count) {
    _totalQuestions = count;
    notifyListeners();
  }

  void setTimePerQuestion(int seconds) {
    _timePerQuestion = seconds;
    _remainingTime = seconds;
    notifyListeners();
  }

  Future<bool> fetchQuestions(String courseName) async {
    _isLoading = true;
    _questions = [];
    _errorMessage = null;
    notifyListeners();

    try {
      List<Map<String, dynamic>> allQuestions = [];
      for (var chapterId in _selectedChapterIds) {
        final chapter = _chapters.firstWhere((ch) => ch['id'] == chapterId);
        final chapterName = chapter['name']?.toString() ?? 'Unnamed Chapter';
        final snapshot = await _firestore
            .collection('practisemcq')
            .doc(courseName)
            .collection(chapterName)
            .get();
        final questions = snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
        allQuestions.addAll(questions);
      }

      if (allQuestions.isEmpty) {
        _errorMessage = 'No questions available in the selected chapters';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Shuffle and select questions
      allQuestions.shuffle(Random());
      _questions = allQuestions.take(_totalQuestions.clamp(0, allQuestions.length)).toList();
      // Shuffle options for each question
      for (var question in _questions) {
        List<String> options = [
          ...question['wrong_answers'].cast<String>(),
          question['correct_answer'].toString(),
        ];
        options.shuffle(Random());
        question['shuffled_options'] = options;
      }

      _userAnswers = List.filled(_questions.length, null);
      _isTestStarted = true;
      _remainingTime = _timePerQuestion;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to load questions: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void answerQuestion(String answer) {
    _userAnswers[_currentQuestionIndex] = answer;
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      _remainingTime = _timePerQuestion;
      notifyListeners();
    }
  }

  void submitTest() {
    _score = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_userAnswers[i] == _questions[i]['correct_answer']) {
        _score++;
      }
    }
    _isTestCompleted = true;
    _isTestStarted = false;
    notifyListeners();
  }

  void updateRemainingTime(int time) {
    _remainingTime = time;
    if (_remainingTime <= 0 && _currentQuestionIndex < _questions.length - 1) {
      nextQuestion();
    } else if (_remainingTime <= 0) {
      submitTest();
    }
    notifyListeners();
  }

  void resetQuiz() {
    _selectedChapterIds = [];
    _questions = [];
    _currentQuestionIndex = 0;
    _userAnswers = [];
    _score = 0;
    _totalQuestions = 0;
    _timePerQuestion = 120;
    _remainingTime = 0;
    _isTestStarted = false;
    _isTestCompleted = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}