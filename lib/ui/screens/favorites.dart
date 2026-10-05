import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/adaptive.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../widgets/common.dart';
import 'detail.dart';
import 'search.dart';

// Favoritos: grid que crece con la pantalla (2 en móvil, hasta 5).
// Se guardan solos gracias a AppState.
class Favorites extends StatelessWidget {
  const Favorites({super.key});

  @override
  Widget build(BuildContext context) {
    final favs = context.watch<AppState>().favs;
    return Scaffold(
      backgroundColor: C.bg,
      // Solo el icono lupa en verde: abre el buscador de personajes.
      appBar: AppBar(
        title: const Text('Favorites', style: T.title),
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
        child: favs.isEmpty
            ? const Nada(
                icon: Icons.favorite_outline,
                title: 'No favorites yet',
                body: 'Tap the heart on any character to save it here.',
              )
            : LayoutBuilder(
                builder: (context, box) {
                  final w = box.maxWidth;
                  final side = D.pad + Rx.side(w, Rx.wide);
                  return GridView.builder(
                    padding: EdgeInsets.fromLTRB(side, 4, side, 24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: Rx.favColumns(w),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: w < 380 ? .68 : .74,
                    ),
                    itemCount: favs.length,
                    itemBuilder: (context, i) => FavCard(c: favs[i]),
                  );
                },
              ),
      ),
    );
  }
}

// Tarjeta del grid. Vive aquí porque solo favoritos la usa.
class FavCard extends StatelessWidget {
  final Character c;
  const FavCard({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final fav = context.select<AppState, bool>((s) => s.isFav(c.id));
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => Detail(character: c)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(D.radius),
          border: Border.all(color: C.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  c.image.isEmpty
                      ? const ColoredBox(
                          color: C.card2,
                          child: Icon(Icons.person_outline, color: C.dim),
                        )
                      : Image.network(
                          c.image,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const ColoredBox(
                            color: C.card2,
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: C.dim,
                            ),
                          ),
                        ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Material(
                        color: Colors.black54,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => context.read<AppState>().toggleFav(c),
                          child: Icon(
                            fav ? Icons.favorite : Icons.favorite_border,
                            color: C.neon,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${c.species} · ${c.origin}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
    );
  }
}
