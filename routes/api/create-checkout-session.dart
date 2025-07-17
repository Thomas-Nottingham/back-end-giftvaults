import 'dart:io';
import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final stripeKey = Platform.environment['STRIPE_SECRET_KEY'];
  if (stripeKey == null) {
    return Response(statusCode: 500, body: 'Stripe key not configured.');
  }

  final requestData = await context.request.json() as Map<String, dynamic>;

  // Manually build the request body for Stripe's API
  final body = <String, dynamic>{
    'payment_method_types[]': 'card',
    'line_items[0][price_data][currency]': requestData['currency'],
    'line_items[0][price_data][product_data][name]': requestData['title'],
    'line_items[0][price_data][unit_amount]': requestData['amount'],
    'line_items[0][quantity]': 1,
    'mode': 'payment',
    'success_url':
        '${requestData['successUrl']}?session_id={CHECKOUT_SESSION_ID}',
    'cancel_url': requestData['cancelUrl'],
    'shipping_address_collection[allowed_countries][]': 'GB',
  };

  if (requestData.containsKey('metadata')) {
    final metadata = requestData['metadata'] as Map<String, dynamic>;
    for (var entry in metadata.entries) {
      body['metadata[${entry.key}]'] = entry.value.toString();
    }
  }

  try {
    final response = await http.post(
      Uri.parse('https://api.stripe.com/v1/checkout/sessions'),
      headers: {
        'Authorization': 'Bearer $stripeKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body.map((key, value) => MapEntry(key, value.toString())),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final session = jsonDecode(response.body);
      return Response.json(body: {'url': session['url']});
    } else {
      print('Stripe Error: ${response.body}');
      return Response(statusCode: response.statusCode, body: response.body);
    }
  } catch (e) {
    print('Error creating checkout session: $e');
    return Response(statusCode: 500, body: 'Error creating session.');
  }
}
