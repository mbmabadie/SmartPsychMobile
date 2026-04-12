import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../theme/app_colors.dart';

enum ThemeMode { system, light, dark }

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isDarkMode = false;

  // Theme customization
  Color _primaryColor = AppColors.primary;
  Color _accentColor = AppColors.accent;
  String _fontFamily = 'NotoSansArabic';

  // UI preferences
  bool _useSystemColors = false;
  bool _highContrast = false;
  double _textScale = 1.0;
  bool _animationsEnabled = true;

  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _isDarkMode;
  Color get primaryColor => _primaryColor;
  Color get accentColor => _accentColor;
  String get fontFamily => _fontFamily;
  bool get useSystemColors => _useSystemColors;
  bool get highContrast => _highContrast;
  double get textScale => _textScale;
  bool get animationsEnabled => _animationsEnabled;

  // Initialize theme provider
  Future<void> initialize() async {
    await _loadThemePreferences();
    _updateDarkMode();
  }

  // Load theme preferences
  Future<void> _loadThemePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final themeModeString = prefs.getString(AppConstants.keyThemeMode) ?? 'system';
      _themeMode = _parseThemeMode(themeModeString);

      _primaryColor = Color(prefs.getInt('primary_color') ?? AppColors.primary.value);
      _accentColor = Color(prefs.getInt('accent_color') ?? AppColors.accent.value);
      _fontFamily = prefs.getString('font_family') ?? 'NotoSansArabic';
      _useSystemColors = prefs.getBool('use_system_colors') ?? false;
      _highContrast = prefs.getBool('high_contrast') ?? false;
      _textScale = prefs.getDouble('text_scale') ?? 1.0;
      _animationsEnabled = prefs.getBool('animations_enabled') ?? true;

    } catch (e) {
      debugPrint('Error loading theme preferences: $e');
    }
  }

  // Parse theme mode from string
  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // Convert theme mode to string
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }

  // Update dark mode based on theme mode and system settings
  void _updateDarkMode() {
    switch (_themeMode) {
      case ThemeMode.light:
        _isDarkMode = false;
        break;
      case ThemeMode.dark:
        _isDarkMode = true;
        break;
      case ThemeMode.system:
      // This would normally check system theme, but we'll default to light
        _isDarkMode = false;
        break;
    }
  }

  // Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyThemeMode, _themeModeToString(mode));

      _themeMode = mode;
      _updateDarkMode();
      notifyListeners();

    } catch (e) {
      debugPrint('Error setting theme mode: $e');
    }
  }

  // Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final newMode = _isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  // Set primary color
  Future<void> setPrimaryColor(Color color) async {
    if (_primaryColor == color) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('primary_color', color.value);

      _primaryColor = color;
      notifyListeners();

    } catch (e) {
      debugPrint('Error setting primary color: $e');
    }
  }

  // Set accent color
  Future<void> setAccentColor(Color color) async {
    if (_accentColor == color) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('accent_color', color.value);

      _accentColor = color;
      notifyListeners();

    } catch (e) {
      debugPrint('Error setting accent color: $e');
    }
  }

  // Set font family
  Future<void> setFontFamily(String fontFamily) async {
    if (_fontFamily == fontFamily) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('font_family', fontFamily);

      _fontFamily = fontFamily;
      notifyListeners();

    } catch (e) {
      debugPrint('Error setting font family: $e');
    }
  }

  // Set use system colors
  Future<void> setUseSystemColors(bool useSystem) async {
    if (_useSystemColors == useSystem) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('use_system_colors', useSystem);

      _useSystemColors = useSystem;

      if (useSystem) {
        // Reset to default colors when using system colors
        _primaryColor = AppColors.primary;
        _accentColor = AppColors.accent;
      }

      notifyListeners();

    } catch (e) {
      debugPrint('Error setting use system colors: $e');
    }
  }

  // Set high contrast
  Future<void> setHighContrast(bool highContrast) async {
    if (_highContrast == highContrast) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('high_contrast', highContrast);

      _highContrast = highContrast;
      notifyListeners();

    } catch (e) {
      debugPrint('Error setting high contrast: $e');
    }
  }

  // Set text scale
  Future<void> setTextScale(double scale) async {
    if (_textScale == scale) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('text_scale', scale);

      _textScale = scale.clamp(0.8, 1.4);
      notifyListeners();

    } catch (e) {
      debugPrint('Error setting text scale: $e');
    }
  }

  // Set animations enabled
  Future<void> setAnimationsEnabled(bool enabled) async {
    if (_animationsEnabled == enabled) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('animations_enabled', enabled);

      _animationsEnabled = enabled;
      notifyListeners();

    } catch (e) {
      debugPrint('Error setting animations enabled: $e');
    }
  }

  // Get light theme data
  ThemeData getLightTheme() {
    final colorScheme = _useSystemColors
        ? ColorScheme.fromSeed(seedColor: _primaryColor)
        : ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: _highContrast ? _getHighContrastLightScheme() : colorScheme,
      primaryColor: _primaryColor,
      fontFamily: _fontFamily,

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: _isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
        foregroundColor: _isDarkMode ? AppColors.textLight : AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 20 * _textScale,
          fontWeight: FontWeight.bold,
          color: _isDarkMode ? AppColors.textLight : AppColors.textPrimary,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: _highContrast ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_highContrast ? 8 : 16),
          side: _highContrast ? BorderSide(color: AppColors.borderLight, width: 2) : BorderSide.none,
        ),
        color: AppColors.cardLight,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          textStyle: TextStyle(
            fontFamily: _fontFamily,
            fontSize: 16 * _textScale,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_highContrast ? 8 : 12),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 24 * _textScale,
            vertical: 12 * _textScale,
          ),
          elevation: _highContrast ? 8 : 2,
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryColor,
          textStyle: TextStyle(
            fontFamily: _fontFamily,
            fontSize: 16 * _textScale,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_highContrast ? 8 : 12),
          borderSide: BorderSide(
            color: _highContrast ? AppColors.borderLight : AppColors.borderLight,
            width: _highContrast ? 2 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_highContrast ? 8 : 12),
          borderSide: BorderSide(
            color: AppColors.borderLight,
            width: _highContrast ? 2 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_highContrast ? 8 : 12),
          borderSide: BorderSide(
            color: _primaryColor,
            width: 2,
          ),
        ),
        fillColor: AppColors.inputFillLight,
        filled: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16 * _textScale,
          vertical: 12 * _textScale,
        ),
      ),

      // Text Theme
      textTheme: _getTextTheme(false),

      // Icon Theme
      iconTheme: IconThemeData(
        color: AppColors.textPrimary,
        size: 24 * _textScale,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: AppColors.divider,
        thickness: _highContrast ? 2 : 1,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(_primaryColor),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryColor.withOpacity(0.5);
          }
          return AppColors.borderLight;
        }),
      ),
    );
  }

  // Get dark theme data
  ThemeData getDarkTheme() {
    final colorScheme = _useSystemColors
        ? ColorScheme.fromSeed(seedColor: _primaryColor, brightness: Brightness.dark)
        : ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: _highContrast ? _getHighContrastDarkScheme() : colorScheme,
      primaryColor: _primaryColor,
      fontFamily: _fontFamily,

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 20 * _textScale,
          fontWeight: FontWeight.bold,
          color: AppColors.textLight,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: _highContrast ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_highContrast ? 8 : 16),
          side: _highContrast ? BorderSide(color: AppColors.borderDark, width: 2) : BorderSide.none,
        ),
        color: AppColors.cardDark,
      ),

      // Text Theme
      textTheme: _getTextTheme(true),

      // Icon Theme
      iconTheme: IconThemeData(
        color: AppColors.textLight,
        size: 24 * _textScale,
      ),

      // Additional dark theme configurations...
    );
  }

  // Get text theme
  TextTheme _getTextTheme(bool isDark) {
    final baseColor = isDark ? AppColors.textLight : AppColors.textPrimary;
    final secondaryColor = isDark ? AppColors.textLight.withOpacity(0.7) : AppColors.textSecondary;

    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 32 * _textScale,
        fontWeight: FontWeight.bold,
        color: baseColor,
      ),
      displayMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 28 * _textScale,
        fontWeight: FontWeight.bold,
        color: baseColor,
      ),
      displaySmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 24 * _textScale,
        fontWeight: FontWeight.bold,
        color: baseColor,
      ),
      headlineLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 22 * _textScale,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20 * _textScale,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      headlineSmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18 * _textScale,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      titleLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16 * _textScale,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      titleMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14 * _textScale,
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),
      titleSmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12 * _textScale,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
      ),
      bodyLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16 * _textScale,
        fontWeight: FontWeight.normal,
        color: baseColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14 * _textScale,
        fontWeight: FontWeight.normal,
        color: baseColor,
      ),
      bodySmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12 * _textScale,
        fontWeight: FontWeight.normal,
        color: secondaryColor,
      ),
      labelLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14 * _textScale,
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),
      labelMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12 * _textScale,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
      ),
      labelSmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 10 * _textScale,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
      ),
    );
  }

  // Get high contrast light color scheme
  ColorScheme _getHighContrastLightScheme() {
    return ColorScheme.light(
      primary: _primaryColor,
      secondary: _accentColor,
      surface: Colors.white,
      error: Colors.red.shade700,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black,
      onError: Colors.white,
      outline: Colors.black,
    );
  }

  // Get high contrast dark color scheme
  ColorScheme _getHighContrastDarkScheme() {
    return ColorScheme.dark(
      primary: _primaryColor,
      secondary: _accentColor,
      surface: Colors.black,
      error: Colors.red.shade300,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      onError: Colors.black,
      outline: Colors.white,
    );
  }

  // Reset theme to defaults
  Future<void> resetTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Remove theme-related keys
      await prefs.remove(AppConstants.keyThemeMode);
      await prefs.remove('primary_color');
      await prefs.remove('accent_color');
      await prefs.remove('font_family');
      await prefs.remove('use_system_colors');
      await prefs.remove('high_contrast');
      await prefs.remove('text_scale');
      await prefs.remove('animations_enabled');

      // Reset to defaults
      _themeMode = ThemeMode.system;
      _primaryColor = AppColors.primary;
      _accentColor = AppColors.accent;
      _fontFamily = 'NotoSansArabic';
      _useSystemColors = false;
      _highContrast = false;
      _textScale = 1.0;
      _animationsEnabled = true;

      _updateDarkMode();
      notifyListeners();

    } catch (e) {
      debugPrint('Error resetting theme: $e');
    }
  }

  // Export theme settings
  Map<String, dynamic> exportThemeSettings() {
    return {
      'theme_mode': _themeModeToString(_themeMode),
      'primary_color': _primaryColor.value,
      'accent_color': _accentColor.value,
      'font_family': _fontFamily,
      'use_system_colors': _useSystemColors,
      'high_contrast': _highContrast,
      'text_scale': _textScale,
      'animations_enabled': _animationsEnabled,
    };
  }

  // Get available font families
  List<String> get availableFonts => [
    'NotoSansArabic',
    'Cairo',
    'Amiri',
    'Roboto',
    'OpenSans',
  ];

  // Get available primary colors
  List<Color> get availablePrimaryColors => [
    AppColors.primary,
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.red,
    Colors.teal,
    Colors.indigo,
  ];
}