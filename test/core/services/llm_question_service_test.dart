import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:wikigame/core/models/question.dart';
import 'package:wikigame/core/services/llm_question_service.dart';

// ---------------------------------------------------------------------------
// Minimal fake HTTP client
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

http.Response _serverResponse(Map<String, dynamic> body, {int status = 200}) {
  return http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );
}

Map<String, dynamic> _validPayload() => {
      'youtubeSearchQuery': 'Eiffel Tower history documentary',
      'keyFacts': [
        'The Eiffel Tower was completed in 1889.',
        'It was designed by Gustave Eiffel.',
        'It attracts 7 million visitors per year.',
      ],
      'questions': [
        {
          'type': 'multiple_choice',
          'question': 'The Eiffel Tower was completed in ___.',
          'explanation': 'Construction finished in 1889.',
          'options': ['1889', '1901', '1875', '1910'],
          'correct_index': 0,
        },
        {
          'type': 'multiple_choice',
          'question': 'Who designed the Eiffel Tower?',
          'explanation': 'Gustave Eiffel led the project.',
          'options': ['Rodin', 'Sullivan', 'Gustave Eiffel', 'Haussmann'],
          'correct_index': 2,
        },
        {
          'type': 'true_false',
          'question': 'The Eiffel Tower was built for the 1889 World\'s Fair.',
          'explanation': 'True — it served as the entrance arch.',
          'is_true': true,
        },
        {
          'type': 'true_false',
          'question': 'The Eiffel Tower has always been the tallest structure.',
          'explanation': 'False — it held the record for only 41 years.',
          'is_true': false,
        },
        {
          'type': 'fill_blank',
          'question': 'The Eiffel Tower stands ___ metres tall.',
          'explanation': 'The answer is 330.',
          'answer': '330',
        },
      ],
    };

