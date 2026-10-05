// ─── Modelos: así se ve el JSON convertido a Dart ────────────────
// Cada clase sabe crearse desde JSON (fromJson) y volverse JSON
// (toJson, para guardar favoritos en el teléfono).

class Character {
  final int id;
  final String name;
  final String status; // Alive | Dead | unknown
  final String species;
  final String gender;
  final String origin; // solo el nombre, lo demás sobra
  final String location;
  final String image;
  final List<int> episodes; // ids de episodios donde sale

  const Character({
    required this.id,
    required this.name,
    required this.status,
    required this.species,
    required this.gender,
    required this.origin,
    required this.location,
    required this.image,
    required this.episodes,
  });

  factory Character.fromJson(Map<String, dynamic> j) {
    int idFrom(String url) => int.tryParse(url.split('/').last) ?? 0;
    return Character(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: (j['name'] as String?) ?? '?',
      status: (j['status'] as String?) ?? 'unknown',
      species: (j['species'] as String?) ?? '?',
      gender: (j['gender'] as String?) ?? '?',
      origin: (j['origin']?['name'] as String?) ?? '?',
      location: (j['location']?['name'] as String?) ?? '?',
      image: (j['image'] as String?) ?? '',
      episodes: ((j['episode'] as List?) ?? const [])
          .whereType<String>()
          .map(idFrom)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'status': status,
    'species': species,
    'type': '',
    'gender': gender,
    'origin': {'name': origin, 'url': ''},
    'location': {'name': location, 'url': ''},
    'image': image,
    'episode': [for (final e in episodes) 'https://x/$e'],
    'url': '',
  };

  String get line => '$status · $species'; // "Alive · Human"
}

class Episode {
  final int id;
  final String name;
  final String airDate;
  final String code; // S01E01
  final List<int> characters; // ids de personajes que salen

  const Episode({
    required this.id,
    required this.name,
    required this.airDate,
    required this.code,
    required this.characters,
  });

  factory Episode.fromJson(Map<String, dynamic> j) {
    return Episode(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: (j['name'] as String?) ?? '?',
      airDate: (j['air_date'] as String?) ?? '?',
      code: (j['episode'] as String?) ?? '',
      characters: ((j['characters'] as List?) ?? const [])
          .whereType<String>()
          .map((u) => int.tryParse(u.split('/').last) ?? 0)
          .where((e) => e > 0)
          .toList(),
    );
  }

  String get label => '$code · $name'; // "S01E01 · Pilot"

  // "S02E02" -> "Season 2 · Episode 2"
  String get season {
    final m = RegExp(r'^S(\d+)E(\d+)$', caseSensitive: false).firstMatch(code);
    return m == null
        ? code
        : 'Season ${int.parse(m[1]!)} · Episode ${int.parse(m[2]!)}';
  }
}
