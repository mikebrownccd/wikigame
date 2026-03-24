import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import '../lib/ollama_question_generator.dart';

const _anthropicUrl = 'https://api.anthropic.com/v1/messages';
const _proxyPort = 8081;

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, x-api-key, anthropic-version',
};

Middleware corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }
      final response = await innerHandler(request);
      return response.change(headers: _corsHeaders);
    };
  };
}

Response _jsonResponse(int status, Map<String, dynamic> body) {
  return Response(
    status,
    body: jsonEncode(body),
    headers: {'Content-Type': 'application/json', ..._corsHeaders},
  );
}

void main() async {
  final generator = OllamaQuestionGenerator();
  final router = Router();

  // ---------------------------------------------------------------------------
  // Anthropic CORS proxy (kept for legacy use)
  // ---------------------------------------------------------------------------
  router.post('/v1/messages', (Request request) async {
    final body = await request.readAsString();
    final apiKey = request.headers['x-api-key'] ?? '';
    final anthropicVersion =
        request.headers['anthropic-version'] ?? '2023-06-01';

    final upstream = await http.post(
      Uri.parse(_anthropicUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': anthropicVersion,
      },
      body: body,
    );

    return Response(
      upstream.statusCode,
      body: upstream.body,
      headers: {
        'Content-Type': 'application/json',
        ..._corsHeaders,
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Ollama question generation
  // POST /api/questions
  // Body: { "topic": "...", "content": "..." }
  // Response: { "keyFacts": [...], "questions": [...] }
  // ---------------------------------------------------------------------------
  router.post('/api/questions', (Request request) async {
    final rawBody = await request.readAsString();

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(rawBody) as Map<String, dynamic>;
    } catch (_) {
      return _jsonResponse(400, {'error': 'Request body must be valid JSON'});
    }

    final topic = body['topic'] as String?;
    final content = body['content'] as String?;
    if (topic == null || topic.isEmpty) {
      return _jsonResponse(400, {'error': 'Missing required field: topic'});
    }
    if (content == null || content.isEmpty) {
      return _jsonResponse(400, {'error': 'Missing required field: content'});
    }

    try {
      final result = await generator.generate(topic, content);
      return _jsonResponse(200, result);
    } on OllamaException catch (e) {
      return _jsonResponse(502, {'error': e.message});
    } catch (e) {
      return _jsonResponse(500, {'error': 'Internal server error: $e'});
    }
  });

  // ---------------------------------------------------------------------------
  // Health check
  // ---------------------------------------------------------------------------
  router.get('/health', (_) => Response.ok('OK'));

  final handler =
      Pipeline().addMiddleware(corsMiddleware()).addHandler(router.call);
  final server = await io.serve(handler, 'localhost', _proxyPort);
  print('Server listening on http://localhost:${server.port}');
  print('  POST /api/questions  — Ollama question generation');
  print('  POST /v1/messages    — Anthropic CORS proxy');
  print('  GET  /health         — Health check');

  // Pre-warm the model so the first user request is fast
  print('Warming up Ollama model...');
  generator.generate('warmup', 'warmup').then((_) {
    print('Model ready.');
  }).catchError((e) {
    print('Warm-up skipped (Ollama may not be running): $e');
  });
}
