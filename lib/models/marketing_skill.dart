import 'dart:convert';
import 'package:flutter/services.dart';

class MarketingSkill {
  final String id;
  final String category;
  final String title;
  final String description;
  final String systemPrompt;
  final List<String> variables;
  final String originPath;

  const MarketingSkill({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.systemPrompt,
    required this.variables,
    required this.originPath,
  });

  factory MarketingSkill.fromJson(Map<String, dynamic> json) {
    return MarketingSkill(
      id: json['id'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      systemPrompt: json['system_prompt'] as String,
      variables: List<String>.from(json['variables'] as List),
      originPath: json['origin_path'] as String,
    );
  }
}

class KnowledgeBase {
  final String version;
  final String lastUpdated;
  final List<MarketingSkill> skills;

  const KnowledgeBase({
    required this.version,
    required this.lastUpdated,
    required this.skills,
  });

  factory KnowledgeBase.fromJson(Map<String, dynamic> json) {
    return KnowledgeBase(
      version: json['version'] as String,
      lastUpdated: json['last_updated'] as String,
      skills: (json['skills'] as List)
          .map((e) => MarketingSkill.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static Future<KnowledgeBase> load() async {
    final jsonString =
        await rootBundle.loadString('assets/marketing_knowledge_base.json');
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    return KnowledgeBase.fromJson(jsonData);
  }

  List<String> get categories =>
      skills.map((s) => s.category).toSet().toList()..sort();

  List<MarketingSkill> byCategory(String category) =>
      skills.where((s) => s.category == category).toList();

  List<MarketingSkill> search(String query) {
    final q = query.toLowerCase();
    return skills
        .where((s) =>
            s.title.toLowerCase().contains(q) ||
            s.description.toLowerCase().contains(q) ||
            s.category.toLowerCase().contains(q))
        .toList();
  }
}
