import 'package:flutter/material.dart';

/// MarketingFlow brand colors
/// Warm coral + neutral slate — professional marketing feel, not techy/AI
class AppTheme {
  AppTheme._();

  // Brand palette
  static const _brand = Color(0xFFE8604C);       // Warm coral
  static const _brandDark = Color(0xFFD4503E);    // Deeper coral for dark mode
  static const _accent = Color(0xFFF5A623);       // Amber accent
  static const _surface = Color(0xFFFAF8F6);      // Warm off-white
  static const _surfaceDark = Color(0xFF1C1917);  // Warm dark

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _brand,
          brightness: Brightness.light,
          primary: _brand,
          secondary: _accent,
          surface: _surface,
          onSurface: const Color(0xFF1C1917),
        ),
        scaffoldBackgroundColor: _surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1C1917),
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE7E5E4), width: 1),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF5F3F0),
          selectedColor: _brand.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE7E5E4)),
          ),
        ),
        searchBarTheme: SearchBarThemeData(
          backgroundColor: WidgetStatePropertyAll(Colors.white),
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE7E5E4)),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _brand,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE7E5E4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE7E5E4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _brand, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dividerColor: const Color(0xFFE7E5E4),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1C1917),
            letterSpacing: -0.5,
          ),
          titleLarge: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C1917),
          ),
          titleMedium: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C1917),
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF44403C),
          ),
          bodySmall: TextStyle(
            color: Color(0xFF78716C),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _brandDark,
          brightness: Brightness.dark,
          primary: _brandDark,
          secondary: _accent,
          surface: _surfaceDark,
          onSurface: const Color(0xFFFAFAF9),
        ),
        scaffoldBackgroundColor: _surfaceDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF292524),
          foregroundColor: Color(0xFFFAFAF9),
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF292524),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF44403C), width: 1),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF292524),
          selectedColor: _brandDark.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF44403C)),
          ),
        ),
        searchBarTheme: SearchBarThemeData(
          backgroundColor: const WidgetStatePropertyAll(Color(0xFF292524)),
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF44403C)),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _brandDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF292524),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF44403C)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF44403C)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _brandDark, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dividerColor: const Color(0xFF44403C),
      );

  // Category colors — warm, muted palette
  static const categoryColors = <String, Color>{
    '콘텐츠 운영': Color(0xFFE8604C),   // Coral
    '전환 최적화': Color(0xFFF5A623),   // Amber
    '재무 운영': Color(0xFF4A9B7F),     // Sage green
    '성장 엔진': Color(0xFFE07B39),     // Burnt orange
    '아웃바운드 엔진': Color(0xFF5B8BD4), // Soft blue
    '팟캐스트 운영': Color(0xFFC06AB3),  // Mauve
    '매출 인텔리전스': Color(0xFF7B9F35), // Olive
    '세일즈 파이프라인': Color(0xFF4DAAAB), // Teal
    '세일즈 플레이북': Color(0xFFD4503E), // Red-coral
    'SEO 운영': Color(0xFF8B6EC0),      // Lavender
    '팀 운영': Color(0xFF6B8E8E),       // Slate teal
    '보안': Color(0xFF9B8579),          // Warm taupe
    '텔레메트리': Color(0xFF7E8C9E),    // Cool grey
  };

  static Color categoryColor(String category) =>
      categoryColors[category] ?? const Color(0xFF78716C);

  // Type colors — subtle muted tones
  static Color typeColor(String type) {
    switch (type) {
      case 'skill_definition':
        return const Color(0xFFE8604C);
      case 'expert_persona':
        return const Color(0xFF5B8BD4);
      case 'automation_script':
        return const Color(0xFF4A9B7F);
      case 'reference':
        return const Color(0xFFF5A623);
      case 'scoring_rubric':
        return const Color(0xFFC06AB3);
      case 'documentation':
        return const Color(0xFF6B8E8E);
      default:
        return const Color(0xFF9B8579);
    }
  }
}
