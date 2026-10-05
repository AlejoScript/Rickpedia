// ─── ChartsHub: menú con las 4 librerías ──────────────────────────
// Para sustentar: cada botón abre 1 pantalla que usa 1 SOLA librería.
// Así el profe ve que son 4 implementaciones distintas.

import 'package:flutter/material.dart';

import '../../core/adaptive.dart';
import '../../core/theme.dart';
import '../charts/chart_d.dart';
import '../charts/chart_fl.dart';
import '../charts/chart_graphic.dart';
import '../charts/chart_sync.dart';

class ChartsHub extends StatelessWidget {
  const ChartsHub({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      ('fl_chart', 'Barras, pastel y líneas.', Icons.bar_chart_outlined),
      ('graphic', 'Gramática de gráficos.', Icons.auto_graph_outlined),
      ('d_chart', 'La más simple.', Icons.pie_chart_outline),
      ('syncfusion', 'Empresarial animada.', Icons.show_chart_outlined),
    ];
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('Gráficas por librería', style: T.title)),
      body: Centered(
        max: Rx.reading,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(D.pad, 12, D.pad, 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final (nombre, desc, icono) = items[i];
            // Material (no Container): la tinta del ListTile necesita
            // un Material ancestor, si no Flutter protesta en debug.
            return Material(
              color: C.card,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(D.radius),
                side: const BorderSide(color: C.line),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: C.card2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icono, color: C.neon),
                ),
                title: Text(nombre, style: T.name),
                subtitle: Text(desc, style: T.caption),
                trailing: const Icon(Icons.arrow_forward_ios, color: C.muted, size: 18),
                onTap: () {
                  Widget page;
                  if (i == 0) {
                    page = const ChartFlScreen();
                  } else if (i == 1) {
                    page = const ChartGraphicScreen();
                  } else if (i == 2) {
                    page = const ChartDScreen();
                  } else {
                    page = const ChartSyncScreen();
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => page),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
