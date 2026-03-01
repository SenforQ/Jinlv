import 'dart:convert';

import 'package:http/http.dart' as http;

/// 智谱 AI 服务 - GLM-4-Flash
class ZhipuAiService {
  static const String _baseUrl = 'https://open.bigmodel.cn/api/paas/v4/chat/completions';
  static const String _apiKey = '0651fb69e3be429da628aab3b5f91c0a.JJiGHtnAbX5nquNi';
  static const String _model = 'glm-4-flash';

  /// 发送消息并获取回复（英文）
  static Future<String> chat(List<Map<String, String>> messages) async {
    final systemMsg = {
      'role': 'system',
      'content': 'You are a helpful travel assistant. Always reply in English.',
    };
    final allMessages = [systemMsg, ...messages];

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'messages': allMessages,
        'temperature': 0.7,
        'max_tokens': 2000,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('API error: ${response.statusCode} ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('No response from AI');
    }
    final content = choices[0]['message']?['content'] as String?;
    return content ?? '';
  }
}
