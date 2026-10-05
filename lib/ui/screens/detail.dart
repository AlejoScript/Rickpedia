import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/adaptive.dart';
import '../../core/theme.dart';
import '../../data/api.dart';
import '../../data/models.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';

// Detalle: foto grande con degradado + datos + episodios donde sale.
// Recibe el Character por constructor (sin rutas con argumentos).
class Detail extends StatefulWidget {
  final Character character;
  const Detail({super.key, required this.character});

  @override
  State<Detail> createState() => _DetailState();
}

class _DetailState extends State<Detail> {
  Future<List<Episode>>? _eps;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pide de una vez los primeros 6 episodios: /episode/1,2,3...
    _eps ??= context.read<Api>().someEpisodes(
      widget.character.episodes.take(6).toList(),
    );
  }

  void _share() {
    final c = widget.character;
    Share.share(
      '${c.name} — ${c.line}. Origin: ${c.origin}. ${c.image}',
      subject: c.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.character;
    return Scaffold(
      backgroundColor: C.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: Rx.compact(context) ? 340 : 420,
            pinned: true,
            backgroundColor: C.bg,
            leading: _Round(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
            actions: [
              _Round(icon: Icons.share_outlined, onTap: _share),
              const SizedBox(width: 12),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (c.image.isNotEmpty)
                    Image.network(
                      c.image,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) =>
                          const ColoredBox(color: C.card2),
                    ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Color(0xCC08080C),
                          C.bg,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Centered(
              max: Rx.reading,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(D.pad, 4, D.pad, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name, style: T.title),
                    const SizedBox(height: 6),
                    const Text(
                      'The smartest man in the universe.',
                      style: T.body,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        Dot(status: c.status),
                        Tag(c.species),
                        Tag(c.gender),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Info(
                          title: 'Origin',
                          value: c.origin,
                          icon: Icons.public_outlined,
                        ),
                        const SizedBox(width: 12),
                        Info(
                          title: 'Location',
                          value: c.location,
                          icon: Icons.location_on_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Featured Episodes', style: T.name),
                    const SizedBox(height: 10),
                    FutureBuilder<List<Episode>>(
                      future: _eps,
                      builder: (context, s) {
                        if (s.connectionState == ConnectionState.waiting) {
                          return const SizedBox(height: 60, child: Busy());
                        }
                        final eps = s.data ?? [];
                        if (eps.isEmpty) {
                          return const Text(
                            'No episodes found.',
                            style: T.caption,
                          );
                        }
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (var i = 0; i < eps.length; i++) ...[
                                EpChip(e: eps[i]),
                                if (i < eps.length - 1)
                                  const SizedBox(width: 8),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Heart(c: c),
    );
  }
}

class _Round extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Round({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 8),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Material(
          color: Colors.black54,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

// Chip "S01E01 · Pilot". Vive aquí porque solo el detalle lo usa.
class EpChip extends StatelessWidget {
  final Episode e;
  const EpChip({super.key, required this.e});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: C.line),
      ),
      child: Text(
        e.label,
        style: const TextStyle(
          fontFamily: 'Geist',
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: Colors.white,
        ),
      ),
    );
  }
}
