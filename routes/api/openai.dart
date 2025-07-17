// In routes/api/openai.dart
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;

Future<Response> onRequest(RequestContext context) async {
  // 1. Get the request body sent from your front-end
  final requestBody = await context.request.body();

  // 2. Get the secret key from an environment variable (NEVER hardcode it)
  final openAIKey = Platform.environment['OPENAI_API_KEY'];

  if (openAIKey == null) {
    return Response(statusCode: 500, body: 'API Key not configured on server');
  }

  // 3. Make the secure request to OpenAI from the backend
  final response = await http.post(
    Uri.parse('https://api.openai.com/v1/chat/completions'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $openAIKey',
    },
    body: requestBody,
  );

  // 4. Send OpenAI's response back to your front-end
  return Response.bytes(
    body: response.bodyBytes,
    headers: {'Content-Type': 'application/json'},
  );
}
