import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'models.dart';

// ─── Errores con mensaje listo para mostrar ─────────────────────
// empty  = la búsqueda no dio nada (no es un fallo, es "vacío")
// offline = sin internet o tardó demasiado
// server = la API falló
class ApiError implements Exception {
  final String message;
  final bool isEmpty;
  const ApiError(this.message, {this.isEmpty = false});
  const ApiError.empty() : this('No results found.', isEmpty: true);
  const ApiError.offline()
    : this('No internet connection. Check your network and try again.');
  const ApiError.server() : this('Server error. Please try again later.');
}

// ─── El cartero de la app: toda la red pasa por aquí ────────────
// Devuelve (items, pages): la lista y cuántas páginas hay en total.
class Api {
  static const base = 'https://rickandmortyapi.com/api';
  final http.Client _http;
  Api({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  // GET genérico con timeout y errores traducidos.
  Future<dynamic> _get(String path, [Map<String, String>? q]) async {
    final url = Uri.parse('$base$path').replace(queryParameters: q);
    try {
      final r = await _http.get(url).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) return jsonDecode(r.body);
      if (r.statusCode == 404) throw const ApiError.empty();
      throw const ApiError.server();
    } on ApiError {
      rethrow;
    } on SocketException {
      throw const ApiError.offline();
    } on TimeoutException {
      throw const ApiError.offline();
    } catch (_) {
      throw const ApiError.server();
    }
  }

  // La API pagina de 20 en 20: info.pages dice cuántas hay.
  Future<({List<Character> items, int pages})> characters({
    int page = 1,
  }) async {
    final j =
        await _get('/character', {'page': '$page'}) as Map<String, dynamic>;
    return (
      items: ((j['results'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Character.fromJson)
          .toList(),
      pages: (j['info']?['pages'] as num?)?.toInt() ?? 1,
    );
  }

  Future<({List<Episode> items, int pages})> episodes({int page = 1}) async {
    final j = await _get('/episode', {'page': '$page'}) as Map<String, dynamic>;
    return (
      items: ((j['results'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Episode.fromJson)
          .toList(),
      pages: (j['info']?['pages'] as num?)?.toInt() ?? 1,
    );
  }

  // Varios por id en una sola petición: /character/1,2,3
  Future<List<Character>> someCharacters(List<int> ids) async {
    if (ids.isEmpty) return [];
    final j = await _get('/character/${ids.join(',')}');
    if (j is List) {
      return j
          .whereType<Map<String, dynamic>>()
          .map(Character.fromJson)
          .toList();
    }
    return [Character.fromJson(j as Map<String, dynamic>)];
  }

  Future<List<Episode>> someEpisodes(List<int> ids) async {
    if (ids.isEmpty) return [];
    final j = await _get('/episode/${ids.join(',')}');
    if (j is List) {
      return j.whereType<Map<String, dynamic>>().map(Episode.fromJson).toList();
    }
    return [Episode.fromJson(j as Map<String, dynamic>)];
  }

  // Buscar personajes por nombre (404 = lista vacía, no error).
  Future<List<Character>> searchCharacters(String name) async {
    try {
      final j = await _get('/character', {'name': name, 'page': '1'});
      return ((j['results'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Character.fromJson)
          .take(5)
          .toList();
    } on ApiError catch (e) {
      if (e.isEmpty) return [];
      rethrow;
    }
  }

  // Buscar episodios por nombre o código (S01E02).
  Future<List<Episode>> searchEpisodes(String q) async {
    final isCode = RegExp(
      r'^s\d{1,2}e\d{1,2}$',
      caseSensitive: false,
    ).hasMatch(q.trim());
    try {
      final j = await _get(
        '/episode',
        isCode ? {'episode': q.trim()} : {'name': q.trim()},
      );
      return ((j['results'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Episode.fromJson)
          .take(5)
          .toList();
    } on ApiError catch (e) {
      if (e.isEmpty) return [];
      rethrow;
    }
  }

  void close() => _http.close();
}
