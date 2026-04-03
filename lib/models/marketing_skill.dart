import 'dart:convert';
import 'package:flutter/services.dart';

class MarketingSkill {
  final String id;
  final String category;
  final String type;
  final String title;
  final String description;
  final String systemPrompt;
  final List<String> variables;
  final String originPath;
  final String fileName;

  const MarketingSkill({
    required this.id,
    required this.category,
    required this.type,
    required this.title,
    required this.description,
    required this.systemPrompt,
    required this.variables,
    required this.originPath,
    required this.fileName,
  });

  factory MarketingSkill.fromJson(Map<String, dynamic> json) {
    return MarketingSkill(
      id: json['id'] as String,
      category: json['category'] as String,
      type: json['type'] as String? ?? 'skill_definition',
      title: json['title'] as String,
      description: json['description'] as String,
      systemPrompt: json['system_prompt'] as String,
      variables: List<String>.from(json['variables'] as List),
      originPath: json['origin_path'] as String,
      fileName: json['file_name'] as String? ?? '',
    );
  }

  bool get isSkillDefinition => type == 'skill_definition';
  bool get isExpert => type == 'expert_persona';
  bool get isScript => type == 'automation_script';
  bool get isReference => type == 'reference';
  bool get isRubric => type == 'scoring_rubric';
  bool get isDoc => type == 'documentation';

  String get typeLabel {
    switch (type) {
      case 'skill_definition':
        return '스킬 정의';
      case 'expert_persona':
        return '전문가 페르소나';
      case 'automation_script':
        return '자동화 스크립트';
      case 'reference':
        return '참고자료';
      case 'scoring_rubric':
        return '평가 루브릭';
      case 'documentation':
        return '문서';
      case 'config_template':
        return '설정 템플릿';
      case 'config':
        return '설정';
      case 'requirements':
        return '의존성';
      default:
        return type;
    }
  }

  IconLabel get typeIcon {
    switch (type) {
      case 'skill_definition':
        return IconLabel(0xe1b0, 'purple');      // auto_awesome
      case 'expert_persona':
        return IconLabel(0xe7fd, 'blue');         // person
      case 'automation_script':
        return IconLabel(0xe86f, 'green');        // code
      case 'reference':
        return IconLabel(0xe873, 'orange');       // description
      case 'scoring_rubric':
        return IconLabel(0xef6e, 'red');          // grading
      case 'documentation':
        return IconLabel(0xe865, 'teal');         // article
      default:
        return IconLabel(0xe2c7, 'grey');         // settings
    }
  }
}

class IconLabel {
  final int codePoint;
  final String color;
  const IconLabel(this.codePoint, this.color);
}

class KnowledgeBase {
  final String version;
  final String lastUpdated;
  final int totalItems;
  final List<String> categoryList;
  final List<MarketingSkill> skills;

  const KnowledgeBase({
    required this.version,
    required this.lastUpdated,
    required this.totalItems,
    required this.categoryList,
    required this.skills,
  });

  factory KnowledgeBase.fromJson(Map<String, dynamic> json) {
    return KnowledgeBase(
      version: json['version'] as String,
      lastUpdated: json['last_updated'] as String,
      totalItems: json['total_items'] as int? ?? 0,
      categoryList: List<String>.from(json['categories'] as List? ?? []),
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

  List<String> get types =>
      skills.map((s) => s.type).toSet().toList()..sort();

  List<MarketingSkill> byCategory(String category) =>
      skills.where((s) => s.category == category).toList();

  List<MarketingSkill> byType(String type) =>
      skills.where((s) => s.type == type).toList();

  List<MarketingSkill> search(String query) {
    final q = query.toLowerCase();
    return skills
        .where((s) =>
            s.title.toLowerCase().contains(q) ||
            s.description.toLowerCase().contains(q) ||
            s.category.toLowerCase().contains(q) ||
            s.type.toLowerCase().contains(q) ||
            s.fileName.toLowerCase().contains(q))
        .toList();
  }
}
