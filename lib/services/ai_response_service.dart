import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/marketing_skill.dart';

class AIResponseService {
  final String apiKey;
  final String baseUrl;
  final String model;

  AIResponseService({
    required this.apiKey,
    this.baseUrl = 'https://api.anthropic.com/v1/messages',
    this.model = 'claude-sonnet-4-20250514',
  });

  /// system_prompt와 사용자 입력 변수를 결합하여 LLM API와 통신합니다.
  Future<String> execute({
    required MarketingSkill skill,
    required Map<String, String> userInputs,
  }) async {
    // 시스템 프롬프트의 변수를 사용자 입력으로 치환
    String prompt = skill.systemPrompt;
    userInputs.forEach((key, value) {
      prompt = prompt.replaceAll('{$key}', value);
      prompt = prompt.replaceAll('{{$key}}', value);
      prompt = prompt.replaceAll('[${key.toUpperCase()}]', value);
    });

    final userMessage =
        '다음 마케팅 전략을 실행해주세요.\n\n'
        '카테고리: ${skill.category}\n'
        '스킬: ${skill.title}\n\n'
        '입력 데이터:\n${userInputs.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}';

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: json.encode({
          'model': model,
          'max_tokens': 4096,
          'system': prompt,
          'messages': [
            {'role': 'user', 'content': userMessage},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final content = data['content'] as List;
        return (content.first as Map<String, dynamic>)['text'] as String;
      } else {
        return '## 오류\n\nAPI 요청 실패 (${response.statusCode})\n\n'
            '```\n${response.body}\n```\n\n'
            'API 키를 설정 화면에서 확인해주세요.';
      }
    } catch (e) {
      return '## 연결 오류\n\n서버에 연결할 수 없습니다.\n\n`$e`';
    }
  }
}
