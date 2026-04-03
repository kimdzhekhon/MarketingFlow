import 'package:flutter/material.dart';
import '../models/marketing_skill.dart';
import 'skill_detail_screen.dart';
import 'about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  KnowledgeBase? _knowledgeBase;
  String? _selectedCategory;
  String? _selectedType;
  String _searchQuery = '';
  bool _isLoading = true;

  static const _categoryIcons = <String, IconData>{
    '콘텐츠 운영': Icons.edit_note,
    '전환 최적화': Icons.trending_up,
    '재무 운영': Icons.account_balance,
    '성장 엔진': Icons.rocket_launch,
    '아웃바운드 엔진': Icons.send,
    '팟캐스트 운영': Icons.podcasts,
    '매출 인텔리전스': Icons.insights,
    '세일즈 파이프라인': Icons.filter_alt,
    '세일즈 플레이북': Icons.menu_book,
    'SEO 운영': Icons.search,
    '팀 운영': Icons.groups,
    '보안': Icons.security,
    '텔레메트리': Icons.analytics,
  };

  static const _typeLabels = <String, String>{
    'skill_definition': '스킬 정의',
    'expert_persona': '전문가',
    'automation_script': '스크립트',
    'reference': '참고자료',
    'scoring_rubric': '루브릭',
    'documentation': '문서',
    'config_template': '설정',
    'config': '설정',
    'requirements': '의존성',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final kb = await KnowledgeBase.load();
      setState(() {
        _knowledgeBase = kb;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로딩 실패: $e')),
        );
      }
    }
  }

  List<MarketingSkill> get _filteredSkills {
    if (_knowledgeBase == null) return [];

    var skills = _knowledgeBase!.skills;

    if (_selectedCategory != null) {
      skills = skills.where((s) => s.category == _selectedCategory).toList();
    }

    if (_selectedType != null) {
      skills = skills.where((s) => s.type == _selectedType).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      skills = skills
          .where((s) =>
              s.title.toLowerCase().contains(q) ||
              s.description.toLowerCase().contains(q) ||
              s.category.toLowerCase().contains(q) ||
              s.fileName.toLowerCase().contains(q))
          .toList();
    }

    return skills;
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'skill_definition': return Colors.purple;
      case 'expert_persona': return Colors.blue;
      case 'automation_script': return Colors.green;
      case 'reference': return Colors.orange;
      case 'scoring_rubric': return Colors.red;
      case 'documentation': return Colors.teal;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _knowledgeBase?.categories ?? [];
    final types = _knowledgeBase?.types ?? [];
    final total = _knowledgeBase?.totalItems ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 24),
            const SizedBox(width: 8),
            const Text('MarketingFlow'),
            if (total > 0) ...[
              const SizedBox(width: 8),
              Badge(
                label: Text('$total'),
                backgroundColor: theme.colorScheme.primary,
              ),
            ],
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: '라이선스 및 정보',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 검색바
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: SearchBar(
                    hintText: '마케팅 스킬 검색... ($total개 항목)',
                    leading: const Icon(Icons.search),
                    onChanged: (q) => setState(() => _searchQuery = q),
                    trailing: _searchQuery.isNotEmpty
                        ? [
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () =>
                                  setState(() => _searchQuery = ''),
                            ),
                          ]
                        : null,
                  ),
                ),

                // 타입 필터
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: const Text('전체 타입'),
                          selected: _selectedType == null,
                          onSelected: (_) =>
                              setState(() => _selectedType = null),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      ...types.map((type) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(_typeLabels[type] ?? type),
                              selected: _selectedType == type,
                              selectedColor: _typeColor(type).withValues(alpha: 0.2),
                              onSelected: (_) => setState(() =>
                                  _selectedType =
                                      _selectedType == type ? null : type),
                              visualDensity: VisualDensity.compact,
                            ),
                          )),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // 카테고리 필터
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: const Text('전체'),
                          selected: _selectedCategory == null,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = null),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      ...categories.map((cat) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              avatar: Icon(
                                _categoryIcons[cat] ?? Icons.category,
                                size: 16,
                              ),
                              label: Text(cat),
                              selected: _selectedCategory == cat,
                              onSelected: (_) => setState(() =>
                                  _selectedCategory =
                                      _selectedCategory == cat ? null : cat),
                              visualDensity: VisualDensity.compact,
                            ),
                          )),
                    ],
                  ),
                ),

                // 결과 카운트
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      Text(
                        '${_filteredSkills.length}개 결과',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      if (_selectedCategory != null || _selectedType != null) ...[
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(Icons.clear_all, size: 16),
                          label: const Text('필터 초기화'),
                          onPressed: () => setState(() {
                            _selectedCategory = null;
                            _selectedType = null;
                          }),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // 스킬 목록
                Expanded(
                  child: _filteredSkills.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off,
                                  size: 64,
                                  color: theme.colorScheme.outline),
                              const SizedBox(height: 16),
                              Text('결과가 없습니다',
                                  style: theme.textTheme.titleMedium),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _filteredSkills.length,
                          itemBuilder: (context, index) {
                            final skill = _filteredSkills[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _typeColor(skill.type).withValues(alpha: 0.15),
                                  child: Icon(
                                    _categoryIcons[skill.category] ?? Icons.category,
                                    color: _typeColor(skill.type),
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  skill.title,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      skill.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: _typeColor(skill.type).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            skill.typeLabel,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: _typeColor(skill.type),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            skill.originPath,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: theme.colorScheme.outline,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right, size: 18),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SkillDetailScreen(skill: skill),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
