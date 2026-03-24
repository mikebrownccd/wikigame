import 'dart:convert';
import 'package:http/http.dart' as http;

const _defaultModel = 'gemma3:4b';

/// Generates quiz questions and key facts by calling a local Ollama server.
///
/// The response JSON uses the same field names as [Question.fromJson] in the
/// Flutter app so the output can be forwarded directly.
class OllamaQuestionGenerator {
  final http.Client _client;
  final String baseUrl;
  final String model;

  OllamaQuestionGenerator({
    http.Client? client,
    this.baseUrl = 'http://localhost:11434',
    this.model = _defaultModel,
  }) : _client = client ?? http.Client();

  /// Returns a map with keys [keyFacts] (List<String>) and [questions]
  /// (List<Map>) ready to be forwarded to the Flutter app.
  ///
  /// Throws [OllamaException] if the model returns a non-200 status or
  /// invalid JSON.
  Future<Map<String, dynamic>> generate(String topic, String content) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'user', 'content': buildPrompt(topic, content)},
        ],
        'stream': false,
        'format': 'json',
      }),
    );

    if (response.statusCode != 200) {
      throw OllamaException(
        'Ollama returned HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final rawContent = body['message']?['content'] as String?;
    if (rawContent == null) {
      throw OllamaException('Unexpected Ollama response shape: $body');
    }

    final Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(rawContent) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw OllamaException('Model returned invalid JSON: $e\n\n$rawContent');
    }

    _validate(parsed);
    return parsed;
  }

  /// Exposed for testing.
  String buildPrompt(String topic, String content) => '''
You are an educational quiz generator. Given an article about "$topic", produce an engaging quiz that tests real comprehension.

Article (use only facts from this text):
$content

Return ONLY valid JSON matching this exact structure — no markdown, no explanation:
{
  "youtubeSearchQuery": "topic keywords documentary",
  "keyFacts": [
    "Short, punchy fact 1.",
    "Short, punchy fact 2.",
    "Short, punchy fact 3."
  ],
  "questions": [
    {
      "type": "multiple_choice",
      "question": "Question with ___ for the missing term.",
      "explanation": "The correct answer is X because ...",
      "options": ["correct answer", "distractor 1", "distractor 2", "distractor 3"],
      "correct_index": 0
    },
    {
      "type": "multiple_choice",
      "question": "Another multiple-choice question?",
      "explanation": "Explanation referencing the article.",
      "options": ["option A", "option B", "option C", "option D"],
      "correct_index": 2
    },
    {
      "type": "true_false",
      "question": "A true statement from the article.",
      "explanation": "True. This appears directly in the article.",
      "is_true": true
    },
    {
      "type": "true_false",
      "question": "A subtly incorrect statement about the topic.",
      "explanation": "False. The article states [correct fact].",
      "is_true": false
    },
    {
      "type": "fill_blank",
      "question": "Sentence with ___ replacing the key term.",
      "explanation": "The missing word is X. The article states ...",
      "answer": "key term"
    }
  ]
}

Rules:
- youtubeSearchQuery: 3-6 words targeting a short YouTube explainer video under 10 minutes (e.g. "Eiffel Tower explained", "World War 2 in 5 minutes", "Leonardo da Vinci who was he") — avoid the word "documentary"
- keyFacts: exactly 3 short, punchy facts — one sentence each, under 20 words, most surprising or important facts from the article
- questions: exactly 5 questions in the order shown above (2 MC, 2 T/F, 1 fill_blank)
- All content must be grounded in the article — no invented facts
- Multiple-choice options must be plausible distractors, not obviously wrong
- correct_index is 0-based (0 = first option in the options array)
- Return only the JSON object, nothing else
''';

  void _validate(Map<String, dynamic> data) {
    final facts = data['keyFacts'];
    if (facts is! List || facts.length < 1) {
      throw OllamaException('keyFacts missing or empty in model response');
    }
    final questions = data['questions'];
    if (questions is! List || questions.length < 1) {
      throw OllamaException('questions missing or empty in model response');
    }
    // youtubeSearchQuery is optional — fall back gracefully if missing
  }
}

class OllamaException implements Exception {
  final String message;
  const OllamaException(this.message);

  @override
  String toString() => 'OllamaException: $message';
}
