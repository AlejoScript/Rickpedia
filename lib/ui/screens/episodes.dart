import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/adaptive.dart';
import '../../core/theme.dart';
import '../../data/api.dart';
import '../../data/models.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';

// Episodios: buscador + lista que se expande + paginación infinita.
// El primero arranca abierto.
class Episodes extends StatefulWidget {
  const Episodes({super.key});

  @override
  State<Episodes> createState() => _EpisodesState();
}

class _EpisodesState extends State<Episodes>
    with AutomaticKeepAliveClientMixin {
  // KeepAlive: conserva episodios y scroll al deslizar entre tabs.
  @override
  bool get wantKeepAlive => true;

  final _search = TextEditingController();
  final _scroll = ScrollController();
  late final Debounce _wait;
  List<Episode> _items = [];
  int _page = 1;
  int _max = 1;
  int? _open;
  bool _loading = true;
  bool _more = false;
  Object? _error;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _wait = Debounce();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
        _next();
      }
    });
    _first();
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    _wait.dispose();
    super.dispose();
  }

  Future<void> _first() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<Api>();
      final r = _q.isEmpty
          ? await api.episodes(page: 1)
          : (items: await api.searchEpisodes(_q), pages: 1);
      if (!mounted) return;
      setState(() {
        _items = r.items;
        _page = 1;
        _max = r.pages;
        _open = r.items.isNotEmpty ? r.items.first.id : null;
        _loading = false;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _next() async {
    if (_loading || _more || _page >= _max || _q.isNotEmpty) return;
    setState(() => _more = true);
    try {
      final r = await context.read<Api>().episodes(page: _page + 1);
      if (!mounted) return;
      setState(() {
        _page++;
        _items = [..._items, ...r.items];
        _more = false;
      });
    } catch (_) {
      if (mounted) setState(() => _more = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // exigido por el KeepAlive
    return Scaffold(
      backgroundColor: C.bg,
      // Solo el Finder de episodios (sin mic). El buscador global de
      // personajes ya no vive aquí para no confundir.
      appBar: AppBar(title: const Text('Episodes', style: T.title)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            // Centrado por padding para no romper el Expanded de abajo.
            final side = Rx.side(box.maxWidth, Rx.reading);
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: side),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(D.pad, 4, D.pad, 12),
                    child: Finder(
                      controller: _search,
                      hint: 'Search episode name or code...',
                      onChanged: (v) => _wait(() {
                        _q = v.trim();
                        _first();
                      }),
                      onSubmit: (v) {
                        _q = v.trim();
                        _first();
                      },
                    ),
                  ),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (_loading) {
                          return const Busy(text: 'Loading episodes...');
                        }
                        if (_error is ApiError && _items.isEmpty) {
                          return Oops(
                            message: (_error! as ApiError).message,
                            retry: _first,
                          );
                        }
                        if (_items.isEmpty) {
                          return const Nada(
                            icon: Icons.movie_outlined,
                            title: 'No results found',
                            body: 'Try another name or episode code.',
                          );
                        }
                        return ListView.separated(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(
                            D.pad,
                            0,
                            D.pad,
                            24,
                          ),
                          itemCount: _items.length + (_more ? 1 : 0),
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            if (i >= _items.length) {
                              return const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }
                            final e = _items[i];
                            return EpCard(
                              e: e,
                              open: _open == e.id,
                              onTap: () => setState(
                                () => _open = _open == e.id ? null : e.id,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// Avatares encimados + "+9". Vive aquí porque solo EpCard lo usa.
class Faces extends StatelessWidget {
  final List<String> urls;
  final int total;
  const Faces({super.key, required this.urls, required this.total});

  @override
  Widget build(BuildContext context) {
    final show = urls.take(5).toList();
    final extra = total - show.length;
    return SizedBox(
      height: 36,
      child: Stack(
        children: [
          for (var i = 0; i < show.length; i++)
            Positioned(
              left: i * 26.0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: C.bg, width: 2),
                ),
                child: Pic(url: show[i], size: 34),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: show.length * 26.0,
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: C.card2,
                  shape: BoxShape.circle,
                  border: Border.all(color: C.bg, width: 2),
                ),
                child: Text(
                  '+$extra',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Episodio que se expande al tocarlo. Solo esta pantalla lo usa.
class EpCard extends StatefulWidget {
  final Episode e;
  final bool open;
  final VoidCallback onTap;
  const EpCard({
    super.key,
    required this.e,
    required this.open,
    required this.onTap,
  });

  @override
  State<EpCard> createState() => _EpCardState();
}

class _EpCardState extends State<EpCard> {
  Future<List<String>>? _faces;

  // Solo cuando se abre: trae las fotos de los primeros 6 personajes.
  void _load() {
    final ids = widget.e.characters.take(6).toList();
    _faces = context
        .read<Api>()
        .someCharacters(ids)
        .then((cs) => cs.map((c) => c.image).toList())
        .catchError((Object e) => <String>[]);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.open && _faces == null) _load();
    final e = widget.e;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(D.radius),
        border: Border.all(
          color: widget.open ? C.neon : C.line,
          width: widget.open ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(D.radius),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.code,
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 1.1,
                            color: C.neon,
                          ),
                        ),
                        Text(e.name, style: T.name.copyWith(fontSize: 17)),
                        Text(e.airDate, style: T.caption),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: widget.open ? .5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: C.muted,
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                child: !widget.open
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Text(
                            'Appearing Characters (${e.characters.length})',
                            style: T.caption,
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder<List<String>>(
                            future: _faces,
                            builder: (context, s) {
                              if (!s.hasData) {
                                return const SizedBox(
                                  height: 36,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return Faces(
                                urls: s.data!,
                                total: e.characters.length,
                              );
                            },
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
