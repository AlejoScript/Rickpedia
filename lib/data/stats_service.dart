// ─── StatsService: convierte la API en números listos para graficar ───
// la API da personajes/episodios sueltos,
// aquí los CONTAMOS (agregamos) para que las 4 librerías dibujen.
// Solo trae 5 páginas de personajes (~100) + todos los episodios (51)
// para no saturar la API ni congelar el celular.

import 'package:flutter/foundation.dart';

import 'api.dart';
import 'models.dart';

// Un par nombre->cantidad, fácil de graficar en cualquier librería.
class Dato {
  final String nombre;
  final double valor;
  const Dato(this.nombre, this.valor);
}

// Todo lo que las 4 pantallas necesitan. Una sola clase = 1 fuente.
class StatsData {
  final int totalChars;
  final int totalEps;
  final List<Dato> status; // Alive, Dead, unknown
  final List<Dato> species; // top especies
  final List<Dato> gender; // Male, Female, ...
  final List<Dato> origin; // top orígenes
  final List<Dato> location; // top ubicaciones
  final List<Dato> epsPorPersonaje; // buckets: 1, 2-5, 6-10, 11+
  final List<Dato> charsPorEpisodio; // 5 primeros episodios
  final List<Dato> epsPorTemporada; // S01..S05
  final List<Dato> epsPorAnio; // por año de airDate
  final List<Dato> topPersonajesEps; // 6 con más episodios

  const StatsData({
    required this.totalChars,
    required this.totalEps,
    required this.status,
    required this.species,
    required this.gender,
    required this.origin,
    required this.location,
    required this.epsPorPersonaje,
    required this.charsPorEpisodio,
    required this.epsPorTemporada,
    required this.epsPorAnio,
    required this.topPersonajesEps,
  });

  // Vacío mientras carga (evita nulls en las gráficas).
  factory StatsData.vacio() => const StatsData(
    totalChars: 0,
    totalEps: 0,
    status: [],
    species: [],
    gender: [],
    origin: [],
    location: [],
    epsPorPersonaje: [],
    charsPorEpisodio: [],
    epsPorTemporada: [],
    epsPorAnio: [],
    topPersonajesEps: [],
  );
}

class StatsService {
  StatsData? _cache; // 1 sola descarga, las 4 pantallas reusan.

  Future<StatsData> load(Api api) async {
    if (_cache != null) return _cache!;
    final data = await _build(api);
    _cache = data;
    return data;
  }

  void clear() => _cache = null;

  // ─── Paso 1: descargar ───
  Future<StatsData> _build(Api api) async {
    final List<Character> chars = [];
    for (var p = 1; p <= 5; p++) {
      try {
        final r = await api.characters(page: p);
        chars.addAll(r.items);
        if (p >= r.pages) break;
      } catch (e) {
        debugPrint('stats chars p$p: $e');
        break;
      }
    }
    final List<Episode> eps = [];
    try {
      final first = await api.episodes(page: 1);
      eps.addAll(first.items);
      for (var p = 2; p <= first.pages; p++) {
        final r = await api.episodes(page: p);
        eps.addAll(r.items);
      }
    } catch (e) {
      debugPrint('stats eps: $e');
    }
    return _contar(chars, eps);
  }

  // ─── Paso 2: contar ───
  StatsData _contar(List<Character> chars, List<Episode> eps) {
    Map<String, int> cuenta(String Function(Character) f) {
      final m = <String, int>{};
      for (final c in chars) {
        final k = f(c).trim().isEmpty ? '?' : f(c).trim();
        m[k] = (m[k] ?? 0) + 1;
      }
      return m;
    }

    List<Dato> top(Map<String, int> m, [int n = 6]) {
      final e = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return [for (final x in e.take(n)) Dato(x.key, x.value.toDouble())];
    }

    final status = cuenta((c) => c.status);
    final species = cuenta((c) => c.species);
    final gender = cuenta((c) => c.gender);
    final origin = cuenta((c) => c.origin);
    final location = cuenta((c) => c.location);

    // Buckets de episodios por personaje.
    var b1 = 0, b25 = 0, b610 = 0, b11 = 0;
    for (final c in chars) {
      final n = c.episodes.length;
      if (n <= 1) {
        b1++;
      } else if (n <= 5) {
        b25++;
      } else if (n <= 10) {
        b610++;
      } else {
        b11++;
      }
    }

    // Temporadas S01.. desde el código "S01E02".
    final seasons = <String, int>{};
    for (final e in eps) {
      final m = RegExp(
        r'^S(\d+)E\d+$',
        caseSensitive: false,
      ).firstMatch(e.code);
      final k = m == null ? '?' : 'S${m[1]}';
      seasons[k] = (seasons[k] ?? 0) + 1;
    }

    // Años desde "December 2, 2013".
    final years = <String, int>{};
    for (final e in eps) {
      final m = RegExp(r'(\d{4})').firstMatch(e.airDate);
      final k = m == null ? '?' : m[1]!;
      years[k] = (years[k] ?? 0) + 1;
    }

    final tops = [...chars]
      ..sort((a, b) => b.episodes.length.compareTo(a.episodes.length));

    return StatsData(
      totalChars: chars.length,
      totalEps: eps.length,
      status: top(status, 3),
      species: top(species, 6),
      gender: top(gender, 4),
      origin: top(origin, 6),
      location: top(location, 6),
      epsPorPersonaje: [
        Dato('1 ep', b1.toDouble()),
        Dato('2-5', b25.toDouble()),
        Dato('6-10', b610.toDouble()),
        Dato('11+', b11.toDouble()),
      ],
      charsPorEpisodio: [
        for (final e in eps.take(6))
          Dato(
            e.code.isEmpty ? '#${e.id}' : e.code,
            e.characters.length.toDouble(),
          ),
      ],
      epsPorTemporada: top(seasons, 6),
      epsPorAnio: top(years, 6),
      topPersonajesEps: [
        for (final c in tops.take(6))
          Dato(
            c.name.length > 10 ? '${c.name.substring(0, 10)}…' : c.name,
            c.episodes.length.toDouble(),
          ),
      ],
    );
  }
}
