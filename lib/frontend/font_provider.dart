/// FontProvider - Font Family Management
/// 
/// ChangeNotifier for managing font selection across the app.
/// Persists font preference to SharedPreferences for retention across sessions.
/// 
/// Provides:
/// - Font family getter/setter (minimalistic/original)
/// - Font name display for UI
/// - Automatic persistence and retrieval of user's font preference
/// - Notification to all listeners when font changes
/// 
/// Font Options:
/// - "minimalistic": Poppins (clean, simple, classic)
/// - "original": Inter (modern, elegant, ultra-light)
/// 
/// Usage: Wrap app with Consumer<FontProvider> to react to font changes.
/// All theme changes are handled based on this provider's selection.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontProvider extends ChangeNotifier {
  String _fontFamily = 'minimalistic'; // Default to Poppins (minimalistic)

  String get fontFamily => _fontFamily;
  
  String get fontDisplayName {
    switch (_fontFamily) {
      case 'minimalistic':
        return 'Minimalistic (Poppins)';
      case 'original':
        return 'Original (Inter)';
      default:
        return 'Minimalistic (Poppins)';
    }
  }

  bool get isMinimalistic => _fontFamily == 'minimalistic';
  bool get isOriginal => _fontFamily == 'original';

  FontProvider() {
    _loadFontFamily();
  }

  Future<void> _loadFontFamily() async {
    final prefs = await SharedPreferences.getInstance();
    final savedFont = prefs.getString('fontFamily') ?? 'minimalistic';
    final loaded = (savedFont == 'minimalistic' || savedFont == 'original')
        ? savedFont
        : 'minimalistic';

    // Only notify if something actually changed — avoids an unnecessary
    // MaterialApp rebuild (and welcome screen animation restart) on cold start.
    if (loaded != _fontFamily) {
      _fontFamily = loaded;
      notifyListeners();
    }
  }

  Future<void> setFontFamily(String family) async {
    if (family != 'minimalistic' && family != 'original') return;
    
    _fontFamily = family;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fontFamily', family);
    notifyListeners();
  }
}
