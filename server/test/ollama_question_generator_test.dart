import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import '../lib/ollama_question_generator.dart';

// ---------------------------------------------------------------------------
// Minimal fake HTTP client — no code-gen required
// ---------------------------------------------------------------------------
class _FakeClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest) handler;
  _FakeClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

http.Response _ollamaResponse(Map<String, dynamic> content) {
  return http.Response(
    jsonEncode({
      'model': 'gemma3:4b',
      'message': {'role': 'assistant', 'content': jsonEncode(content)},
      'done': true,
    }),
    200,
    headers: {'content-type': 'application/json'},
  );
}

// A valid quiz payload the model might return
Map<String, dynamic> _validPayload() => {
      'keyFacts': [
        'The Eiffel Tower was built between 1887 and 1889.',
        'It was designed by Gustave Eiffel for the 1889 World\'s Fair.',
        'The tower stands 330 metres tall including its antenna.',
        'It was the world\'s tallest man-made structure for 41 years.',
        'About 7 million people visit the Eiffel Tower every year.',
        'The tower was originally intended to be dismantled after 20 years.',
      ],
      'questions': [
        {
          'type': 'multiple_choice',
          'question': 'The Eiffel Tower was completed in ___.',
          'explanation': 'Construction finished in 1889 for the World\'s Fair.',
          'options': ['1889', '1901', '1875', '1910'],
          'correct_index': 0,
        },
        {
          'type': 'multiple_choice',
          'question': 'Who designed the Eiffel Tower?',
          'explanation': 'Gustave Eiffel led the engineering project.',
          'options': ['Auguste Rodin', 'Louis Sullivan', 'Gustave Eiffel', 'Haussmann'],
          'correct_index': 2,
        },
        {
          'type': 'true_false',
          'question': 'The Eiffel Tower was built for the 1889 World\'s Fair.',
          'explanation': 'True. It served as the entrance arch for the exposition.',
          'is_true': true,
        },
        {
          'type': 'true_false',
          'question': 'The Eiffel Tower has always been the world\'s tallest structure.',
          'explanation': 'False. It held the record for 41 years before being surpassed.',
          'is_true': false,
        },
        {
          'type': 'fill_blank',
          'question': 'The Eiffel Tower stands ___ metres tall including its antenna.',
          'explanation': 'The answer is 330. The tower reaches 330 metres with the antenna.',
          'answer': '330',
        },
      ],
    };

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  group('OllamaQuestionGenerator', () {
    // -------------------------------------------------------------------------
    // buildPrompt
    // -------------------------------------------------------------------------
    group('buildPrompt', () {
      late OllamaQuestionGenerator generator;

      setUp(() => generator = OllamaQuestionGenerator());

      test('includes the topic name', () {
        final prompt = generator.buildPrompt('Eiffel Tower', 'some content');
        expect(prompt, contains('Eiffel Tower'));
      });

      test('includes the article content', () {
        final prompt =
            generator.buildPrompt('Topic', 'unique content string xyz');
        expect(prompt, contains('unique content string xyz'));
      });

      test('specifies all three question types', () {
        final prompt = generator.buildPrompt('Topic', 'content');
        expect(prompt, contains('multiple_choice'));
        expect(prompt, contains('true_false'));
        expect(prompt, contains('fill_blank'));
      });

      test('asks for exactly 5 questions and 6 key facts', () {
        final prompt = generator.buildPrompt('Topic', 'content');
        expect(prompt, contains('5 questions'));
        expect(prompt, contains('6 interesting'));
      });

      test('uses snake_case JSON field names', () {
        final prompt = generator.buildPrompt('Topic', 'content');
        expect(prompt, contains('correct_index'));
        expect(prompt, contains('is_true'));
        expect(prompt, contains('keyFacts'));
      });
    });

    // -------------------------------------------------------------------------
    // generate — happy path
    // -------------------------------------------------------------------------
    group('generate — success', () {
      late OllamaQuestionGenerator generator;

      setUp(() {
        generator = OllamaQuestionGenerator(
          client: _FakeClient((_) async => _ollamaResponse(_validPayload())),
        );
      });

      test('returns keyFacts list', () async {
        final result = await generator.generate('Eiffel Tower', 'content');
        expect(result['keyFacts'], isA<List>());
        expect((result['keyFacts'] as List).length, 6);
      });

      test('returns questions list', () async {
        final result = await generator.generate('Eiffel Tower', 'content');
        expect(result['questions'], isA<List>());
        expect((result['questions'] as List).length, 5);
      });

      test('question types are preserved', () async {
        final result = await generator.generate('Eiffel Tower', 'content');
        final questions = result['questions'] as List;
        final types = questions.map((q) => q['type']).toList();
        expect(types, containsAll(['multiple_choice', 'true_false', 'fill_blank']));
      });

      test('multiple_choice question has correct_index and options', () async {
        final result = await generator.generate('Eiffel Tower', 'content');
        final mcq = (result['questions'] as List)
            .firstWhere((q) => q['type'] == 'multiple_choice');
        expect(mcq['options'], isA<List>());
        expect((mcq['options'] as List).length, 4);
        expect(mcq['correct_index'], isA<int>());
      });

      test('true_false question has is_true field', () async {
        final result = await generator.generate('Eiffel Tower', 'content');
        final tfq = (result['questions'] as List)
            .firstWhere((q) => q['type'] == 'true_false');
        expect(tfq['is_true'], isA<bool>());
      });

      test('fill_blank question has answer field', () async {
        final result = await generator.generate('Eiffel Tower', 'content');
        final fbq = (result['questions'] as List)
            .firstWhere((q) => q['type'] == 'fill_blank');
        expect(fbq['answer'], isA<String>());
        expect((fbq['answer'] as String).isNotEmpty, isTrue);
      });

      test('sends request to the configured baseUrl', () async {
        http.BaseRequest? captured;
        final gen = OllamaQuestionGenerator(
          baseUrl: 'http://custom-host:11434',
          client: _FakeClient((req) async {
            captured = req;
            return _ollamaResponse(_validPayload());
          }),
        );
        await gen.generate('Topic', 'content');
        expect(captured?.url.host, 'custom-host');
        expect(captured?.url.port, 11434);
        expect(captured?.url.path, '/api/chat');
      });

      test('sends the configured model name in request body', () async {
        String? sentBody;
        final gen = OllamaQuestionGenerator(
          model: 'llama3.2',
          client: _FakeClient((req) async {
            sentBody = await req.finalize().bytesToString();
            return _ollamaResponse(_validPayload());
          }),
        );
        await gen.generate('Topic', 'content');
        final decoded = jsonDecode(sentBody!) as Map<String, dynamic>;
        expect(decoded['model'], 'llama3.2');
      });

      test('sends stream: false', () async {
        String? sentBody;
        final gen = OllamaQuestionGenerator(
          client: _FakeClient((req) async {
            sentBody = await req.finalize().bytesToString();
            return _ollamaResponse(_validPayload());
          }),
        );
        await gen.generate('Topic', 'content');
        final decoded = jsonDecode(sentBody!) as Map<String, dynamic>;
        expect(decoded['stream'], isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // generate — error handling
    // -------------------------------------------------------------------------
    group('generate — error handling', () {
      test('throws OllamaException on non-200 HTTP status', () async {
        final gen = OllamaQuestionGenerator(
          client: _FakeClient(
            (_) async => http.Response('Service unavailable', 503),
          ),
        );
        expect(
          () => gen.generate('Topic', 'content'),
          throwsA(isA<OllamaException>()),
        );
      });

      test('OllamaException message includes the HTTP status code', () async {
        final gen = OllamaQuestionGenerator(
          client: _FakeClient(
            (_) async => http.Response('Bad gateway', 502),
          ),
        );
        try {
          await gen.generate('Topic', 'content');
          fail('Should have thrown');
        } on OllamaException catch (e) {
          expect(e.message, contains('502'));
        }
      });

      test('throws OllamaException when model returns invalid JSON', () async {
        final gen = OllamaQuestionGenerator(
          client: _FakeClient(
            (_) async => http.Response(
              jsonEncode({
                'message': {'role': 'assistant', 'content': 'not json at all'},
              }),
              200,
            ),
          ),
        );
        expect(
          () => gen.generate('Topic', 'content'),
          throwsA(isA<OllamaException>()),
        );
      });

      test('throws OllamaException when message content key is missing', () async {
        final gen = OllamaQuestionGenerator(
          client: _FakeClient(
            (_) async => http.Response(
              jsonEncode({'unexpected': 'shape'}),
              200,
            ),
          ),
        );
        expect(
          () => gen.generate('Topic', 'content'),
          throwsA(isA<OllamaException>()),
        );
      });

      test('throws OllamaException when keyFacts is missing', () async {
        final badPayload = {
          'questions': _validPayload()['questions'],
          // keyFacts intentionally omitted
        };
        final gen = OllamaQuestionGenerator(
          client: _FakeClient((_) async => _ollamaResponse(badPayload)),
        );
        expect(
          () => gen.generate('Topic', 'content'),
          throwsA(isA<OllamaException>()),
        );
      });

      test('throws OllamaException when questions list is missing', () async {
        final badPayload = {
          'keyFacts': _validPayload()['keyFacts'],
          // questions intentionally omitted
        };
        final gen = OllamaQuestionGenerator(
          client: _FakeClient((_) async => _ollamaResponse(badPayload)),
        );
        expect(
          () => gen.generate('Topic', 'content'),
          throwsA(isA<OllamaException>()),
        );
      });

      test('OllamaException has a readable toString', () {
        const e = OllamaException('something went wrong');
        expect(e.toString(), contains('OllamaException'));
        expect(e.toString(), contains('something went wrong'));
      });
    });
  });
}
