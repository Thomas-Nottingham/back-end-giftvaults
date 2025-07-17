import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart';

Future<Response> onRequest(RequestContext context) async {
  final supabaseUrl = Platform.environment['SUPABASE_URL'];
  final supabaseKey = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];

  if (supabaseUrl == null || supabaseKey == null) {
    return Response(statusCode: 500, body: 'Supabase not configured');
  }

  final supabase = SupabaseClient(supabaseUrl, supabaseKey);
  final event = await context.request.json() as Map<String, dynamic>;

  if (event['type'] == 'checkout.session.completed') {
    final session = event['data']['object'] as Map<String, dynamic>;
    final metadata = session['metadata'] as Map<String, dynamic>;
    final stripeId = session['payment_intent'];

    // --- NEW LOGIC TO REASSEMBLE THE CONVERSATION ---
    // 1. Find all conversation parts in the metadata
    final convoParts = <int, String>{};
    metadata.forEach((key, value) {
      if (key.startsWith('convo_part_')) {
        final index = int.tryParse(key.split('_').last);
        if (index != null) {
          convoParts[index] = value as String;
        }
      }
    });

    // 2. Sort them by their index and join them back together
    final sortedKeys = convoParts.keys.toList()..sort();
    final fullConversation = sortedKeys.map((k) => convoParts[k]).join('');
    // ---------------------------------------------

    try {
      await supabase.from('cart_items').insert({
        'name': metadata['name'],
        'purchase_amount': (session['amount_total'] as int) / 100,
        'convo_summary': metadata['giftSummary'],
        'convo_history': fullConversation, // Save the reassembled conversation
        'stripe_id': stripeId,
        'foreign_key': metadata['foreignKey'],
      });
      return Response(statusCode: 200);
    } catch (e) {
      print('Supabase Insert Error: $e');
      return Response(statusCode: 500);
    }
  }

  return Response(statusCode: 200, body: 'Event type not handled');
}
