import 'package:flutter/material.dart';

import '../../core/theme.dart';

// ─── Piezas con imagen usadas en varias pantallas ───────────────
// Regla: lo que solo se usa UNA vez vive en su pantalla, no aquí.

// Avatar que no se rompe: muestra carga y error.
class Pic extends StatelessWidget {
  final String url;
  final double size;
  const Pic({super.key, required this.url, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: url.isEmpty
            ? const ColoredBox(
                color: C.card2,
                child: Icon(Icons.person_outline, color: C.dim),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (c, w, p) => p == null
                    ? w
                    : const ColoredBox(
                        color: C.card2,
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                errorBuilder: (c, e, s) => const ColoredBox(
                  color: C.card2,
                  child: Icon(Icons.broken_image_outlined, color: C.dim),
                ),
              ),
      ),
    );
  }
}

// Pastilla Alive/Dead/unknown (punto + texto, no solo color).
class Dot extends StatelessWidget {
  final String status;
  const Dot({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final c = s == 'alive'
        ? C.neon
        : s == 'dead'
        ? C.red
        : C.dim;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: C.card2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: C.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class Tag extends StatelessWidget {
  final String text;
  const Tag(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: C.line),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

// Tarjetica Origin / Location del detalle.
class Info extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const Info({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(D.radius),
          border: Border.all(color: C.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: C.neon, size: 20),
            const SizedBox(height: 8),
            Text(title.toUpperCase(), style: T.label),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
