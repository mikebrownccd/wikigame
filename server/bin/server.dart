import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

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

void main() async {
  final router = Router();

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

  final handler = Pipeline().addMiddleware(corsMiddleware()).addHandler(router.call);
  final server = await io.serve(handler, 'localhost', _proxyPort);
  print('Proxy listening on http://localhost:${server.port}');
}
