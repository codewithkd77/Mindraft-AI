import 'package:supabase_flutter/supabase_flutter.dart';

class ApiKeys {
  // Gemini API Key
  static Future<String> get geminiApiKey async {
    try {
      final response = await Supabase.instance.client
          .from('api_keys')
          .select()
          .eq('key_name', 'gemini')
          .single();
      return response['key_value'] as String;
    } catch (e) {
      print('Error fetching response: $e');
      return '';
    }

    // Add other API keys here as needed
    // static const String otherApiKey = 'your-other-api-key';
  }
}
