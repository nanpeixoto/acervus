import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'acervus_colors.dart';

/// Tema global do Acervus — Material 3 + Inter, conforme mockup "Telas Acervus".
class AppTheme {
  // Mantidos como API pública (ThemeProvider e telas legadas dependem destes nomes)
  static const Color primaryColor = AcervusColors.primary;
  static const Color secondaryColor = AcervusColors.primaryDark;
  static const Color accentColor = AcervusColors.warning;
  static const Color backgroundColor = AcervusColors.background;
  static const Color cardColor = AcervusColors.surface;
  static const Color textColor = AcervusColors.textPrimary;
  static const Color subtitleColor = AcervusColors.textSecondary;

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AcervusColors.primary,
        primary: AcervusColors.primary,
        error: AcervusColors.danger,
        surface: AcervusColors.surface,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AcervusColors.background,
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AcervusColors.textPrimary,
      displayColor: AcervusColors.textPrimary,
    );

    return base.copyWith(
      textTheme: textTheme.copyWith(
        titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        titleMedium:
            textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        headlineSmall:
            textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AcervusColors.background,
        foregroundColor: AcervusColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AcervusColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AcervusColors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AcervusColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AcervusColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AcervusColors.textPrimary,
          side: const BorderSide(color: AcervusColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AcervusColors.primary,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AcervusColors.surface,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: const TextStyle(color: AcervusColors.textMuted),
        labelStyle: const TextStyle(color: AcervusColors.textSecondary),
        floatingLabelStyle: const TextStyle(color: AcervusColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AcervusColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AcervusColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AcervusColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AcervusColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AcervusColors.danger, width: 1.5),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AcervusColors.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AcervusColors.border),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AcervusColors.textPrimary,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AcervusColors.border,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      dataTableTheme: const DataTableThemeData(
        headingRowHeight: 44,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 56,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AcervusColors.primary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF111827),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      cardTheme: CardThemeData(
        color: const Color(0xFF1F2937),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF374151)),
        ),
      ),
    );
  }
}
