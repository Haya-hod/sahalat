import 'package:flutter/material.dart';

///

class AppColors {

  static const Color primary = Color(0xFF0061FF);
  static const Color primaryDark = Color(0xFF0048CC);
  static const Color primaryLight = Color(0xFF4D94FF);


  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF059669);
  
  static const Color green = Color(0xFF16A34A);
  static const Color greenLight = Color(0xFF22C55E);
  static const Color greenPale = Color(0xFFDCFCE7);
  static const Color primaryMid = Color(0xFF1E5FA8);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFD97706);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFFDC2626);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDEBEFC);
  static const Color infoDark = Color(0xFF1F77F5);


  static const Color background = Color(0xFFF8FAFC);

  static const Color surface = Color(0xFFFFFFFF);

  static const Color surfaceAlt = Color(0xFFF1F5F9);

  static const Color surfaceNeutral = Color(0xFFF3F4F6);


  static const Color textPrimary = Color(0xFF0F172A);

  static const Color textSecondary = Color(0xFF475569);

  static const Color textHint = Color(0xFF94A3B8);

  static const Color textDisabled = Color(0xFFCBD5E1);


  static const Color border = Color(0xFFE2E8F0);

  static const Color borderStrong = Color(0xFFCBD5E1);

  static const Color divider = Color(0xFFE2E8F0);


  static const Color cardSuccessBg = Color(0xFFF0FDF4);
  static const Color cardSuccessBorder = Color(0xFFD1FAE5);

  static const Color cardWarningBg = Color(0xFFFEF3C7);
  static const Color cardWarningBorder = Color(0xFFFCD34D);

  static const Color cardErrorBg = Color(0xFFFEE2E2);
  static const Color cardErrorBorder = Color(0xFFFCACA);

  static const Color cardInfoBg = Color(0xFFEFF6FF);
  static const Color cardInfoBorder = Color(0xFFBFDBFE);
  
  static const Color cardRed = Color(0xFFFEF2F2);
  static const Color cardYellow = Color(0xFFFFFBEB);
  static const Color cardBlue = Color(0xFFEFF6FF);
  static const Color cardGreen = Color(0xFFF0FDF4);


  static const Color stadiumGreen = Color(0xFF16A34A);
  static const Color stadiumGreenLight = Color(0xFF86EFAC);

  static const Color seatBlue = Color(0xFF1E40AF);
  static const Color seatBlueDark = Color(0xFF1E3A8A);


  static const Color crowdLow = Color(0xFF10B981);
  static const Color crowdLowLight = Color(0xFFD1FAE5);

  static const Color crowdMedium = Color(0xFFF59E0B);
  static const Color crowdMediumLight = Color(0xFFFEF3C7);

  static const Color crowdHigh = Color(0xFFEF4444);
  static const Color crowdHighLight = Color(0xFFFEE2E2);


  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowMedium = Color(0x19000000);
  static const Color shadowDark = Color(0x33000000);


  static const Color overlay = Color(0x4C000000);
  static const Color overlayLight = Color(0x19000000);


  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0061FF), Color(0xFF4D94FF)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF6EE7B7)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFFFD66F)],
  );

  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFFFCA5A5)],
  );

  static const LinearGradient stadiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF16A34A), Color(0xFF0F766E)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0061FF), Color(0xFF10B981)],
  );


  static Color getCrowdColor(double percentage) {
    if (percentage < 30) {
      return crowdLow;
    } else if (percentage < 60) {
      return crowdMedium;
    } else {
      return crowdHigh;
    }
  }

  static String getCrowdStatus(double percentage) {
    if (percentage < 30) {
      return 'Low Congestion';
    } else if (percentage < 60) {
      return 'Medium Congestion';
    } else {
      return 'High Congestion';
    }
  }

  static Color getCardBackground(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'valid':
        return cardSuccessBg;
      case 'warning':
        return cardWarningBg;
      case 'error':
      case 'expired':
        return cardErrorBg;
      case 'info':
      default:
        return cardInfoBg;
    }
  }

  static Color getCardBorder(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'valid':
        return cardSuccessBorder;
      case 'warning':
        return cardWarningBorder;
      case 'error':
      case 'expired':
        return cardErrorBorder;
      case 'info':
      default:
        return cardInfoBorder;
    }
  }

  static LinearGradient getGradient(String type) {
    switch (type.toLowerCase()) {
      case 'success':
        return successGradient;
      case 'warning':
        return warningGradient;
      case 'error':
        return errorGradient;
      case 'stadium':
        return stadiumGradient;
      case 'splash':
        return splashGradient;
      default:
        return primaryGradient;
    }
  }

  static Color getTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? textPrimary : Colors.white;
  }


  static List<BoxShadow> get shadowSmall => [
    const BoxShadow(
      color: shadowLight,
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMediumBox => [
    const BoxShadow(
      color: shadowMedium,
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowLarge => [
    const BoxShadow(
      color: shadowDark,
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];
}


ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    
    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),

    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      hintStyle: const TextStyle(color: AppColors.textHint),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
    ),

    // Text Themes
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textHint,
      ),
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
    ),

    // Checkbox Theme
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.all(AppColors.primary),
      checkColor: MaterialStateProperty.all(Colors.white),
    ),

    // Radio Theme
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.all(AppColors.primary),
    ),

    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primary;
        }
        return Colors.grey;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primary.withValues(alpha: 0.4);
        }
        return Colors.grey.withValues(alpha: 0.3);
      }),
    ),

    // Color Scheme
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      background: AppColors.background,
      surface: AppColors.surface,
      error: AppColors.error,
      errorContainer: AppColors.errorLight,
    ),
  );
}
