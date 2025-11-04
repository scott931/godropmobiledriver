import 'package:flutter/material.dart';

/// Utility class for generating consistent avatar colors based on letters/initials
class AvatarColorUtils {
  // A vibrant color palette for avatar backgrounds
  static const List<Color> _colorPalette = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Green
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFF84CC16), // Lime
    Color(0xFFF97316), // Orange
    Color(0xFF6366F1), // Indigo
    Color(0xFF14B8A6), // Teal
    Color(0xFFA855F7), // Violet
    Color(0xFFDC2626), // Red variant
    Color(0xFF2563EB), // Blue variant
    Color(0xFF059669), // Green variant
    Color(0xFF7C3AED), // Purple variant
    Color(0xFFBE185D), // Pink variant
    Color(0xFF0D9488), // Teal variant
    Color(0xFFD97706), // Amber variant
    Color(0xFF9333EA), // Violet variant
    Color(0xFF1D4ED8), // Blue dark
    Color(0xFF047857), // Green dark
    Color(0xFFB91C1C), // Red dark
    Color(0xFF7E22CE), // Purple dark
    Color(0xFFBE123C), // Rose
    Color(0xFF0369A1), // Sky blue
  ];

  /// Get a color for a given letter/character
  /// This ensures the same letter always gets the same color
  static Color getColorForLetter(String letter) {
    if (letter.isEmpty) {
      return _colorPalette[0];
    }

    // Get the uppercase first character
    final char = letter.toUpperCase()[0];

    // Convert letter to index (A=0, B=1, etc.)
    final index = char.codeUnitAt(0) - 65; // 'A' is 65 in ASCII

    // If it's not a letter, use a default color
    if (index < 0 || index >= 26) {
      // Use hash code of the character for non-letters
      return _colorPalette[(char.codeUnitAt(0) % _colorPalette.length)];
    }

    // Map letter index to color palette
    return _colorPalette[index % _colorPalette.length];
  }

  /// Get a color for a name (uses first letter)
  static Color getColorForName(String name) {
    if (name.isEmpty) {
      return _colorPalette[0];
    }
    return getColorForLetter(name[0]);
  }

  /// Get initials from a name (first letter of each word, max 2)
  static String getInitials(String name) {
    if (name.isEmpty) return '?';

    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '?';

    if (words.length == 1) {
      return words[0][0].toUpperCase();
    }

    // Return first letter of first two words
    return '${words[0][0].toUpperCase()}${words[1][0].toUpperCase()}';
  }
}

