import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/adaptive.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';

// ─── Piezas chicas reutilizadas por varias pantallas ────────────

// Espera a que dejes de escribir antes de buscar (no pide 1 por tecla).
class Debounce {
  final Duration wait;
  Timer? _t;
  Debounce({this.wait = const Duration(milliseconds: 450)});
  void call(void Function() fn) {
    _t?.cancel();
    _t = Timer(wait, fn);
  }

  void dispose() => _t?.cancel();
}

class Busy extends StatelessWidget {
  final String? text;
  const Busy({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          if (text != null) ...[
            const SizedBox(height: 12),
            Text(text!, style: const TextStyle(color: C.muted, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

class Oops extends StatelessWidget {
  final String message;
  final VoidCallback retry;
  const Oops({super.key, required this.message, required this.retry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(D.pad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.signal_wifi_off_outlined,
              color: C.muted,
              size: 40,
            ),
            const SizedBox(height: 12),
            const Text('Something went wrong', style: T.name),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: C.muted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: C.neon,
                foregroundColor: Colors.black,
                minimumSize: const Size(0, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Nada extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const Nada({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(D.pad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: C.neon, size: 44),
            const SizedBox(height: 12),
            Text(title, style: T.name),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: C.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class Finder extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmit;
  const Finder({
    super.key,
    required this.controller,
    required this.hint,
    this.autofocus = false,
    this.onChanged,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onSubmitted: onSubmit,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, color: C.muted),
      ),
    );
  }
}

class RecentChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final VoidCallback onX;
  const RecentChip({
    super.key,
    required this.text,
    required this.onTap,
    required this.onX,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: C.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close, size: 16, color: C.muted),
                onPressed: onX,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Barra inferior de 4 tabs (centrada en PC) ──────────────────
// Tabs: Characters, Episodes, Charts y Favorites.
// La lupa ya no es tab: en Characters y Favorites hay un icono lupa
// verde arriba a la derecha que abre Search con push.
class Nav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const Nav({super.key, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.groups_outlined, Icons.groups, 'Characters'),
      (Icons.movie_outlined, Icons.movie, 'Episodes'),
      (Icons.bar_chart_outlined, Icons.bar_chart, 'Charts'),
      (Icons.favorite_outline, Icons.favorite, 'Favorites'),
    ];
    return SafeArea(
      top: false,
      child: Container(
        height: D.navH,
        decoration: const BoxDecoration(
          color: C.bg,
          border: Border(top: BorderSide(color: C.line)),
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final side = Rx.side(box.maxWidth, Rx.phone);
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: side),
              child: Row(
                children: List.generate(items.length, (i) {
                  final on = i == index;
                  final color = on ? C.neon : C.dim;
                  return Expanded(
                    child: InkWell(
                      onTap: () => onTap(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            on ? items[i].$2 : items[i].$1,
                            color: color,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            items[i].$3,
                            style: T.label.copyWith(color: color, fontSize: 10),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: on ? C.neon : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Corazón de favorito con rebotito ───────────────────────────
class Heart extends StatefulWidget {
  final Character c;
  const Heart({super.key, required this.c});

  @override
  State<Heart> createState() => _HeartState();
}

class _HeartState extends State<Heart> with SingleTickerProviderStateMixin {
  late final AnimationController _a;

  @override
  void initState() {
    super.initState();
    _a = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fav = context.select<AppState, bool>((s) => s.isFav(widget.c.id));
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.25).animate(_a),
      child: SizedBox(
        width: 56,
        height: 56,
        child: FloatingActionButton(
          heroTag: 'fav${widget.c.id}',
          backgroundColor: fav ? C.neon : C.card2,
          foregroundColor: fav ? Colors.black : C.neon,
          shape: const CircleBorder(
            side: BorderSide(color: C.neon, width: 1.5),
          ),
          onPressed: () async {
            _a.forward().then((_) => _a.reverse());
            await context.read<AppState>().toggleFav(widget.c);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    fav ? 'Removed from favorites' : 'Added to favorites',
                  ),
                ),
              );
          },
          child: Icon(fav ? Icons.favorite : Icons.favorite_border, size: 26),
        ),
      ),
    );
  }
}
