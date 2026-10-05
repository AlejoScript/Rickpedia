import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/adaptive.dart';
import '../../core/theme.dart';
import '../../data/api.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';
import 'detail.dart';

// Buscar: escribe, espera 450ms (Debounce) y pide personajes y
// episodios a la vez. En PC salen en 2 columnas.
// Ya no es tab: se abre con push desde el TopSearch, con BackButton
// para volver. Recibe [initial] por si vienes con texto escrito.
class Search extends StatefulWidget {
  final String initial;
  const Search({super.key, this.initial = ''});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  late final TextEditingController _search;
  late final Debounce _wait;
  List<Character> _chars = [];
  List<Episode> _eps = [];
  bool _loading = false;
  bool _done = false;
  int _req = 0; // ignora respuestas viejas si escribes rápido

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.initial);
    _wait = Debounce();
    // Solo busca solo si vienes con texto; si no, muestra recientes.
    if (widget.initial.trim().isNotEmpty) _go(widget.initial);
  }

  @override
  void dispose() {
    _search.dispose();
    _wait.dispose();
    super.dispose();
  }

  Future<void> _go(String raw) async {
    final q = raw.trim();
    if (q.isEmpty) {
      setState(() {
        _chars = [];
        _eps = [];
        _done = false;
        _loading = false;
      });
      return;
    }
    final id = ++_req;
    setState(() {
      _loading = true;
      _done = true;
    });
    List<Character> chars = [];
    List<Episode> eps = [];
    try {
      final api = context.read<Api>();
      final r = await Future.wait([
        api.searchCharacters(q),
        api.searchEpisodes(q),
      ]);
      chars = r[0] as List<Character>;
      eps = r[1] as List<Episode>;
    } catch (e) {
      debugPrint('search parcial: $e');
    }
    if (!mounted || id != _req) return;
    setState(() {
      _chars = chars;
      _eps = eps;
      _loading = false;
    });
  }

  Future<void> _open(Character c) async {
    await context.read<AppState>().addRecent(c.name);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Detail(character: c)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recent = context.watch<AppState>().recent;
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        titleSpacing: 0,
        title: Finder(
          controller: _search,
          hint: 'Search characters or episodes...',
          onChanged: (v) => _wait(() => _go(v)),
          onSubmit: (v) async {
            await context.read<AppState>().addRecent(v);
            _go(v);
          },
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final wide = Rx.twoCols(box.maxWidth);
            final side = Rx.side(box.maxWidth, wide ? Rx.search : Rx.reading);
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: side),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(D.pad, 8, D.pad, 24),
                children: [
                  const Text('RECENT SEARCHES', style: T.label),
                  const SizedBox(height: 10),
                  if (recent.isEmpty)
                    const Text('No recent searches yet.', style: T.caption)
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final r in recent)
                          RecentChip(
                            text: r,
                            onTap: () {
                              _search.text = r;
                              _go(r);
                            },
                            onX: () => context.read<AppState>().delRecent(r),
                          ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  const Text('Search Results', style: T.name),
                  const SizedBox(height: 10),
                  if (_loading)
                    const SizedBox(height: 120, child: Busy())
                  else if (!_done)
                    // Recién abierta sin buscar: invita a escribir.
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Type above to search characters or episodes.',
                        style: T.body,
                      ),
                    )
                  else if (_done && _chars.isEmpty && _eps.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No results found. Try another name or episode code.',
                        style: T.body,
                      ),
                    )
                  else if (wide)
                    // En PC: personajes a la izquierda, episodios a la derecha.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('CHARACTERS', style: T.label),
                              const SizedBox(height: 8),
                              for (var i = 0; i < _chars.length; i++)
                                _CharTile(
                                  c: _chars[i],
                                  hot: i == 0,
                                  onTap: () => _open(_chars[i]),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('EPISODES', style: T.label),
                              const SizedBox(height: 8),
                              for (final e in _eps) _EpTile(e: e),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    for (var i = 0; i < _chars.length; i++)
                      _CharTile(
                        c: _chars[i],
                        hot: i == 0,
                        onTap: () => _open(_chars[i]),
                      ),
                    for (final e in _eps) _EpTile(e: e),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CharTile extends StatelessWidget {
  final Character c;
  final bool hot;
  final VoidCallback onTap;
  const _CharTile({required this.c, required this.hot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: C.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(D.radius),
          side: BorderSide(color: hot ? C.neon : C.line, width: hot ? 1.5 : 1),
        ),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.all(10),
          leading: Pic(url: c.image, size: 52),
          title: Text(
            c.name,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              const Text('CHARACTER', style: T.label),
              Text('${c.line}\nOrigin: ${c.origin}', style: T.caption),
            ],
          ),
          isThreeLine: true,
        ),
      ),
    );
  }
}

class _EpTile extends StatelessWidget {
  final Episode e;
  const _EpTile({required this.e});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: C.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(D.radius),
          side: const BorderSide(color: C.line),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: C.card2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.movie_outlined, color: C.neon),
          ),
          title: Text(
            e.name,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            'EPISODE\n${e.season}\nAired: ${e.airDate}',
            style: T.caption,
          ),
          isThreeLine: true,
        ),
      ),
    );
  }
}
