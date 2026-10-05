// ─── ChartViewer: la cajita que muestra 1 gráfica y deja cambiarla ───
// Para sustentar: recibe una LISTA de títulos + LISTA de dibujos.
// El Dropdown y los botones solo cambian el ÍNDICE, el dibujo cambia solo.
// Se usa 2 veces por pantalla: una para básicas y otra para avanzadas.

import 'package:flutter/material.dart';

import '../../core/theme.dart';

class ChartViewer extends StatelessWidget {
  final String etiqueta; // "BÁSICA" o "AVANZADA"
  final List<String> titulos; // nombres de cada gráfica
  final List<String> descripciones; // explicaciones en español
  final List<Widget> hijos; // dibujos
  final int indice; // cuál se ve ahora
  final ValueChanged<int> onChanged; // avisa a la pantalla

  const ChartViewer({
    super.key,
    required this.etiqueta,
    required this.titulos,
    required this.descripciones,
    required this.hijos,
    required this.indice,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final i = indice.clamp(0, hijos.length - 1);
    return Container(
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(D.radius),
        border: Border.all(color: C.line),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila: etiqueta + contador de posición.
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: etiqueta == 'BÁSICA' ? C.neon : C.card2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: C.line),
                ),
                child: Text(
                  etiqueta,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: etiqueta == 'BÁSICA' ? Colors.black : Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Text('${i + 1}/${hijos.length}', style: T.caption),
            ],
          ),
          const SizedBox(height: 8),
          Text(titulos[i], style: T.name.copyWith(fontSize: 16)),
          const SizedBox(height: 4),
          // Explicación en español: qué está mostrando esta gráfica.
          Text(descripciones[i], style: T.caption),
          const SizedBox(height: 10),
          // El dibujo (altura fija para que no salte).
          SizedBox(height: 260, child: hijos[i]),
          const SizedBox(height: 10),
          // Botones anterior / siguiente.
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: i > 0 ? () => onChanged(i - 1) : null,
                  child: const Text('◀ Anterior'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: C.neon,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: i < hijos.length - 1
                      ? () => onChanged(i + 1)
                      : null,
                  child: const Text('Siguiente ▶'),
                ),
              ),
            ],
          ),
          // Dropdown con todos los nombres (para saltar directo).
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            // isExpanded: el botón ocupa todo el ancho y el texto largo
            // se corta con "..." en vez de salirse de la pantalla
            // (franja amarilla "overflowed") en el móvil.
            isExpanded: true,
            // ignore: deprecated_member_use
            value: i,
            dropdownColor: C.card2,
            decoration: const InputDecoration(
              labelText: 'Saltar a...',
              labelStyle: TextStyle(color: C.muted, fontSize: 12),
            ),
            items: [
              for (var k = 0; k < titulos.length; k++)
                DropdownMenuItem(
                  value: k,
                  child: Text(
                    '${k + 1}. ${titulos[k]}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ),
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}