void main() {
  group('LlmQuestionService', () {
    // -------------------------------------------------------------------------
    // Happy path
    // -------------------------------------------------------------------------
    group('generate — success', () {
      late LlmQuestionService service;

      setUp(() {
        service = LlmQuestionService(
          client: _FakeClient((_) async => _serverResponse(_validPayload())),
        );
      });

      test('returns 5 questions', () async {
        final result = await service.generate('Eiffel Tower', 'content');
        expect(result.questions.length, 5);
      });

      test('returns 3 key facts', () async {
        final result = await service.generate('Eiffel Tower', 'content');
        expect(result.keyFacts.length, 3);
      });

      test('parses multiple_choice question type', () async {
        final result = await service.generate('Eiffel Tower', 'content');
        final mc = result.questions
            .where((q) => q.type == QuestionType.multipleChoice)
            .toList();
        expect(mc.length, 2);
        expect(mc.first.options?.length, 4);
        expect(mc.first.correctIndex, isNotNull);
      });

      test('parses true_false question type', () async {
        final result = await service.generate('Eiffel Tower', 'content');
        final tf = result.questions
            .where((q) => q.type == QuestionType.trueFalse)
            .toList();
        expect(tf.length, 2);
        expect(tf.first.isTrue, isNotNull);
      });

      test('parses fill_blank question type', () async {
        final result = await service.generate('Eiffel Tower', 'content');
        final fb = result.questions
            .where((q) => q.type == QuestionType.fillBlank)
            .toList();
        expect(fb.length, 1);
        expect(fb.first.answer, isNotEmpty);
      });

      test('questions have non-empty text and explanation', () async {
        final result = await service.generate('Eiffel Tower', 'content');
        for (final q in result.questions) {
          expect(q.question, isNotEmpty);
          expect(q.explanation, isNotEmpty);
        }
      });

      test('key facts are non-empty strings', () async {
        final result = await service.generate('Eiffel Tower', 'content');
        for (final f in result.keyFacts) {
          expect(f, isNotEmpty);
        }
      });

      test('returns youtubeSearchQuery from response', () async {
        final result = await service.generate('Eiffel Tower', 'content');
        expect(result.youtubeSearchQuery, 'Eiffel Tower history documentary');
      });

      test('youtubeSearchQuery is null when server omits it', () async {
        final payloadWithoutVideo = Map<String, dynamic>.from(_validPayload())
          ..remove('youtubeSearchQuery');
        final svc = LlmQuestionService(
          client: _FakeClient((_) async => _serverResponse(payloadWithoutVideo)),
        );
        final result = await svc.generate('Topic', 'content');
        expect(result.youtubeSearchQuery, isNull);
      });

      test('sends POST to /api/questions', () async {
        http.BaseRequest? captured;
        final svc = LlmQuestionService(
          client: _FakeClient((req) async {
            captured = req;
            return _serverResponse(_validPayload());
          }),
        );
        await svc.generate('Topic', 'content');
        expect(captured?.method, 'POST');
        expect(captured?.url.path, '/api/questions');
      });

      test('sends topic and content in request body', () async {
        String? sentBody;
        final svc = LlmQuestionService(
          client: _FakeClient((req) async {
            sentBody = await req.finalize().bytesToString();
            return _serverResponse(_validPayload());
          }),
        );
        await svc.generate('Eiffel Tower', 'article content here');
        final decoded = jsonDecode(sentBody!) as Map<String, dynamic>;
        expect(decoded['topic'], 'Eiffel Tower');
        expect(decoded['content'], 'article content here');
      });

      test('uses configured serverUrl', () async {
        http.BaseRequest? captured;
        final svc = LlmQuestionService(
          serverUrl: 'http://my-server:9000',
          client: _FakeClient((req) async {
            captured = req;
            return _serverResponse(_validPayload());
          }),
        );
        await svc.generate('Topic', 'content');
        expect(captured?.url.host, 'my-server');
        expect(captured?.url.port, 9000);
      });
    });

    // -------------------------------------------------------------------------
    // Error handling
    // -------------------------------------------------------------------------
    group('generate — error handling', () {
      test('throws LlmServiceException on HTTP 500', () async {
        final svc = LlmQuestionService(
          client: _FakeClient(
            (_) async => _serverResponse({'error': 'internal'}, status: 500),
          ),
        );
        expect(
          () => svc.generate('Topic', 'content'),
          throwsA(isA<LlmServiceException>()),
        );
      });

      test('throws LlmServiceException on HTTP 502', () async {
        final svc = LlmQuestionService(
          client: _FakeClient(
            (_) async => http.Response('Bad gateway', 502),
          ),
        );
        expect(
          () => svc.generate('Topic', 'content'),
          throwsA(isA<LlmServiceException>()),
        );
      });

      test('exception message includes HTTP status', () async {
        final svc = LlmQuestionService(
          client: _FakeClient(
            (_) async => http.Response('error', 503),
          ),
        );
        try {
          await svc.generate('Topic', 'content');
          fail('Should have thrown');
        } on LlmServiceException catch (e) {
          expect(e.message, contains('503'));
        }
      });

      test('throws LlmServiceException when server returns error field', () async {
        final svc = LlmQuestionService(
          client: _FakeClient(
            (_) async =>
                _serverResponse({'error': 'Ollama not running'}, status: 200),
          ),
        );
        expect(
          () => svc.generate('Topic', 'content'),
          throwsA(isA<LlmServiceException>()),
        );
      });

      test('throws LlmServiceException when questions key is missing', () async {
        final svc = LlmQuestionService(
          client: _FakeClient(
            (_) async => _serverResponse({'keyFacts': ['fact']}),
          ),
        );
        expect(
          () => svc.generate('Topic', 'content'),
          throwsA(isA<LlmServiceException>()),
        );
      });

      test('throws LlmServiceException when keyFacts key is missing', () async {
        final svc = LlmQuestionService(
          client: _FakeClient(
            (_) async =>
                _serverResponse({'questions': _validPayload()['questions']}),
          ),
        );
        expect(
          () => svc.generate('Topic', 'content'),
          throwsA(isA<LlmServiceException>()),
        );
      });

      test('throws LlmServiceException when questions list is empty', () async {
        final svc = LlmQuestionService(
          client: _FakeClient(
            (_) async => _serverResponse({
              'keyFacts': _validPayload()['keyFacts'],
              'questions': <dynamic>[],
            }),
          ),
        );
        expect(
          () => svc.generate('Topic', 'content'),
          throwsA(isA<LlmServiceException>()),
        );
      });

      test('throws LlmServiceException when body is not valid JSON', () async {
        final svc = LlmQuestionService(
          client: _FakeClient(
            (_) async => http.Response('not json', 200),
          ),
        );
        expect(
          () => svc.generate('Topic', 'content'),
          throwsA(isA<LlmServiceException>()),
        );
      });

      test('LlmServiceException has a readable toString', () {
        const e = LlmServiceException('something failed');
        expect(e.toString(), contains('LlmServiceException'));
        expect(e.toString(), contains('something failed'));
      });
    });
  });
}
