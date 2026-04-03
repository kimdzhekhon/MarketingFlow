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

    var skills = _selectedCategory != null
        ? _knowledgeBase!.byCategory(_selectedCategory!)
        : _knowledgeBase!.skills;

    if (_searchQuery.isNotEmpty) {
      skills = _knowledgeBase!.search(_searchQuery);
      if (_selectedCategory != null) {
        skills =
            skills.where((s) => s.category == _selectedCategory).toList();
      }
    }

    return skills;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _knowledgeBase?.categories ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('MarketingFlow'),
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
                  padding: const EdgeInsets.all(16),
                  child: SearchBar(
                    hintText: '마케팅 스킬 검색...',
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

                // 카테고리 칩
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('전체'),
                          selected: _selectedCategory == null,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = null),
                        ),
                      ),
                      ...categories.map((cat) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              avatar: Icon(
                                _categoryIcons[cat] ?? Icons.category,
                                size: 18,
                              ),
                              label: Text(cat),
                              selected: _selectedCategory == cat,
                              onSelected: (_) => setState(() =>
                                  _selectedCategory =
                                      _selectedCategory == cat ? null : cat),
                            ),
                          )),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

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
                              Text(
                                '결과가 없습니다',
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredSkills.length,
                          itemBuilder: (context, index) {
                            final skill = _filteredSkills[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Icon(
                                    _categoryIcons[skill.category] ??
                                        Icons.category,
                                  ),
                                ),
                                title: Text(
                                  skill.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  skill.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing:
                                    const Icon(Icons.chevron_right),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SkillDetailScreen(
                                        skill: skill),
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
