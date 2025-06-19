import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class QuizProvider with ChangeNotifier {
  FirebaseFirestore? _firestore;
  bool _isFirestoreInitialized = false;
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

  QuizProvider() {
    _initializeFirestore();
  }

  Future<void> _initializeFirestore() async {
    try {
      await Firebase.initializeApp();
      _firestore = FirebaseFirestore.instance;
      _firestore!.settings;
      _isFirestoreInitialized = true;
      print('Firestore initialized successfully, persistence disabled'); // Debug log
      await _testFirestore();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to initialize Firestore: $e';
      _isFirestoreInitialized = false;
      print('Firestore initialization error: $e'); // Debug log
      notifyListeners();
    }
  }

  Future<void> _testFirestore() async {
    if (!_isFirestoreInitialized || _firestore == null) {
      print('Test query skipped: Firestore not initialized'); // Debug log
      return;
    }
    try {
      final testSnapshot = await _firestore!.collection('practisemcq').limit(1).get();
      print('Test query snapshot size: ${testSnapshot.size}'); // Debug log
      print('Test query docs: ${testSnapshot.docs.map((doc) => doc.id).toList()}'); // Debug log
    } catch (e) {
      print('Test query error: $e'); // Debug log
    }
  }

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
  bool get isFirestoreInitialized => _isFirestoreInitialized;

  Future<void> fetchCourses() async {
    if (!_isFirestoreInitialized || _firestore == null) {
      await _initializeFirestore(); // Re-attempt initialization
      if (!_isFirestoreInitialized || _firestore == null) {
        _errorMessage = 'Firestore not initialized after retry';
        print('Firestore not initialized in fetchCourses'); // Debug log
        notifyListeners();
        return;
      }
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('Querying practisemcq collection...'); // Debug log
      final snapshot = await _firestore!.collection('practisemcq').get();
      print('Snapshot size: ${snapshot.size}'); // Debug log
      print('Snapshot docs: ${snapshot.docs.map((doc) => doc.id).toList()}'); // Debug log
      print('Snapshot metadata: fromCache=${snapshot.metadata.isFromCache}, hasPendingWrites=${snapshot.metadata.hasPendingWrites}'); // Debug log

      _courses = snapshot.docs.map((doc) {
        final data = doc.data();
        print('Course document ID: ${doc.id}, Data: $data'); // Debug log
        return {
          'id': doc.id,
          'name': data['name'] ?? doc.id, // Fallback to ID if no name field
          ...data,
        };
      }).toList();

      if (_courses.isEmpty) {
        _errorMessage = 'No courses found in practisemcq collection';
        print('No courses found in practisemcq'); // Debug log
      } else {
        print('Fetched ${_courses.length} courses: $_courses'); // Debug log
      }
    } catch (e) {
      _errorMessage = 'Failed to load courses: $e';
      print('Error fetching courses: $e'); // Debug log
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchChapters(String courseId) async {
    if (!_isFirestoreInitialized || _firestore == null) {
      await _initializeFirestore();
      if (!_isFirestoreInitialized || _firestore == null) {
        _errorMessage = 'Firestore not initialized';
        print('Firestore not initialized in fetchChapters'); // Debug log
        notifyListeners();
        return;
      }
    }
    _isLoading = true;
    _chapters = [];
    _errorMessage = null;
    notifyListeners();

    try {
      print('Querying chapters for course: $courseId'); // Debug log
      final snapshot = await _firestore!
          .collection('practisemcq')
          .doc(courseId)
          .collection('chapters')
          .orderBy('order', descending: false)
          .get();
      print('Chapters snapshot size: ${snapshot.size}'); // Debug log
      print('Chapters snapshot docs: ${snapshot.docs.map((doc) => doc.id).toList()}'); // Debug log

      _chapters = snapshot.docs.map((doc) {
        final data = doc.data();
        print('Chapter document ID: ${doc.id}, Data: $data'); // Debug log
        return {
          'id': doc.id,
          'name': data['name'] ?? doc.id, // Fallback to ID if no name field
          ...data,
        };
      }).toList();

      if (_chapters.isEmpty) {
        _errorMessage = 'No chapters found for course $courseId';
        print('No chapters found for course $courseId'); // Debug log
      } else {
        print('Fetched ${_chapters.length} chapters for course $courseId: $_chapters'); // Debug log
      }
    } catch (e) {
      _errorMessage = 'Failed to load chapters: $e';
      print('Error fetching chapters: $e'); // Debug log
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
    if (!_isFirestoreInitialized || _firestore == null) {
      await _initializeFirestore();
      if (!_isFirestoreInitialized || _firestore == null) {
        _errorMessage = 'Firestore not initialized';
        print('Firestore not initialized in fetchQuestions'); // Debug log
        notifyListeners();
        return false;
      }
    }
    _isLoading = true;
    _questions = [];
    _errorMessage = null;
    notifyListeners();

    try {
      List<Map<String, dynamic>> allQuestions = [];
      for (var chapterId in _selectedChapterIds) {
        final chapter = _chapters.firstWhere((ch) => ch['id'] == chapterId, orElse: () => {});
        if (chapter.isEmpty) {
          print('Chapter $chapterId not found in chapters list'); // Debug log
          continue;
        }
        final chapterName = chapter['name']?.toString() ?? chapterId;
        print('Querying questions for course: $courseName, chapter: $chapterName'); // Debug log
        final snapshot = await _firestore!
            .collection('practisemcq')
            .doc(courseName)
            .collection('chapters')
            .doc(chapterName)
            .collection('questions')
            .get();
        print('Questions snapshot size: ${snapshot.size}'); // Debug log
        print('Questions snapshot docs: ${snapshot.docs.map((doc) => doc.id).toList()}'); // Debug log

        final questions = snapshot.docs.map((doc) {
          final data = doc.data();
          print('Question document ID: ${doc.id}, Data: $data'); // Debug log
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
        allQuestions.addAll(questions);
      }

      if (allQuestions.isEmpty) {
        _errorMessage = 'No questions available in the selected chapters';
        print('No questions found for selected chapters'); // Debug log
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
      print('Error fetching questions: $e'); // Debug log
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