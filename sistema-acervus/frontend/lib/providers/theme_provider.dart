import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';

enum AppThemeMode {
  system,
  light,
  dark,
}

extension AppThemeModeExtension on AppThemeMode {
  String get name {
    switch (this) {
      case AppThemeMode.system:
        return 'system';
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
    }
  }

  String get displayName {
    switch (this) {
      case AppThemeMode.system:
        return 'Sistema';
      case AppThemeMode.light:
        return 'Claro';
      case AppThemeMode.dark:
        return 'Escuro';
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemeMode.system:
        return Icons.brightness_auto;
      case AppThemeMode.light:
        return Icons.brightness_high;
      case AppThemeMode.dark:
        return Icons.brightness_2;
    }
  }

  ThemeMode get themeMode {
    switch (this) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }
}

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.system;
  bool _highContrast = false;
  double _fontSize = 1.0; // Fator de escala da fonte
  bool _isLoading = false;

  // Cores personalizáveis
  Color _primaryColor = AppTheme.primaryColor;
  Color _accentColor = AppTheme.accentColor;

  // Getters
  AppThemeMode get themeMode => _themeMode;
  bool get highContrast => _highContrast;
  double get fontSize => _fontSize;
  bool get isLoading => _isLoading;
  Color get primaryColor => _primaryColor;
  Color get accentColor => _accentColor;

  // Getters para compatibilidade com UI
  bool get isDarkMode => _themeMode == AppThemeMode.dark;
  bool get isLightMode => _themeMode == AppThemeMode.light;
  bool get isSystemMode => _themeMode == AppThemeMode.system;

  // NOVO: Getter para compatibilidade com isHighContrast
  bool get isHighContrast => _highContrast;

  ThemeProvider() {
    _loadThemeSettings();
  }

  // ==========================================
  // INICIALIZAÇÃO E CARREGAMENTO
  // ==========================================

  Future<void> _loadThemeSettings() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Carrega modo do tema
      final themeModeInt = await StorageService.getThemeMode();
      if (themeModeInt != null && themeModeInt < AppThemeMode.values.length) {
        _themeMode = AppThemeMode.values[themeModeInt];
      }

      // Carrega alto contraste
      final highContrastValue = await StorageService.getHighContrast();
      if (highContrastValue != null) {
        _highContrast = highContrastValue;
      }

      // Carrega tamanho da fonte
      final fontSizeValue = await StorageService.getFontSize();
      if (fontSizeValue != null) {
        _fontSize = fontSizeValue;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      debugPrint('Erro ao carregar configurações de tema: $e');
      notifyListeners();
    }
  }

  // ==========================================
  // MÉTODOS DE CONFIGURAÇÃO DE TEMA
  // ==========================================

  /// Altera o modo do tema
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    await StorageService.setThemeMode(mode.index);
    notifyListeners();
  }

  /// Altera para tema claro
  Future<void> setLightTheme() async {
    await setThemeMode(AppThemeMode.light);
  }

  /// Altera para tema escuro
  Future<void> setDarkTheme() async {
    await setThemeMode(AppThemeMode.dark);
  }

  /// Altera para tema do sistema
  Future<void> setSystemTheme() async {
    await setThemeMode(AppThemeMode.system);
  }

  /// Alterna entre claro e escuro
  Future<void> toggleTheme() async {
    switch (_themeMode) {
      case AppThemeMode.light:
        await setDarkTheme();
        break;
      case AppThemeMode.dark:
        await setLightTheme();
        break;
      case AppThemeMode.system:
        await setLightTheme();
        break;
    }
  }

  // ==========================================
  // CONFIGURAÇÕES DE ACESSIBILIDADE
  // ==========================================

  /// Altera o alto contraste
  Future<void> setHighContrast(bool value) async {
    if (_highContrast == value) return;

    _highContrast = value;
    await StorageService.setHighContrast(value);
    notifyListeners();
  }

  /// Alterna alto contraste
  Future<void> toggleHighContrast() async {
    await setHighContrast(!_highContrast);
  }

  /// Altera o tamanho da fonte
  Future<void> setFontSize(double size) async {
    // Limita entre 0.8 e 1.5
    final clampedSize = size.clamp(0.8, 1.5);
    if (_fontSize == clampedSize) return;

    _fontSize = clampedSize;
    await StorageService.setFontSize(clampedSize);
    notifyListeners();
  }

  /// Aumenta tamanho da fonte
  Future<void> increaseFontSize() async {
    await setFontSize(_fontSize + 0.1);
  }

  /// Diminui tamanho da fonte
  Future<void> decreaseFontSize() async {
    await setFontSize(_fontSize - 0.1);
  }

  /// Reseta tamanho da fonte
  Future<void> resetFontSize() async {
    await setFontSize(1.0);
  }

  // ==========================================
  // CORES PERSONALIZADAS
  // ==========================================

  /// Altera cor primária
  Future<void> setPrimaryColor(Color color) async {
    if (_primaryColor == color) return;

    _primaryColor = color;
    // Pode salvar no storage se desejar persistir
    notifyListeners();
  }

  /// Altera cor de destaque
  Future<void> setAccentColor(Color color) async {
    if (_accentColor == color) return;

    _accentColor = color;
    notifyListeners();
  }

  /// Reseta cores para padrão
  Future<void> resetColors() async {
    _primaryColor = AppTheme.primaryColor;
    _accentColor = AppTheme.accentColor;
    notifyListeners();
  }

  // ==========================================
  // TEMAS GERADOS
  // ==========================================

  /// Retorna tema claro
  ThemeData get lightTheme {
    return _buildTheme(
      brightness: Brightness.light,
      primaryColor: _primaryColor,
      backgroundColor: _highContrast ? Colors.white : AppTheme.backgroundColor,
      cardColor: _highContrast ? Colors.white : AppTheme.cardColor,
      textColor: _highContrast ? Colors.black : AppTheme.textColor,
    );
  }

  /// Retorna tema escuro
  ThemeData get darkTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      primaryColor: _primaryColor,
      backgroundColor: _highContrast ? Colors.black : const Color(0xFF121212),
      cardColor: _highContrast ? Colors.black : const Color(0xFF1E1E1E),
      textColor: _highContrast ? Colors.white : Colors.white,
    );
  }

  /// Constrói tema personalizado
  ThemeData _buildTheme({
    required Brightness brightness,
    required Color primaryColor,
    required Color backgroundColor,
    required Color cardColor,
    required Color textColor,
  }) {
    final bool isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
        primary: primaryColor,
        secondary: _accentColor,
        surface: cardColor,
        background: backgroundColor,
      ),

      // Texto com escala personalizada
      textTheme: GoogleFonts.interTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ).apply(
        bodyColor: textColor,
        displayColor: textColor,
        fontSizeFactor: _fontSize,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20 * _fontSize,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: _highContrast ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: _highContrast
              ? BorderSide(color: textColor, width: 2)
              : BorderSide.none,
        ),
      ),

      // Botões elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12 * _fontSize,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: _highContrast
                ? const BorderSide(color: Colors.white, width: 2)
                : BorderSide.none,
          ),
          textStyle: TextStyle(
            fontSize: 16 * _fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Campos de texto
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: _highContrast ? textColor : Colors.grey,
            width: _highContrast ? 2 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: _highContrast ? textColor : Colors.grey,
            width: _highContrast ? 2 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: primaryColor,
            width: _highContrast ? 3 : 2,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12 * _fontSize,
        ),
        labelStyle: TextStyle(
          fontSize: 16 * _fontSize,
          color: textColor.withOpacity(0.7),
        ),
        hintStyle: TextStyle(
          fontSize: 16 * _fontSize,
          color: textColor.withOpacity(0.5),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        elevation: _highContrast ? 0 : 6,
        shape: _highContrast
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: const BorderSide(color: Colors.white, width: 2),
              )
            : null,
      ),

      // Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        indicatorColor: primaryColor.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontSize: 12 * _fontSize,
            fontWeight: FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? primaryColor
                : textColor.withOpacity(0.6),
          );
        }),
      ),

      // Drawer
      drawerTheme: DrawerThemeData(
        backgroundColor: cardColor,
        elevation: _highContrast ? 0 : 16,
        shape: _highContrast
            ? RoundedRectangleBorder(
                side: BorderSide(color: textColor, width: 2),
              )
            : null,
      ),

      // Divisores
      dividerTheme: DividerThemeData(
        color: textColor.withOpacity(_highContrast ? 1.0 : 0.2),
        thickness: _highContrast ? 2 : 1,
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: backgroundColor,
        selectedColor: primaryColor.withOpacity(0.2),
        labelStyle: TextStyle(
          fontSize: 14 * _fontSize,
          color: textColor,
        ),
        side: _highContrast
            ? BorderSide(color: textColor, width: 2)
            : BorderSide.none,
      ),
    );
  }

  // ==========================================
  // MÉTODOS UTILITÁRIOS
  // ==========================================

  /// Reseta todas as configurações
  Future<void> resetThemeSettings() async {
    _themeMode = AppThemeMode.system;
    _highContrast = false;
    _fontSize = 1.0;
    _primaryColor = AppTheme.primaryColor;
    _accentColor = AppTheme.accentColor;

    await StorageService.setThemeMode(_themeMode.index);
    await StorageService.setHighContrast(_highContrast);
    await StorageService.setFontSize(_fontSize);

    notifyListeners();
  }

  /// Obtém configurações atuais
  Map<String, dynamic> get currentSettings {
    return {
      'themeMode': _themeMode.name,
      'highContrast': _highContrast,
      'fontSize': _fontSize,
      'primaryColor': _primaryColor.value,
      'accentColor': _accentColor.value,
    };
  }

  /// Aplica configurações de um Map
  Future<void> applySettings(Map<String, dynamic> settings) async {
    if (settings['themeMode'] != null) {
      final mode = AppThemeMode.values.firstWhere(
        (m) => m.name == settings['themeMode'],
        orElse: () => AppThemeMode.system,
      );
      await setThemeMode(mode);
    }

    if (settings['highContrast'] != null) {
      await setHighContrast(settings['highContrast']);
    }

    if (settings['fontSize'] != null) {
      await setFontSize(settings['fontSize'].toDouble());
    }

    if (settings['primaryColor'] != null) {
      await setPrimaryColor(Color(settings['primaryColor']));
    }

    if (settings['accentColor'] != null) {
      await setAccentColor(Color(settings['accentColor']));
    }
  }

  /// Lista de temas predefinidos
  static List<Map<String, dynamic>> get presetThemes {
    return [
      {
        'name': 'Padrão',
        'primaryColor': AppTheme.primaryColor,
        'accentColor': AppTheme.accentColor,
      },
      {
        'name': 'Verde',
        'primaryColor': const Color(0xFF4CAF50),
        'accentColor': const Color(0xFF8BC34A),
      },
      {
        'name': 'Roxo',
        'primaryColor': const Color(0xFF9C27B0),
        'accentColor': const Color(0xFFE91E63),
      },
      {
        'name': 'Laranja',
        'primaryColor': const Color(0xFFFF9800),
        'accentColor': const Color(0xFFFF5722),
      },
      {
        'name': 'Azul Escuro',
        'primaryColor': const Color(0xFF1976D2),
        'accentColor': const Color(0xFF2196F3),
      },
    ];
  }

  /// Aplica tema predefinido
  Future<void> applyPresetTheme(Map<String, dynamic> preset) async {
    await setPrimaryColor(preset['primaryColor']);
    await setAccentColor(preset['accentColor']);
  }
}
