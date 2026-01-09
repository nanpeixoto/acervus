// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import '../services/_core/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _isHighContrast = false;
  double _fontSize = 1.0;

  // Getters
  bool get isDarkMode => _isDarkMode;
  bool get isHighContrast => _isHighContrast;
  double get fontSize => _fontSize;

  ThemeProvider() {
    _loadThemePreferences();
  }

  // Carregar preferências salvas
  Future<void> _loadThemePreferences() async {
    try {
      _isDarkMode = await StorageService.getBool('dark_mode') ?? false;
      _isHighContrast = await StorageService.getBool('high_contrast') ?? false;
      _fontSize = await StorageService.getDouble('font_size') ?? 1.0;
      notifyListeners();
    } catch (e) {
      print('Erro ao carregar preferências de tema: $e');
    }
  }

  // Alternar tema escuro
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await StorageService.setBool('dark_mode', _isDarkMode);
    notifyListeners();
  }

  // Definir tema escuro
  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await StorageService.setBool('dark_mode', _isDarkMode);
    notifyListeners();
  }

  // Alternar alto contraste
  Future<void> toggleHighContrast() async {
    _isHighContrast = !_isHighContrast;
    await StorageService.setBool('high_contrast', _isHighContrast);
    notifyListeners();
  }

  // Definir alto contraste
  Future<void> setHighContrast(bool value) async {
    _isHighContrast = value;
    await StorageService.setBool('high_contrast', _isHighContrast);
    notifyListeners();
  }

  // Definir tamanho da fonte
  Future<void> setFontSize(double value) async {
    _fontSize = value.clamp(0.8, 1.5);
    await StorageService.setDouble('font_size', _fontSize);
    notifyListeners();
  }

  // Resetar todas as configurações
  Future<void> resetToDefaults() async {
    _isDarkMode = false;
    _isHighContrast = false;
    _fontSize = 1.0;

    await StorageService.setBool('dark_mode', _isDarkMode);
    await StorageService.setBool('high_contrast', _isHighContrast);
    await StorageService.setDouble('font_size', _fontSize);

    notifyListeners();
  }

  // Tema claro personalizado
  ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: _isHighContrast
            ? _highContrastLightColorScheme
            : ColorScheme.fromSeed(
                seedColor: const Color(0xFF2E7D32),
                brightness: Brightness.light,
              ),
        fontFamily: 'Roboto',
        textTheme: _buildTextTheme(Brightness.light),
      );

  // Tema escuro personalizado
  ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: _isHighContrast
            ? _highContrastDarkColorScheme
            : ColorScheme.fromSeed(
                seedColor: const Color(0xFF2E7D32),
                brightness: Brightness.dark,
              ),
        fontFamily: 'Roboto',
        textTheme: _buildTextTheme(Brightness.dark),
      );

  // Esquema de cores para alto contraste claro
  ColorScheme get _highContrastLightColorScheme => const ColorScheme.light(
        primary: Color(0xFF000000),
        onPrimary: Color(0xFFFFFFFF),
        secondary: Color(0xFF2E7D32),
        onSecondary: Color(0xFFFFFFFF),
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF000000),
      );

  // Esquema de cores para alto contraste escuro
  ColorScheme get _highContrastDarkColorScheme => const ColorScheme.dark(
        primary: Color(0xFFFFFFFF),
        onPrimary: Color(0xFF000000),
        secondary: Color(0xFF4CAF50),
        onSecondary: Color(0xFF000000),
        surface: Color(0xFF000000),
        onSurface: Color(0xFFFFFFFF),
      );

  // Construir tema de texto com tamanho personalizado
  TextTheme _buildTextTheme(Brightness brightness) {
    final baseTheme = brightness == Brightness.light
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;

    return baseTheme.copyWith(
      displayLarge: baseTheme.displayLarge?.copyWith(
        fontSize: (baseTheme.displayLarge?.fontSize ?? 57) * _fontSize,
      ),
      displayMedium: baseTheme.displayMedium?.copyWith(
        fontSize: (baseTheme.displayMedium?.fontSize ?? 45) * _fontSize,
      ),
      displaySmall: baseTheme.displaySmall?.copyWith(
        fontSize: (baseTheme.displaySmall?.fontSize ?? 36) * _fontSize,
      ),
      headlineLarge: baseTheme.headlineLarge?.copyWith(
        fontSize: (baseTheme.headlineLarge?.fontSize ?? 32) * _fontSize,
      ),
      headlineMedium: baseTheme.headlineMedium?.copyWith(
        fontSize: (baseTheme.headlineMedium?.fontSize ?? 28) * _fontSize,
      ),
      headlineSmall: baseTheme.headlineSmall?.copyWith(
        fontSize: (baseTheme.headlineSmall?.fontSize ?? 24) * _fontSize,
      ),
      titleLarge: baseTheme.titleLarge?.copyWith(
        fontSize: (baseTheme.titleLarge?.fontSize ?? 22) * _fontSize,
      ),
      titleMedium: baseTheme.titleMedium?.copyWith(
        fontSize: (baseTheme.titleMedium?.fontSize ?? 16) * _fontSize,
      ),
      titleSmall: baseTheme.titleSmall?.copyWith(
        fontSize: (baseTheme.titleSmall?.fontSize ?? 14) * _fontSize,
      ),
      bodyLarge: baseTheme.bodyLarge?.copyWith(
        fontSize: (baseTheme.bodyLarge?.fontSize ?? 16) * _fontSize,
      ),
      bodyMedium: baseTheme.bodyMedium?.copyWith(
        fontSize: (baseTheme.bodyMedium?.fontSize ?? 14) * _fontSize,
      ),
      bodySmall: baseTheme.bodySmall?.copyWith(
        fontSize: (baseTheme.bodySmall?.fontSize ?? 12) * _fontSize,
      ),
      labelLarge: baseTheme.labelLarge?.copyWith(
        fontSize: (baseTheme.labelLarge?.fontSize ?? 14) * _fontSize,
      ),
      labelMedium: baseTheme.labelMedium?.copyWith(
        fontSize: (baseTheme.labelMedium?.fontSize ?? 12) * _fontSize,
      ),
      labelSmall: baseTheme.labelSmall?.copyWith(
        fontSize: (baseTheme.labelSmall?.fontSize ?? 11) * _fontSize,
      ),
    );
  }

  // Obter cor primária baseada no tema atual
  Color get primaryColor {
    return _isDarkMode
        ? (_isHighContrast ? Colors.white : const Color(0xFF4CAF50))
        : (_isHighContrast ? Colors.black : const Color(0xFF2E7D32));
  }

  // Obter cor de fundo baseada no tema atual
  Color get backgroundColor {
    return _isDarkMode
        ? (_isHighContrast ? Colors.black : const Color(0xFF121212))
        : (_isHighContrast ? Colors.white : const Color(0xFFF5F5F5));
  }

  // Obter cor do texto baseada no tema atual
  Color get textColor {
    return _isDarkMode
        ? (_isHighContrast ? Colors.white : Colors.white)
        : (_isHighContrast ? Colors.black : Colors.black87);
  }
}
