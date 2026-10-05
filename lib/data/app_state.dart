import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

// ─── La memoria de la app: favoritos + recientes en UNA clase ───
// Es un ChangeNotifier: avisa a la UI cuando algo cambia y todas
// las pantallas se actualizan solas. Se guarda en el teléfono,
// así que sobrevive al cerrar la app.
class AppState extends ChangeNotifier {
  final Map<int, Character> _favs = {};
  final List<String> _recent = [];
  SharedPreferences? _prefs;

  List<Character> get favs =>
      _favs.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  List<String> get recent => List.unmodifiable(_recent);

  bool isFav(int id) => _favs.containsKey(id);

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    // Favoritos guardados como JSON.
    try {
      final raw = _prefs!.getString('favs');
      if (raw != null) {
        for (final j in (jsonDecode(raw) as List).whereType<Map>()) {
          final c = Character.fromJson(Map<String, dynamic>.from(j));
          _favs[c.id] = c;
        }
      }
    } catch (e) {
      debugPrint('favs corruptos: $e');
    }
    // Recientes: máximo 10.
    _recent
      ..clear()
      ..addAll((_prefs!.getStringList('recent') ?? const []).take(10));
    notifyListeners();
  }

  Future<void> toggleFav(Character c) async {
    _favs.containsKey(c.id) ? _favs.remove(c.id) : _favs[c.id] = c;
    notifyListeners();
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(
      'favs',
      jsonEncode([for (final f in _favs.values) f.toJson()]),
    );
  }

  Future<void> addRecent(String q) async {
    q = q.trim();
    if (q.isEmpty) return;
    _recent.removeWhere((e) => e.toLowerCase() == q.toLowerCase());
    _recent.insert(0, q);
    if (_recent.length > 10) _recent.removeLast();
    notifyListeners();
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setStringList('recent', _recent);
  }

  Future<void> delRecent(String q) async {
    _recent.removeWhere((e) => e.toLowerCase() == q.toLowerCase());
    notifyListeners();
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setStringList('recent', _recent);
  }
}
