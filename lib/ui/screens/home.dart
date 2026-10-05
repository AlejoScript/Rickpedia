import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/adaptive.dart';
import '../../core/theme.dart';
import '../../data/api.dart';
import '../../data/models.dart';
import '../widgets/common.dart';
import 'detail.dart';
import 'search.dart';

// Home: logo + carrusel que se desliza + tarjeta de descripción.
// Los datos vienen de la API con paginación (20 por página).
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with AutomaticKeepAliveClientMixin {
  // KeepAlive: el PageView del Shell destruye tabs lejanos al deslizar;
  // con esto Home conserva sus datos y no recarga la API al volver.
  @override
  bool get wantKeepAlive => true;

  late final PageController _pages;
  List<Character> _items = [];
  int _sel = 0;
  int _page = 1;
  int _max = 1;
  bool _loading = true;
  bool _more = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _pages = PageController(viewportFraction: .62);
    _first();
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _first() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await context.read<Api>().characters(page: 1);
      if (!mounted) return;
      setState(() {
        _items = r.items;
        _page = 1;
        _max = r.pages;
        _loading = false;
      });
      final rick = _items.indexWhere((c) => c.id == 1);
      if (rick > 0) {
        setState(() => _sel = rick);
        _pages.jumpToPage(rick);
      }
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _next() async {
    if (_more || _page >= _max) return;
    setState(() => _more = true);
    try {
      final r = await context.read<Api>().characters(page: _page + 1);
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
      // Solo el icono lupa en verde: abre el buscador de personajes.
      appBar: AppBar(
        title: const Text('Rickpedia', style: T.appBar),
        actions: [
          IconButton(
            tooltip: 'Search characters',
            icon: const Icon(Icons.search, color: C.neon),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Search()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (_loading) return const Busy(text: 'Loading multiverse...');
            if (_error is ApiError && _items.isEmpty) {
              return Oops(
                message: (_error! as ApiError).message,
                retry: _first,
              );
            }
            final c = _items[_sel.clamp(0, _items.length - 1)];
            return LayoutBuilder(
              builder: (context, box) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: box.maxHeight),
                    child: Centered(
                      max: Rx.phone,
                      child: Column(
                        children: [
                          Carousel(
                            items: _items,
                            selected: _sel,
                            controller: _pages,
                            onMove: (i) {
                              setState(() => _sel = i);
                              if (i >= _items.length - 4) _next();
                            },
                          ),
                          if (_more)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: D.pad,
                            ),
                            child: _Description(c: c),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// Tarjeta con los datos del personaje seleccionado.
// Tocar abre el detalle.
class _Description extends StatelessWidget {
  final Character c;
  const _Description({required this.c});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Gender', c.gender),
      ('Origin', c.origin),
      ('Location', c.location),
      (
        'Episodes',
        c.episodes.length == 1
            ? '1 Appearance'
            : '${c.episodes.length} Appearances',
      ),
    ];
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => Detail(character: c)),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(D.bigRadius),
          border: Border.all(color: C.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Description', style: T.name),
            const SizedBox(height: 12),
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    SizedBox(
                      width: 84,
                      child: Text(
                        r.$1,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 13,
                          color: C.muted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        r.$2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── El carrusel: PageView con la tarjeta central destacada ─────
// Vive aquí porque solo el home lo usa.
class Carousel extends StatelessWidget {
  final List<Character> items;
  final int selected;
  final PageController controller;
  final ValueChanged<int> onMove;
  const Carousel({
    super.key,
    required this.items,
    required this.selected,
    required this.controller,
    required this.onMove,
  });

  void _open(BuildContext context, Character c) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Detail(character: c)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 340,
      child: PageView.builder(
        controller: controller,
        onPageChanged: onMove,
        itemCount: items.length,
        itemBuilder: (context, i) {
          final c = items[i];
          final center = i == selected;
          return AnimatedScale(
            scale: center ? 1 : .82,
            duration: const Duration(milliseconds: 250),
            child: AnimatedOpacity(
              opacity: center ? 1 : .65,
              duration: const Duration(milliseconds: 250),
              child: GestureDetector(
                onTap: () => _open(context, c),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: C.card,
                    borderRadius: BorderRadius.circular(D.bigRadius),
                    border: Border.all(
                      color: center ? C.neon : C.line,
                      width: center ? 2 : 1,
                    ),
                    boxShadow: center
                        ? [
                            BoxShadow(
                              color: C.neon.withValues(alpha: .25),
                              blurRadius: 24,
                            ),
                          ]
                        : null,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: c.image.isEmpty
                            ? const ColoredBox(
                                color: C.card2,
                                child: Icon(
                                  Icons.person_outline,
                                  color: C.dim,
                                  size: 48,
                                ),
                              )
                            : Image.network(
                                c.image,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const ColoredBox(
                                  color: C.card2,
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: C.dim,
                                    size: 48,
                                  ),
                                ),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Text(
                              c.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              c.line,
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 12,
                                color: C.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
