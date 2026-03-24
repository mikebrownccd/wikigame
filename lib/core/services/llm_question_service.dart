import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/question.dart';

/// Result returned by [LlmQuestionService.generate].
class LlmQuizResult {
  final List<Question> questions;
  final List<String> keyFacts;

  const LlmQuizResult({required this.questions, required this.keyFacts});
}

/// Calls the local Dart server's POST /api/questions endpoint, which in turn
/// uses Ollama (gemma3:4b) to generate questions from a Wikipedia article.
///
/// Falls back gracefully — callers should catch [LlmServiceException] and
/// use the rule-based [QuestionGenerator] instead.
class LlmQuestionService {
  final http.Client _client;
  final String serverUrl;

  LlmQuestionService({
    http.Client? client,
    this.serverUrl = 'http://localhost:8081',
  }) : _client = client ?? http.Client();

  Future<LlmQuizResult> generate(String topic, String content) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$serverUrl/api/questions'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'topic': topic, 'content': content}),
          )
          .timeout(const Duration(seconds: 60));
    } catch (e) {
      throw LlmServiceException('Could not reach question server: $e');
    }

    if (response.statusCode != 200) {
      throw LlmServiceException(
        'Server returned HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw LlmServiceException('Invalid JSON from server: $e');
    }

    if (body.containsKey('error')) {
      throw LlmServiceException('Server error: ${body['error']}');
    }

    final rawQuestions = body['questions'];
    final rawFacts = body['keyFacts'];

    if (rawQuestions is! List || rawFacts is! List) {
      throw LlmServiceException(
        'Unexpected response shape — missing questions or keyFacts',
      );
    }

    final questions = rawQuestions
        .cast<Map<String, dynamic>>()
        .map(Question.fromJson)
        .toList();

    final keyFacts = rawFacts.cast<String>();

    if (questions.isEmpty) {
      throw LlmServiceException('Server returned an empty questions list');
    }

    return LlmQuizResult(questions: questions, keyFacts: keyFacts);
  }
}

class LlmServiceException implements Exception {
  final String message;
  const LlmServiceException(this.message);

  @override
  String toString() => 'LlmServiceException: $message';
}
