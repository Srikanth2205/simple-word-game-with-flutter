import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'API Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _response = 'No data yet';
  bool _isLoading = false;
  List<String> _jumbledLetters = [];
  List<String> _userAnswer = [];
  String _originalWord = '';
  String _feedback = '';
  bool _showSuccess = false;
  int _attempts = 0;  // Track number of attempts
  final int _maxAttempts = 3;  // Maximum allowed attempts

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _userAnswer = [];
      _feedback = '';
      _showSuccess = false;
      _attempts = 0;  // Reset attempts when fetching new word
    });

    try {
      final response = await http.get(
        Uri.parse('http://65.1.114.220:5000/api/jumbled-word'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        setState(() {
          _originalWord = decodedResponse['original'];
          _response = 'Arrange the letters to form a word';
          _jumbledLetters = (decodedResponse['jumbled'] as String).split('');
        });
      } else {
        setState(() {
          _response = 'Server Error: ${response.statusCode}';
          _jumbledLetters = [];
        });
      }
    } catch (e) {
      setState(() {
        _response = 'Connection Error: $e';
        _jumbledLetters = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleLetterPress(String letter) {
    setState(() {
      if (_userAnswer.length < _jumbledLetters.length) {
        _userAnswer.add(letter);
        _feedback = '';
        
        // Auto-submit when the last letter is entered
        if (_userAnswer.length == _jumbledLetters.length) {
          _checkAnswer();
        }
      }
    });
  }

  void _removeLastLetter() {
    setState(() {
      if (_userAnswer.isNotEmpty) {
        _userAnswer.removeLast();
        _feedback = '';
      }
    });
  }

  void _resetAnswer() {
    setState(() {
      _userAnswer = [];
      _feedback = '';
      _showSuccess = false;
    });
  }

  void _checkAnswer() {
    if (_userAnswer.length != _originalWord.length) {
      setState(() {
        _feedback = 'Complete the word first!';
        _showSuccess = false;
      });
      return;
    }

    final userWord = _userAnswer.join();
    setState(() {
      if (userWord.toLowerCase() == _originalWord.toLowerCase()) {
        _feedback = 'Correct! Well done! 🎉';
        _showSuccess = true;
        // Add delay and auto-fetch new word after success
        Future.delayed(const Duration(seconds: 2), () {
          _fetchData();
        });
      } else {
        _attempts++;
        if (_attempts >= _maxAttempts) {
          _feedback = 'The word was: $_originalWord\nFetching new word...';
          // Fetch new word after a short delay
          Future.delayed(const Duration(seconds: 2), () {
            _fetchData();
          });
        } else {
          _feedback = 'Try again! ${_maxAttempts - _attempts} attempts left 😕';
        }
        _showSuccess = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Modified condition to show New Word button initially or after completion
    bool canGetNewWord = _jumbledLetters.isEmpty || _showSuccess || _attempts >= _maxAttempts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Jumble Game'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Attempts: $_attempts/$_maxAttempts',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Now the New Word button will show initially
              if (canGetNewWord)
                ElevatedButton(
                  onPressed: _isLoading ? null : _fetchData,
                  child: Text(_isLoading ? 'Loading...' : 'New Word'),
                ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    Text(_response),
                    const SizedBox(height: 20),
                    if (_jumbledLetters.isNotEmpty) ...[
                      // Empty boxes to receive letters with animation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_jumbledLetters.length, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _showSuccess ? Colors.green : Colors.blue,
                                width: index < _userAnswer.length ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: index < _userAnswer.length
                                  ? _showSuccess ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1)
                                  : null,
                            ),
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 300),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _showSuccess ? Colors.green : Colors.black,
                                ),
                                child: Text(
                                  index < _userAnswer.length ? _userAnswer[index] : '',
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                      // Clickable letter buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _jumbledLetters.map((letter) {
                          bool isUsed = _userAnswer.where((l) => l == letter).length >=
                              _jumbledLetters.where((l) => l == letter).length;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ElevatedButton(
                              onPressed: isUsed ? null : () => _handleLetterPress(letter),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(8),
                                minimumSize: const Size(40, 40),
                              ),
                              child: Text(
                                letter,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      // Control buttons - removed Submit button since we have auto-submit
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _userAnswer.isEmpty ? null : _removeLastLetter,
                            child: const Text('⌫ Backspace'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _userAnswer.isEmpty ? null : _resetAnswer,
                            child: const Text('↺ Reset'),
                          ),
                        ],
                      ),
                      if (_feedback.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: _feedback.isNotEmpty ? 1.0 : 0.0,
                          child: Text(
                            _feedback,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _showSuccess ? Colors.green : Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
