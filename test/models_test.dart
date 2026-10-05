import 'package:flutter_test/flutter_test.dart';

import 'package:rickpedia_v2/data/api.dart';
import 'package:rickpedia_v2/data/models.dart';

// Un test corto: el JSON real de la API se vuelve modelo,
// y buscar algo inexistente da lista vacía (no error).
void main() {
  test('Character se crea desde el JSON de la API', () {
    final c = Character.fromJson({
      'id': 1,
      'name': 'Rick Sanchez',
      'status': 'Alive',
      'species': 'Human',
      'type': '',
      'gender': 'Male',
      'origin': {'name': 'Earth (C-137)', 'url': ''},
      'location': {'name': 'Citadel of Ricks', 'url': ''},
      'image': 'https://x/1.jpeg',
      'episode': [
        'https://rickandmortyapi.com/api/episode/1',
        'https://rickandmortyapi.com/api/episode/2',
      ],
      'url': '',
    });
    expect(c.name, 'Rick Sanchez');
    expect(c.line, 'Alive · Human');
    expect(c.episodes, [1, 2]);
    // Y se puede guardar y recuperar (favoritos).
    expect(Character.fromJson(c.toJson()).id, 1);
  });

  test('Episode se crea desde el JSON de la API', () {
    final e = Episode.fromJson({
      'id': 1,
      'name': 'Pilot',
      'air_date': 'December 2, 2013',
      'episode': 'S01E01',
      'characters': ['https://rickandmortyapi.com/api/character/1'],
      'url': '',
    });
    expect(e.label, 'S01E01 · Pilot');
    expect(e.season, 'Season 1 · Episode 1');
  });

  test('404 significa vacío, otro fallo explota', () {
    const empty = ApiError.empty();
    expect(empty.isEmpty, isTrue);
    expect(ApiError.offline().isEmpty, isFalse);
  });
}
