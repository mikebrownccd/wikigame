import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/question.dart';

class ClaudeService {
  final String apiKey;

  static const _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-opus-4-6';

  ClaudeService({required this.apiKey});

  Future<List<Question>> generateQuestions(
    String topic,
    String articleContent,
  ) async {
    final prompt = '''You are a quiz question generator. Based on this Wikipedia article about "$topic", generate exactly 5 quiz questions.

Article content:
$articleContent

Generate a mix of question types:
- At least 2 multiple choice questions (4 options each)
- At least 1 true/false question
- At least 1 fill in the blank question

Return ONLY a valid JSON array with no other text, using this exact structure:
[
  {
    "type": "multiple_choice",
    "question": "Question text here?",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "correct_index": 0,
    "explanation": "Brief explanation of why this is correct."
  },
  {
    "type": "true_false",
    "question": "Statement that is true or false.",
    "is_true": true,
    "explanation": "Brief explanation."
  },
  {
    "type": "fill_blank",
    "question": "The ___ is the capital of France.",
    "answer": "Paris",
    "explanation": "Brief explanation."
  }
]

Rules:
- Questions must be factual and based solely on the article
- Make questions interesting and varied in difficulty
- Fill blank answers should be 1-3 words
- Return ONLY the JSON array, no markdown, no extra text''';

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 2048,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Claude API error: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = (data['content'] as List<dynamic>).first as Map<String, dynamic>;
    final text = content['text'] as String;

    // Extract JSON from response (handle any extra whitespace)
    final jsonStart = text.indexOf('[');
    final jsonEnd = text.lastIndexOf(']') + 1;
    if (jsonStart == -1 || jsonEnd == 0) {
      throw Exception('Claude did not return valid JSON array');
    }

    final jsonStr = text.substring(jsonStart, jsonEnd);
    final questionsJson = jsonDecode(jsonStr) as List<dynamic>;

    return questionsJson
        .cast<Map<String, dynamic>>()
        .map(Question.fromJson)
        .toList();
  }
}
