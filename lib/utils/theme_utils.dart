import 'package:flutter/material.dart';

/// Helper class for consistent theme styling across the app
class ThemeUtils {
  // Common colors
  static const themeColor = Color.fromARGB(255, 40, 108, 100);
  static const secondaryColor = Color(0xFFFF5722);

  // Animation durations
  static const animationDuration = Duration(milliseconds: 300);
  static const animationDurationFast = Duration(milliseconds: 150);

  // Border radius values
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusMedium = 12.0;

  /// Get the appropriate background color based on dark mode
  static Color backgroundColor(bool isDarkMode) {
    return isDarkMode ? Colors.grey[900]! : Colors.grey[50]!;
  }

  /// Get the appropriate card color based on dark mode
  static Color cardColor(bool isDarkMode) {
    return isDarkMode ? Colors.grey[850]! : Colors.white;
  }

  /// Get the appropriate text color based on dark mode
  static Color textColor(bool isDarkMode) {
    return isDarkMode ? Colors.white : Colors.black87;
  }

  /// Get the appropriate secondary text color based on dark mode
  static Color secondaryTextColor(bool isDarkMode) {
    return isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
  }

  /// Get the appropriate background color for input fields based on dark mode
  static Color inputBackgroundColor(bool isDarkMode) {
    return isDarkMode ? Colors.grey[800]! : Colors.grey[100]!;
  }

  /// Get input decoration for form fields with dark mode support
  static InputDecoration inputDecoration({
    required bool isDarkMode,
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(12)),
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: borderRadius),
      filled: isDarkMode,
      fillColor: isDarkMode ? Colors.grey[800] : null,
      labelStyle: TextStyle(
        color: isDarkMode ? Colors.grey[300] : null,
      ),
      hintStyle: TextStyle(
        color: isDarkMode ? Colors.grey[500] : null,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(
          color: themeColor,
        ),
      ),
    );
  }

  /// Get appropriate icon color based on dark mode
  static Color iconColor(bool isDarkMode) {
    return isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
  }

  /// Get app bar theme based on dark mode
  static AppBarTheme appBarTheme(bool isDarkMode) {
    return AppBarTheme(
      backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      titleTextStyle: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black87,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Get decoration for cards with consistent styling
  static BoxDecoration cardDecoration(bool isDarkMode) {
    return BoxDecoration(
      color: cardColor(isDarkMode),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: isDarkMode
              ? Colors.black.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  /// Get button style for primary buttons
  static ButtonStyle primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: themeColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  /// Get button style for secondary buttons based on dark mode
  static ButtonStyle secondaryButtonStyle(bool isDarkMode) {
    return ElevatedButton.styleFrom(
      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
      foregroundColor: isDarkMode ? Colors.white : Colors.black87,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
