import 'package:flutter/material.dart';
import '../app_state.dart';
import '../l10n/app_locale.dart';
import '../models/marketing_skill.dart';
import '../theme.dart';
import 'skill_detail_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppState appState;
  const HomeScreen({super.key, required this.appState});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  KnowledgeBase? _kb;
  String? _selectedCategory;
  String? _selectedType;
  String _searchQuery = '';
  bool _isLoading = true;

  AppLocale get l => widget.appState.locale;

  static const _categoryIcons = <String, IconData>{
    '콘텐츠 운영': Icons.edit_note,
    '전환 최적화': Icons.trending_up,
    '재무 운영': Icons.account_balance,
    '성장 엔진': Icons.rocket_launch,
    '아웃바운드 엔진': Icons.campaign,
    '팟캐스트 운영': Icons.podcasts,
    '매출 인텔리전스': Icons.insights,
    '세일즈 파이프라인': Icons.filter_alt,
    '세일즈 플레이북': Icons.menu_book,
    'SEO 운영': Icons.travel_explore,
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
        _kb = kb;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<MarketingSkill> get _filtered {
    if (_kb == null) return [];
    var skills = _kb!.skills;
    if (_selectedCategory != null) {
      skills = skills.where((s) => s.category == _selectedCategory).toList();
    }
    if (_selectedType != null) {
      skills = skills.where((s) => s.type == _selectedType).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      skills = skills.where((s) =>
          s.title.toLowerCase().contains(q) ||
          s.description.toLowerCase().contains(q) ||
          s.category.toLowerCase().contains(q) ||
          s.fileName.toLowerCase().contains(q)).toList();
    }
    return skills;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _kb?.categories ?? [];
    final types = _kb?.types ?? [];
    final total = _kb?.totalItems ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/app_icon.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text('MarketingFlow', style: TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            )),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 22),
            tooltip: l.settings,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => SettingsScreen(appState: widget.appState))),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 22),
            tooltip: l.aboutTitle,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => AboutScreen(locale: l))),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: SearchBar(
                    hintText: '${l.searchHint} (${l.itemCount(total)})',
                    leading: Icon(Icons.search, color: theme.colorScheme.outline),
                    onChanged: (q) => setState(() => _searchQuery = q),
                    trailing: _searchQuery.isNotEmpty
                        ? [IconButton(icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => setState(() => _searchQuery = ''))]
                        : null,
                  ),
                ),

                // Type filters
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildChip(l.allTypes, _selectedType == null, () =>
                          setState(() => _selectedType = null)),
                      ...types.map((t) => _buildChip(
                        l.typeLabel(t),
                        _selectedType == t,
                        () => setState(() => _selectedType = _selectedType == t ? null : t),
                        color: AppTheme.typeColor(t),
                      )),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // Category filters
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildChip(l.allCategories, _selectedCategory == null, () =>
                          setState(() => _selectedCategory = null)),
                      ...categories.map((cat) => _buildChip(
                        l.categoryLabel(cat),
                        _selectedCategory == cat,
                        () => setState(() => _selectedCategory = _selectedCategory == cat ? null : cat),
                        icon: _categoryIcons[cat],
                        color: AppTheme.categoryColor(cat),
                      )),
                    ],
                  ),
                ),

                // Result count
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Row(
                    children: [
                      Text(l.resultCount(_filtered.length),
                          style: theme.textTheme.bodySmall),
                      if (_selectedCategory != null || _selectedType != null) ...[
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() {
                            _selectedCategory = null;
                            _selectedType = null;
                          }),
                          child: Text(l.resetFilters,
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.primary)),
                        ),
                      ],
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded, size: 56, color: theme.colorScheme.outline),
                            const SizedBox(height: 12),
                            Text(l.noResults, style: theme.textTheme.titleMedium),
                          ],
                        ))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _buildSkillCard(_filtered[i], theme),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildChip(String label, bool selected, VoidCallback onTap,
      {IconData? icon, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        avatar: icon != null ? Icon(icon, size: 15,
            color: selected ? color : null) : null,
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        selectedColor: color?.withValues(alpha: 0.12),
        checkmarkColor: color,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildSkillCard(MarketingSkill skill, ThemeData theme) {
    final catColor = AppTheme.categoryColor(skill.category);
    final tColor = AppTheme.typeColor(skill.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) =>
                SkillDetailScreen(skill: skill, appState: widget.appState))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _categoryIcons[skill.category] ?? Icons.category,
                  color: catColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_displayTitle(skill),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(skill.description,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _typeBadge(l.typeLabel(skill.type), tColor),
                        const SizedBox(width: 6),
                        _typeBadge(l.categoryLabel(skill.category), catColor),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20,
                  color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }

  String _displayTitle(MarketingSkill skill) {
    if (l.isKo && skill.titleKo.isNotEmpty) return skill.titleKo;
    return skill.title;
  }

  Widget _typeBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
    );
  }
}
