import 'dart:io';
import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;

Future<Response> onRequest(RequestContext context) async {
  // Get the session_id from the URL, e.g., /api/session?id=cs_test_...
  final sessionId = context.request.uri.queryParameters['id'];
  if (sessionId == null) {
    return Response(statusCode: 400, body: 'Session ID is required');
  }

  // Get your secret key from the server environment
  final stripeKey = Platform.environment['STRIPE_SECRET_KEY'];
  if (stripeKey == null) {
    return Response(statusCode: 500, body: 'Stripe key not configured.');
  }

  try {
    // Securely ask Stripe for the details of that specific session
    final response = await http.get(
      Uri.parse('https://api.stripe.com/v1/checkout/sessions/$sessionId'),
      headers: {
        'Authorization': 'Bearer $stripeKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    );

    // Send the details back to the front-end SuccessPage
    return Response.bytes(
      statusCode: response.statusCode,
      body: response.bodyBytes,
      headers: {HttpHeaders.contentTypeHeader: ContentType.json.mimeType},
    );
  } catch (e) {
    return Response(statusCode: 500, body: 'Failed to retrieve session');
  }
}
