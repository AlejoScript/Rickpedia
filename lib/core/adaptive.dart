import 'package:flutter/widgets.dart';

// ─── Reglas responsive en un solo lugar ─────────────────────────
// Todo lo de PC solo se activa desde 600px; en móvil no cambia nada.
class Rx {
  static const breakpoint = 600.0;
  static const phone = 520.0; // columna tipo teléfono (home, nav)
  static const reading = 680.0; // listas (episodios, búsqueda, detalle)
  static const search = 920.0; // búsqueda con 2 columnas
  static const wide = 1100.0; // grid de favoritos

  static bool compact(BuildContext c) => MediaQuery.widthOf(c) < breakpoint;

  static int favColumns(double w) {
    if (w < breakpoint) return 2;
    if (w < 900) return 3;
    if (w < 1200) return 4;
    return 5;
  }

  static bool twoCols(double w) => w >= 900;

  // Padding lateral para centrar scrollables (un Align les quitaría
  // la altura y rompería Expanded/Listas). En móvil da 0.
  static double side(double w, double max) => w <= max ? 0 : (w - max) / 2;
}

// ─── Centra el contenido con tope de ancho (solo PC) ────────────
class Centered extends StatelessWidget {
  final Widget child;
  final double max;
  const Centered({super.key, required this.child, required this.max});

  @override
  Widget build(BuildContext context) {
    if (Rx.compact(context)) return child; // móvil: intacto
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: max),
        child: child,
      ),
    );
  }
}
