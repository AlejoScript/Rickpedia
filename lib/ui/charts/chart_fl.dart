// ─── Pantalla 1/4: fl_chart ───────────────────────────────────────
// SOLO importa fl_chart. Seis familias: barras, líneas, pastel, radar,
// dispersión y combinaciones multi-serie.
// BÁSICAS = una variante visual por slot, sin toque ni degradados.
// AVANZADAS = touch/tooltip, degradados, multi-serie, apiladas,
// líneas extra, error bars y zoom. Ninguna repite estructura ni
// presentación con otra dentro de esta pantalla.

import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/adaptive.dart';
import '../../core/theme.dart';
import '../../data/api.dart';
import '../../data/stats_service.dart';
import '../widgets/chart_viewer.dart';
import '../widgets/common.dart';

class ChartFlScreen extends StatefulWidget {
  const ChartFlScreen({super.key});
  @override
  State<ChartFlScreen> createState() => _ChartFlScreenState();
}

class _ChartFlScreenState extends State<ChartFlScreen> {
  Future<StatsData>? _fut;
  int _basic = 0;
  int _adv = 0;
  final _svc = StatsService();
  int? _tocada; // sección del pastel tocada (A23)
  int? _radarTocada; // vértice del radar tocado (A26)

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fut ??= _svc.load(context.read<Api>());
  }

  // Paleta fija para que todas se vean igual.
  static const _cols = [
    Color(0xFF39FF14),
    Color(0xFF22D3EE),
    Color(0xFFFBBF24),
    Color(0xFFF472B6),
    Color(0xFFA78BFA),
    Color(0xFFFF6B6B),
  ];
  Color _c(int i) => _cols[i % _cols.length];

  // ─── Helpers sobre los MISMOS datos de StatsData ───
  double _maxV(List<Dato> ds) {
    var m = 0.0;
    for (final d in ds) {
      if (d.valor > m) m = d.valor;
    }
    return m;
  }

  double _prom(List<Dato> ds) {
    if (ds.isEmpty) return 0;
    var s = 0.0;
    for (final d in ds) {
      s += d.valor;
    }
    return s / ds.length;
  }

  // Años ordenados cronológicamente (epsPorAnio viene ordenado por cantidad).
  List<Dato> _anios(StatsData d) {
    final l = [...d.epsPorAnio]..sort((a, b) => a.nombre.compareTo(b.nombre));
    return l;
  }

  // Acumulado de una serie: suma corrida.
  List<Dato> _acum(List<Dato> ds) {
    var s = 0.0;
    return [for (final d in ds) Dato(d.nombre, s += d.valor)];
  }

  // Serie constante = promedio, para comparar contra los valores.
  List<Dato> _constante(List<Dato> ds, double v) => [
    for (final d in ds) Dato(d.nombre, v),
  ];

  List<FlSpot> _spots(List<Dato> ds) => [
    for (var i = 0; i < ds.length; i++) FlSpot(i.toDouble(), ds[i].valor),
  ];

  Widget _vacio(IconData i) =>
      Nada(icon: i, title: 'Sin datos', body: 'Reintenta.');

  // ══════════════════════ PRIMITIVAS BÁSICAS ══════════════════════

  // B01 · barras redondeadas con guía punteada por defecto.
  Widget _bRedondas(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return BarChart(
      BarChartData(
        maxY: _maxV(ds) * 1.2,
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        barGroups: [
          for (var i = 0; i < ds.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: ds[i].valor,
                  color: _c(i),
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // B02 · solo las barras: sin cuadrícula, sin títulos, sin borde.
  Widget _bMinimal(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return BarChart(
      BarChartData(
        maxY: _maxV(ds) * 1.15,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        barGroups: [
          for (var i = 0; i < ds.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(toY: ds[i].valor, color: _c(i), width: 24),
              ],
            ),
        ],
      ),
    );
  }

  // B03 · histograma: barras contiguas, sin separación ni esquinas.
  Widget _bHistograma(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return BarChart(
      BarChartData(
        maxY: _maxV(ds) * 1.15,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        alignment: BarChartAlignment.center,
        groupsSpace: 0,
        barGroups: [
          for (var i = 0; i < ds.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(toY: ds[i].valor, color: _c(i), width: 44),
              ],
            ),
        ],
      ),
    );
  }

  // B04 · horizontales: todo el gráfico girado 90°.
  Widget _bHorizontal(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return BarChart(
      BarChartData(
        maxY: _maxV(ds) * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        rotationQuarterTurns: 1,
        barGroups: [
          for (var i = 0; i < ds.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: ds[i].valor,
                  color: _c(i),
                  width: 16,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // B05 · pista de fondo que marca el máximo posible.
  Widget _bPista(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    final top = _maxV(ds) * 1.2;
    return BarChart(
      BarChartData(
        maxY: top,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        barGroups: [
          for (var i = 0; i < ds.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: ds[i].valor,
                  color: _c(i),
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: top,
                    color: C.line,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // B06 · divergentes: cada valor menos el promedio.
  Widget _bDivergentes(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    final p = _prom(ds);
    var a = 0.0;
    final diffs = [
      for (final d in ds)
        (d.valor - p).also((v) => a = max(a, v.abs())),
    ];
    return BarChart(
      BarChartData(
        minY: -a * 1.2,
        maxY: a * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        barGroups: [
          for (var i = 0; i < ds.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  fromY: diffs[i] >= 0 ? 0 : diffs[i],
                  toY: diffs[i] >= 0 ? diffs[i] : 0,
                  color: diffs[i] >= 0 ? C.neon : C.red,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // B07 · etiqueta de valor sobre cada punta.
  Widget _bEtiqueta(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return BarChart(
      BarChartData(
        maxY: _maxV(ds) * 1.35,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        barGroups: [
          for (var i = 0; i < ds.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: ds[i].valor,
                  color: _c(i),
                  width: 20,
                  borderRadius: BorderRadius.circular(6),
                  label: BarChartRodLabel(
                    show: true,
                    text: ds[i].valor.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    offset: const Offset(0, 14),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // B08 · contorno discontinuo en cada barra.
  Widget _bBordePunteado(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return BarChart(
      BarChartData(
        maxY: _maxV(ds) * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        barGroups: [
          for (var i = 0; i < ds.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: ds[i].valor,
                  color: C.card2,
                  width: 22,
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: C.neon, width: 1.5),
                  borderDashArray: [5, 4],
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ── Líneas (B09–B17) ──
  Widget _lineaBase(
    List<Dato> ds, {
    bool curved = false,
    List<int>? dash,
    bool step = false,
    bool area = false,
    bool dotsCircle = false,
    bool dotsSquare = false,
    bool dotsCross = false,
    bool thick = false,
  }) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _spots(ds),
            isCurved: curved,
            isStepLineChart: step,
            color: C.neon,
            barWidth: thick ? 6 : 3,
            isStrokeCapRound: thick,
            shadow: thick
                ? Shadow(color: C.neon.withValues(alpha: .5), blurRadius: 8)
                : const Shadow(color: Colors.transparent),
            dashArray: dash,
            belowBarData: BarAreaData(
              show: area,
              color: C.neon.withValues(alpha: .28),
            ),
            dotData: FlDotData(
              show: dotsCircle || dotsSquare || dotsCross,
              getDotPainter: (spot, percent, bar, index) {
                if (dotsSquare) {
                  return FlDotSquarePainter(color: C.neon, size: 9);
                }
                if (dotsCross) {
                  return FlDotCrossPainter(color: C.neon, size: 12, width: 2);
                }
                return FlDotCirclePainter(color: C.neon, radius: 5);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Pastel (B18–B23) ──
  Widget _pastelBase(
    List<Dato> ds, {
    double hole = 0,
    int? splitIndex,
    bool rounded = false,
    bool sunbeam = false,
    double? titleOffset,
    bool outsideTitles = false,
  }) {
    if (ds.isEmpty) return _vacio(Icons.pie_chart_outline);
    var tot = 0.0;
    for (final d in ds) {
      tot += d.valor;
    }
    final rBase = outsideTitles ? 52.0 : 76.0;
    return PieChart(
      PieChartData(
        centerSpaceRadius: hole > 0 ? hole : 0,
        sectionsSpace: 2,
        titleSunbeamLayout: sunbeam,
        sections: [
          for (var i = 0; i < ds.length; i++)
            PieChartSectionData(
              value: ds[i].valor,
              color: _c(i),
              radius: splitIndex == i ? rBase + 14 : rBase,
              cornerRadius: rounded ? 12 : 0,
              showTitle: true,
              title: outsideTitles || sunbeam
                  ? ds[i].nombre
                  : tot == 0
                  ? ''
                  : '${(ds[i].valor / tot * 100).toStringAsFixed(0)}%',
              titlePositionPercentageOffset: titleOffset,
              titleStyle: TextStyle(
                fontSize: outsideTitles || sunbeam ? 10 : 12,
                fontWeight: FontWeight.w700,
                color: outsideTitles || sunbeam ? Colors.white : Colors.black,
              ),
            ),
        ],
      ),
    );
  }

  // ── Radar (B24–B26): necesita ≥3 entradas ──
  Widget _radarBase(
    List<Dato> ds, {
    RadarShape shape = RadarShape.circle,
    bool fill = true,
    bool rings = false,
  }) {
    if (ds.length < 3) return _vacio(Icons.radar);
    return RadarChart(
      RadarChartData(
        radarShape: shape,
        tickCount: rings ? 4 : 3,
        getTitle: (i, _) => RadarChartTitle(text: ds[i % ds.length].nombre),
        titleTextStyle: const TextStyle(fontSize: 9, color: C.muted),
        ticksTextStyle: rings
            ? const TextStyle(fontSize: 8, color: C.dim)
            : const TextStyle(fontSize: 0, color: Colors.transparent),
        tickBorderData: const BorderSide(color: C.line),
        gridBorderData: const BorderSide(color: C.line),
        radarBackgroundColor: C.card2,
        dataSets: [
          RadarDataSet(
            dataEntries: [for (final d in ds) RadarEntry(value: d.valor)],
            borderColor: C.neon,
            borderWidth: 2,
            fillColor: fill
                ? C.neon.withValues(alpha: .25)
                : Colors.transparent,
            entryRadius: 3,
          ),
        ],
      ),
    );
  }

  // ── Dispersión (B27–B31) ──
  Widget _dispersionBase(
    List<Dato> ds, {
    bool squares = false,
    bool cross = false,
    bool bubbles = false,
    bool labels = false,
  }) {
    if (ds.isEmpty) return _vacio(Icons.scatter_plot_outlined);
    final mx = _maxV(ds) == 0 ? 1.0 : _maxV(ds);
    return ScatterChart(
      ScatterChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        scatterLabelSettings: ScatterLabelSettings(
          showLabel: labels,
          getLabelFunction: (i, spot) =>
              ds[i].nombre.length > 8 ? '${ds[i].nombre.substring(0, 8)}…' : ds[i].nombre,
          getLabelTextStyleFunction: (i, spot) => const TextStyle(
            fontSize: 9,
            color: C.muted,
          ),
        ),
        scatterSpots: [
          for (var i = 0; i < ds.length; i++)
            ScatterSpot(
              i.toDouble(),
              ds[i].valor,
              dotPainter: bubbles
                  ? FlDotCirclePainter(
                      color: _c(i).withValues(alpha: .8),
                      radius: 6 + ds[i].valor / mx * 14,
                    )
                  : squares
                  ? FlDotSquarePainter(color: _c(i), size: 12)
                  : cross
                  ? FlDotCrossPainter(color: _c(i), size: 14, width: 2.5)
                  : FlDotCirclePainter(color: _c(i), radius: 7),
            ),
        ],
      ),
    );
  }

  // ══════════════════════ PRIMITIVAS AVANZADAS ══════════════════════

  // A01 · tooltip al tocar.
  Widget _bTactil(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return BarChart(
      BarChartData(
        maxY: _maxV(ds) * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
              '${ds[gi].nombre}\n${rod.toY.toStringAsFixed(0)}',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < ds.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: ds[i].valor,
                  color: _c(i),
                  width: 20,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // A02 · tooltip fijado en el valor mayor (sin toque).
  Widget _bFijado(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    var top = 0;
    for (var i = 1; i < ds.length; i++) {
      if (ds[i].valor > ds[top].valor) top = i;
    }
    return BarChart(
      BarChartData(
        maxY: _maxV(ds) * 1.3,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        barTouchData: BarTouchData(handleBuiltInTouches: false),
        barGroups: [
          for (var i = 0; i < ds.length; i++)
            BarChartGroupData(
              x: i,
              showingTooltipIndicators: i == top ? [0] : null,
              barRods: [
                BarChartRodData(
                  toY: ds[i].valor,
                  color: i == top ? C.neon : C.card2,
                  width: 20,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // A03 · tres series por posición (ranking de 3 listas).
  Widget _bAgrupadas(List<Dato> a, List<Dato> b, List<Dato> c) {
    final n = min(a.length, min(b.length, c.length));
    if (n == 0) return _vacio(Icons.bar_chart_outlined);
    return BarChart(
      BarChartData(
        maxY: max(_maxV(a), max(_maxV(b, ), _maxV(c))) * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        barGroups: [
          for (var i = 0; i < n; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 4,
              barRods: [
                BarChartRodData(
                  toY: a[i].valor,
                  color: _c(0),
                  width: 8,
                  borderRadius: BorderRadius.circular(3),
                ),
                BarChartRodData(
                  toY: b[i].valor,
                  color: _c(1),
                  width: 8,
                  borderRadius: BorderRadius.circular(3),
                ),
                BarChartRodData(
                  toY: c[i].valor,
                  color: _c(2),
                  width: 8,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // A04 · una sola barra apilada por estados.
  Widget _bApiladaUnica(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    var acc = 0.0;
    final segs = <BarChartRodStackItem>[];
    for (var i = 0; i < ds.length; i++) {
      segs.add(BarChartRodStackItem(acc, acc + ds[i].valor, _c(i)));
      acc += ds[i].valor;
    }
    return BarChart(
      BarChartData(
        maxY: acc * 1.1,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: acc,
                width: 56,
                rodStackItems: segs,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // A05 · degradado en cada barra.
  Widget _bDegradado(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return BarChart(
      BarChartData(
        maxY: _maxV(ds) * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        barGroups: [
          for (var i = 0; i < ds.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: ds[i].valor,
                  width: 20,
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [_c(i), _c(i + 2)],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // A06 · whiskers de margen referencial ±12%.
  Widget _bError(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return BarChart(
      BarChartData(
        maxY: _maxV(ds) * 1.3,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        errorIndicatorData: FlErrorIndicatorData(
          painter: (_) => FlSimpleErrorPainter(
            lineColor: C.muted,
            lineWidth: 1.2,
            capLength: 7,
          ),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
              '${rod.toY.toStringAsFixed(0)} ±12%',
              const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < ds.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: ds[i].valor,
                  color: _c(i),
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                  toYErrorRange: FlErrorRange(
                    lowerBy: ds[i].valor * .12,
                    upperBy: ds[i].valor * .12,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // A07 · línea de promedio con etiqueta.
  Widget _bMeta(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    final p = _prom(ds);
    return BarChart(
      BarChartData(
        maxY: _maxV(ds) * 1.25,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: p,
              color: C.red,
              strokeWidth: 2,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                style: const TextStyle(color: C.red, fontSize: 10),
                labelResolver: (_) => 'Prom ${p.toStringAsFixed(1)}',
              ),
            ),
          ],
        ),
        barGroups: [
          for (var i = 0; i < ds.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: ds[i].valor,
                  color: _c(i),
                  width: 20,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // A08 · banda sombreada entre promedio y máximo.
  Widget _bBanda(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    final p = _prom(ds);
    return BarChart(
      BarChartData(
        maxY: _maxV(ds) * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        rangeAnnotations: RangeAnnotations(
          horizontalRangeAnnotations: [
            HorizontalRangeAnnotation(
              y1: p,
              y2: _maxV(ds),
              color: C.neon.withValues(alpha: .12),
            ),
          ],
        ),
        barGroups: [
          for (var i = 0; i < ds.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: ds[i].valor,
                  color: _c(i),
                  width: 20,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // A09 · dos líneas: valores y acumulado.
  Widget _bDoble(List<Dato> a, List<Dato> b) {
    if (a.isEmpty || b.isEmpty) return _vacio(Icons.show_chart);
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _spots(a),
            color: C.neon,
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: _spots(b),
            color: _c(1),
            barWidth: 3,
            isCurved: true,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  // A10 · línea y área con degradado.
  Widget _lineaDegradado(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _spots(ds),
            isCurved: true,
            barWidth: 3,
            gradient: const LinearGradient(
              colors: [Color(0xFF39FF14), Color(0xFF22D3EE)],
            ),
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  C.neon.withValues(alpha: .45),
                  C.neon.withValues(alpha: .03),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // A11 · corredor entre valor y promedio.
  Widget _bCorredor(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return LineChart(
      LineChartData(
        minY: 0,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _spots(ds),
            color: C.neon,
            barWidth: 3,
            dotData: FlDotData(show: true, getDotPainter: (s, p, b, _) =>
                FlDotCirclePainter(color: C.neon, radius: 4)),
          ),
          LineChartBarData(
            spots: _spots(_constante(ds, _prom(ds))),
            color: C.red,
            barWidth: 2,
            dashArray: [6, 4],
            dotData: const FlDotData(show: false),
          ),
        ],
        betweenBarsData: [
          BetweenBarsData(
            fromIndex: 0,
            toIndex: 1,
            color: C.neon.withValues(alpha: .18),
          ),
        ],
      ),
    );
  }

  // A12 · promedio horizontal + línea vertical en el máximo.
  Widget _bPromEvento(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    var top = 0;
    for (var i = 1; i < ds.length; i++) {
      if (ds[i].valor > ds[top].valor) top = i;
    }
    return LineChart(
      LineChartData(
        minY: 0,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: _prom(ds),
              color: C.red,
              strokeWidth: 2,
              label: HorizontalLineLabel(
                show: true,
                style: const TextStyle(color: C.red, fontSize: 10),
                labelResolver: (_) => 'Promedio',
              ),
            ),
          ],
          verticalLines: [
            VerticalLine(
              x: top.toDouble(),
              color: _c(1),
              strokeWidth: 2,
              dashArray: [4, 4],
              label: VerticalLineLabel(
                show: true,
                style: TextStyle(color: _c(1), fontSize: 10),
                labelResolver: (_) => 'Máximo',
              ),
            ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _spots(ds),
            color: C.neon,
            barWidth: 3,
            dotData: FlDotData(show: true, getDotPainter: (s, p, b, _) =>
                FlDotCirclePainter(color: C.neon, radius: 4)),
          ),
        ],
      ),
    );
  }

  // A13 · bandas de rango horizontal y vertical.
  Widget _bZonas(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return LineChart(
      LineChartData(
        minY: 0,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        rangeAnnotations: RangeAnnotations(
          horizontalRangeAnnotations: [
            HorizontalRangeAnnotation(
              y1: _prom(ds),
              y2: _maxV(ds),
              color: C.neon.withValues(alpha: .12),
            ),
          ],
          verticalRangeAnnotations: [
            VerticalRangeAnnotation(
              x1: 0,
              x2: (ds.length / 3).clamp(1, ds.length).toDouble(),
              color: _c(1).withValues(alpha: .12),
            ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _spots(ds),
            color: C.neon,
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  // A14 · cruz y guía sobre el punto tocado.
  Widget _bTouchCruz(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          getTouchedSpotIndicator: (barData, spotIndexes) => [
            for (final _ in spotIndexes)
              TouchedSpotIndicatorData(
                FlLine(color: C.neon, strokeWidth: 2),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, _) =>
                      FlDotCirclePainter(color: C.neon, radius: 7),
                ),
              ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _spots(ds),
            color: C.neon,
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  // A15 · guía vertical permanente en todos los puntos.
  Widget _bIndicadores(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _spots(ds),
            color: C.neon,
            barWidth: 3,
            showingIndicators: [for (var i = 0; i < ds.length; i++) i],
            dotData: FlDotData(show: true, getDotPainter: (s, p, b, _) =>
                FlDotCirclePainter(color: C.neon, radius: 5)),
          ),
        ],
      ),
    );
  }

  // A16 · área cortada en el promedio con gotas hasta cada punto.
  Widget _bCorte(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return LineChart(
      LineChartData(
        minY: 0,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _spots(ds),
            color: C.neon,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: C.neon.withValues(alpha: .3),
              cutOffY: _prom(ds),
              applyCutOffY: true,
              spotsLine: BarAreaSpotsLine(
                show: true,
                flLineStyle: FlLine(
                  color: C.muted,
                  strokeWidth: 1,
                  dashArray: [3, 3],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // A17 · barras de error ±10% por punto.
  Widget _bErrorLinea(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return LineChart(
      LineChartData(
        minY: 0,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (final d in ds)
                FlSpot(
                  ds.indexOf(d).toDouble(),
                  d.valor,
                  yError: FlErrorRange(
                    lowerBy: d.valor * .1,
                    upperBy: d.valor * .1,
                  ),
                ),
            ],
            color: C.neon,
            barWidth: 3,
            dotData: FlDotData(show: true, getDotPainter: (s, p, b, _) =>
                FlDotCirclePainter(color: C.neon, radius: 5)),
            errorIndicatorData: FlErrorIndicatorData(
              painter: (_) => FlSimpleErrorPainter(
                lineColor: C.muted,
                lineWidth: 1,
                capLength: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // A18 · zoom y paneo con gestos.
  Widget _bZoom(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        clipData: const FlClipData.all(),
        lineBarsData: [
          LineChartBarData(
            spots: _spots(ds),
            color: C.neon,
            barWidth: 3,
            dotData: FlDotData(show: true, getDotPainter: (s, p, b, _) =>
                FlDotCirclePainter(color: C.neon, radius: 4)),
          ),
        ],
      ),
      transformationConfig: const FlTransformationConfig(
        scaleAxis: FlScaleAxis.free,
        maxScale: 4,
      ),
    );
  }

  // A19 · pastel con degradado por sección.
  Widget _pastelDegradado(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.pie_chart_outline);
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        sections: [
          for (var i = 0; i < ds.length; i++)
            PieChartSectionData(
              value: ds[i].valor,
              radius: 74,
              gradient: LinearGradient(
                colors: [_c(i), _c(i + 2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
        ],
      ),
    );
  }

  // A20 · dona con insignias (letra) sobre cada porción.
  Widget _donaBadges(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.donut_large_outlined);
    return PieChart(
      PieChartData(
        centerSpaceRadius: 48,
        sectionsSpace: 3,
        sections: [
          for (var i = 0; i < ds.length; i++)
            PieChartSectionData(
              value: ds[i].valor,
              color: _c(i),
              radius: 60,
              showTitle: false,
              badgeWidget: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _c(i),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  ds[i].nombre.isEmpty ? '?' : ds[i].nombre[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
              badgePositionPercentageOffset: .95,
            ),
        ],
      ),
    );
  }

  // A21 · sin separación, bordes del fondo.
  Widget _pastelContiguo(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.pie_chart_outline);
    return PieChart(
      PieChartData(
        sectionsSpace: 0,
        sections: [
          for (var i = 0; i < ds.length; i++)
            PieChartSectionData(
              value: ds[i].valor,
              color: _c(i),
              radius: 74,
              cornerRadius: 6,
              borderSide: const BorderSide(color: C.bg, width: 2),
            ),
        ],
      ),
    );
  }

  // A22 · Nightingale: el radio crece con el valor.
  Widget _pastelRosa(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.pie_chart_outline);
    final mx = _maxV(ds) == 0 ? 1.0 : _maxV(ds);
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        sections: [
          for (var i = 0; i < ds.length; i++)
            PieChartSectionData(
              value: ds[i].valor,
              color: _c(i),
              radius: 34 + ds[i].valor / mx * 48,
              showTitle: false,
            ),
        ],
      ),
    );
  }

  // A23 · al tocar, la porción se agranda.
  Widget _pastelTactil(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.pie_chart_outline);
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        pieTouchData: PieTouchData(
          touchCallback: (event, response) {
            if (!mounted) return;
            setState(() {
              _tocada = response?.touchedSection?.touchedSectionIndex;
            });
          },
        ),
        sections: [
          for (var i = 0; i < ds.length; i++)
            PieChartSectionData(
              value: ds[i].valor,
              color: i == _tocada ? C.neon : _c(i),
              radius: i == _tocada ? 96 : 68,
              showTitle: false,
            ),
        ],
      ),
    );
  }

  // A24 · dos series: valor real vs promedio.
  Widget _radarDosSeries(List<Dato> ds) {
    if (ds.length < 3) return _vacio(Icons.radar);
    final p = _prom(ds);
    return RadarChart(
      RadarChartData(
        getTitle: (i, _) => RadarChartTitle(text: ds[i % ds.length].nombre),
        titleTextStyle: const TextStyle(fontSize: 9, color: C.muted),
        gridBorderData: const BorderSide(color: C.line),
        tickBorderData: const BorderSide(color: C.line),
        radarBackgroundColor: C.card2,
        dataSets: [
          RadarDataSet(
            dataEntries: [for (final d in ds) RadarEntry(value: d.valor)],
            borderColor: C.neon,
            borderWidth: 2,
            fillColor: C.neon.withValues(alpha: .3),
          ),
          RadarDataSet(
            dataEntries: [for (final _ in ds) RadarEntry(value: p)],
            borderColor: _c(1),
            borderWidth: 2,
            entryRadius: 2,
            fillColor: _c(1).withValues(alpha: .15),
          ),
        ],
      ),
    );
  }

  // A25 · relleno con degradado.
  Widget _radarDegradado(List<Dato> ds) {
    if (ds.length < 3) return _vacio(Icons.radar);
    return RadarChart(
      RadarChartData(
        getTitle: (i, _) => RadarChartTitle(text: ds[i % ds.length].nombre),
        titleTextStyle: const TextStyle(fontSize: 9, color: C.muted),
        gridBorderData: const BorderSide(color: C.line),
        tickBorderData: const BorderSide(color: C.line),
        radarBackgroundColor: C.card2,
        dataSets: [
          RadarDataSet(
            dataEntries: [for (final d in ds) RadarEntry(value: d.valor)],
            borderColor: C.neon,
            borderWidth: 2,
            fillGradient: const LinearGradient(
              colors: [Color(0xFF39FF14), Color(0xFF22D3EE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ],
      ),
    );
  }

  // A26 · al tocar un vértice, su etiqueta se resalta.
  Widget _radarTactil(List<Dato> ds) {
    if (ds.length < 3) return _vacio(Icons.radar);
    return RadarChart(
      RadarChartData(
        getTitle: (i, _) {
          final on = i == _radarTocada;
          return RadarChartTitle(
            text: ds[i % ds.length].nombre,
            positionPercentageOffset: on ? .5 : null,
          );
        },
        titleTextStyle: const TextStyle(fontSize: 9, color: C.muted),
        gridBorderData: const BorderSide(color: C.line),
        tickBorderData: const BorderSide(color: C.line),
        radarBackgroundColor: C.card2,
        radarTouchData: RadarTouchData(
          enabled: true,
          touchCallback: (event, response) {
            if (!mounted) return;
            setState(() {
              _radarTocada = response?.touchedSpot?.touchedRadarEntryIndex;
            });
          },
        ),
        dataSets: [
          RadarDataSet(
            dataEntries: [for (final d in ds) RadarEntry(value: d.valor)],
            borderColor: C.neon,
            borderWidth: 2,
            fillColor: C.neon.withValues(alpha: .25),
            entryRadius: _radarTocada == null ? 3 : 6,
          ),
        ],
      ),
    );
  }

  // A27 · dispersión con tooltip al tocar.
  Widget _bDispTouch(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.scatter_plot_outlined);
    return ScatterChart(
      ScatterChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        scatterTouchData: ScatterTouchData(
          enabled: true,
          handleBuiltInTouches: true,
        ),
        scatterSpots: [
          for (var i = 0; i < ds.length; i++)
            ScatterSpot(
              i.toDouble(),
              ds[i].valor,
              dotPainter: FlDotCirclePainter(color: _c(i), radius: 8),
            ),
        ],
      ),
    );
  }

  // A28 · error bars verticales por punto.
  Widget _bDispError(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.scatter_plot_outlined);
    return ScatterChart(
      ScatterChartData(
        minY: 0,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        scatterSpots: [
          for (var i = 0; i < ds.length; i++)
            ScatterSpot(
              i.toDouble(),
              ds[i].valor,
              yError: FlErrorRange(
                lowerBy: ds[i].valor * .15,
                upperBy: ds[i].valor * .15,
              ),
              dotPainter: FlDotCirclePainter(color: _c(i), radius: 7),
            ),
        ],
        errorIndicatorData: FlErrorIndicatorData(
          painter: (_) => FlSimpleErrorPainter(
            lineColor: C.muted,
            lineWidth: 1,
            capLength: 6,
          ),
        ),
      ),
    );
  }

  // A29 · dispersión con zoom y paneo.
  Widget _bDispZoom(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.scatter_plot_outlined);
    return ScatterChart(
      ScatterChartData(
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        clipData: const FlClipData.all(),
        scatterSpots: [
          for (var i = 0; i < ds.length; i++)
            ScatterSpot(
              i.toDouble(),
              ds[i].valor,
              renderPriority: ds.length - i,
              dotPainter: FlDotCirclePainter(
                color: _c(i),
                radius: 9,
                strokeWidth: 2,
                strokeColor: Colors.black,
            ),
          ),
        ],
      ),
      transformationConfig: const FlTransformationConfig(
        scaleAxis: FlScaleAxis.free,
        maxScale: 5,
      ),
    );
  }

  // A30 · etiquetas + tooltip juntos.
  Widget _bDispLabelsTouch(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.scatter_plot_outlined);
    return ScatterChart(
      ScatterChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        scatterTouchData: ScatterTouchData(enabled: true),
        scatterLabelSettings: ScatterLabelSettings(
          showLabel: true,
          getLabelFunction: (i, spot) =>
              ds[i].nombre.length > 8 ? '${ds[i].nombre.substring(0, 8)}…' : ds[i].nombre,
          getLabelTextStyleFunction: (i, spot) => const TextStyle(
            fontSize: 9,
            color: Colors.white,
          ),
        ),
        scatterSpots: [
          for (var i = 0; i < ds.length; i++)
            ScatterSpot(
              i.toDouble(),
              ds[i].valor,
              dotPainter: FlDotCirclePainter(color: _c(i), radius: 7),
            ),
        ],
      ),
    );
  }

  // A31 · apiladas + degradado + tooltip.
  Widget _bApiladasTouch(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    var acc = 0.0;
    final segs = <BarChartRodStackItem>[];
    for (var i = 0; i < ds.length; i++) {
      segs.add(
        BarChartRodStackItem(
          acc,
          acc + ds[i].valor,
          null,
          gradient: LinearGradient(
            colors: [_c(i), _c(i + 2)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
      );
      acc += ds[i].valor;
    }
    return BarChart(
      BarChartData(
        maxY: acc * 1.1,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
              'Capa ${ri + 1}: ${rod.toY.toStringAsFixed(1)}',
              const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: acc,
                width: 60,
                rodStackItems: segs,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // A32 · doble línea con área degradada y tooltip.
  Widget _bDobleTouch(List<Dato> a, List<Dato> b) {
    if (a.isEmpty || b.isEmpty) return _vacio(Icons.show_chart);
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: LineTouchData(enabled: true),
        lineBarsData: [
          LineChartBarData(
            spots: _spots(a),
            isCurved: true,
            barWidth: 3,
            gradient: const LinearGradient(
              colors: [Color(0xFF39FF14), Color(0xFF22D3EE)],
            ),
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  C.neon.withValues(alpha: .4),
                  C.neon.withValues(alpha: .03),
                ],
              ),
            ),
          ),
          LineChartBarData(
            spots: _spots(b),
            color: _c(2),
            barWidth: 2,
            dashArray: [5, 4],
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  // ═══════════════ CATÁLOGO ═══════════════
  // Una sola lista por conjunto (título, descripción, dibujo) para que
  // los tres arreglos de ChartViewer nunca se desincronicen.

  List<(String, String, Widget)> _basicas(StatsData d) => [
    (
      'B01 · Barras verticales redondeadas',
      'Cuántos personajes están vivos, muertos o con estado desconocido.',
      _bRedondas(d.status),
    ),
    (
      'B02 · Barras minimalistas',
      'Las especies más comunes entre los personajes de la serie.',
      _bMinimal(d.species),
    ),
    (
      'B03 · Histograma de apariciones',
      'Cuántos personajes aparecen en 1, 2-5, 6-10 o más de 10 episodios.',
      _bHistograma(d.epsPorPersonaje),
    ),
    (
      'B04 · Barras horizontales',
      'Los personajes con más episodios de la serie (top del ranking).',
      _bHorizontal(d.topPersonajesEps),
    ),
    (
      'B05 · Barras con pista de fondo',
      'Las ubicaciones o planetas donde más personajes se encuentran.',
      _bPista(d.location),
    ),
    (
      'B06 · Barras divergentes',
      'De qué planetas vienen los personajes; en verde los que superan el promedio y en rojo los que no.',
      _bDivergentes(d.origin),
    ),
    (
      'B07 · Barras con etiqueta en la punta',
      'Cuántos personajes son hombres, mujeres, sin género o desconocidos.',
      _bEtiqueta(d.gender),
    ),
    (
      'B08 · Barras con borde punteado',
      'Cuántos episodios tiene cada temporada de la serie.',
      _bBordePunteado(d.epsPorTemporada),
    ),
    (
      'B09 · Línea recta temporal',
      'Cuántos episodios se estrenaron cada año, de principio a fin de la serie.',
      _lineaBase(_anios(d)),
    ),
    (
      'B10 · Línea curva',
      'Cuántos personajes aparecen en cada uno de los primeros episodios.',
      _lineaBase(d.charsPorEpisodio, curved: true),
    ),
    (
      'B11 · Línea punteada',
      'Cuántos episodios tiene cada temporada de la serie.',
      _lineaBase(d.epsPorTemporada, dash: [8, 6]),
    ),
    (
      'B12 · Línea escalonada',
      'Cuántos personajes hay por estado de vida o muerte.',
      _lineaBase(d.status, step: true),
    ),
    (
      'B13 · Línea con área inferior',
      'Cuántos episodios se estrenaron cada año, con el volumen total bajo la curva.',
      _lineaBase(_anios(d), area: true),
    ),
    (
      'B14 · Línea con puntos circulares',
      'Las especies más comunes entre los personajes de la serie.',
      _lineaBase(d.species, dotsCircle: true),
    ),
    (
      'B15 · Línea con puntos cuadrados',
      'De qué planetas vienen los personajes: los orígenes más comunes.',
      _lineaBase(d.origin, dotsSquare: true),
    ),
    (
      'B16 · Línea gruesa con sombra',
      'Las ubicaciones donde más personajes se encuentran.',
      _lineaBase(d.location, thick: true, dotsCircle: true),
    ),
    (
      'B17 · Línea con cruces',
      'Cuántos personajes tienen 1, 2-5, 6-10 o más de 10 episodios.',
      _lineaBase(d.epsPorPersonaje, dotsCross: true),
    ),
    (
      'B18 · Pastel clásico',
      'Qué proporción de personajes está vivo, muerto o con estado desconocido.',
      _pastelBase(d.status),
    ),
    (
      'B19 · Dona',
      'Qué proporción de personajes pertenece a cada especie.',
      _pastelBase(d.species, hole: 42),
    ),
    (
      'B20 · Pastel con rebanada destacada',
      'Cuántos personajes son hombres, mujeres, sin género o desconocidos, resaltando el grupo mayor.',
      _pastelBase(d.gender, splitIndex: 0),
    ),
    (
      'B21 · Pastel de esquinas redondeadas',
      'De qué planetas vienen los personajes: los orígenes más comunes.',
      _pastelBase(d.origin, rounded: true),
    ),
    (
      'B22 · Pastel sunbeam',
      'Las ubicaciones o planetas donde más personajes se encuentran.',
      _pastelBase(d.location, sunbeam: true),
    ),
    (
      'B23 · Pastel con títulos exteriores',
      'Cuántos episodios tiene cada temporada, con el nombre de cada una.',
      _pastelBase(d.epsPorTemporada, outsideTitles: true, titleOffset: 1.0),
    ),
    (
      'B24 · Radar de círculo',
      'Cuántos personajes hay por estado, comparando los tres grupos en una sola figura.',
      _radarBase(d.status),
    ),
    (
      'B25 · Radar polígono',
      'Las especies más comunes comparadas entre sí en una sola figura.',
      _radarBase(d.species, shape: RadarShape.polygon, fill: false),
    ),
    (
      'B26 · Radar con anillos de escala',
      'Cuántos personajes son hombres, mujeres o desconocidos, con anillos para leer la magnitud.',
      _radarBase(d.gender, rings: true),
    ),
    (
      'B27 · Dispersión de círculos',
      'Cuántos personajes aparecen en cada uno de los primeros episodios.',
      _dispersionBase(d.charsPorEpisodio),
    ),
    (
      'B28 · Dispersión de cuadrados',
      'Cuántos episodios se estrenaron en cada año.',
      _dispersionBase(_anios(d), squares: true),
    ),
    (
      'B29 · Dispersión de cruces',
      'Los personajes con más episodios de la serie y cuántos episodios tiene cada uno.',
      _dispersionBase(d.topPersonajesEps, cross: true),
    ),
    (
      'B30 · Burbujas por valor',
      'Cuántos episodios tiene cada temporada; cuanto más grande la burbuja, más episodios.',
      _dispersionBase(d.epsPorTemporada, bubbles: true),
    ),
    (
      'B31 · Dispersión con etiquetas',
      'Cuántos personajes tienen 1, 2-5, 6-10 o más de 10 episodios, con el rótulo de cada rango.',
      _dispersionBase(d.epsPorPersonaje, labels: true),
    ),
  ];

  List<(String, String, Widget)> _avanzadas(StatsData d) => [
    (
      'A01 · Barras con tooltip al tocar',
      'Cuántos personajes están vivos, muertos o desconocidos; toca una barra para ver su valor.',
      _bTactil(d.status),
    ),
    (
      'A02 · Barras con tooltip fijado',
      'Las especies más comunes, con la más numerosa marcada con su valor.',
      _bFijado(d.species),
    ),
    (
      'A03 · Barras agrupadas por posición',
      'Especies, orígenes y ubicaciones más comunes comparados entre sí.',
      _bAgrupadas(d.species, d.origin, d.location),
    ),
    (
      'A04 · Barra apilada por estado',
      'Cuántos personajes hay por estado, sumados todos en una sola barra.',
      _bApiladaUnica(d.status),
    ),
    (
      'A05 · Barras con degradado',
      'De qué planetas vienen los personajes: los orígenes más comunes.',
      _bDegradado(d.origin),
    ),
    (
      'A06 · Barras con margen de error',
      'Cuántos personajes son hombres, mujeres o desconocidos, con su margen de variación.',
      _bError(d.gender),
    ),
    (
      'A07 · Barras con línea de promedio',
      'Las especies más comunes frente al promedio de personajes por especie.',
      _bMeta(d.species),
    ),
    (
      'A08 · Barras con banda de rango',
      'Las especies, marcando la distancia entre el promedio y la más común.',
      _bBanda(d.species),
    ),
    (
      'A09 · Doble línea: anual y acumulado',
      'Cuántos episodios se estrenaron cada año y cuántos llevamos acumulados en total.',
      _bDoble(_anios(d), _acum(_anios(d))),
    ),
    (
      'A10 · Línea y área en degradado',
      'Cuántos episodios se estrenaron cada año, con el volumen acumulado bajo la curva.',
      _lineaDegradado(_anios(d)),
    ),
    (
      'A11 · Banda entre valor y promedio',
      'Cuántos personajes aparecen en cada episodio y cuánto se alejan de su promedio.',
      _bCorredor(d.charsPorEpisodio),
    ),
    (
      'A12 · Promedio y evento',
      'Cuántos episodios tiene cada temporada, su promedio y cuál es la temporada más larga.',
      _bPromEvento(d.epsPorTemporada),
    ),
    (
      'A13 · Zonas de rango',
      'Cuántos episodios se estrenaron cada año, marcando los años altos y el tramo inicial.',
      _bZonas(_anios(d)),
    ),
    (
      'A14 · Línea con cruz al tocar',
      'Cuántos personajes aparecen en cada episodio; toca un punto para ver su valor exacto.',
      _bTouchCruz(d.charsPorEpisodio),
    ),
    (
      'A15 · Línea con indicadores fijos',
      'Las especies más comunes, con su valor visible en cada punto sin tocar nada.',
      _bIndicadores(d.species),
    ),
    (
      'A16 · Área cortada con gotas',
      'Cuántos episodios tiene cada temporada respecto a su promedio: gotas hacia arriba o abajo.',
      _bCorte(d.epsPorTemporada),
    ),
    (
      'A17 · Línea con barras de error',
      'De qué planetas vienen los personajes, con el margen de variación de cada origen.',
      _bErrorLinea(d.origin),
    ),
    (
      'A18 · Línea con zoom',
      'Cuántos episodios se estrenaron cada año; acerca y mueve la vista para ver un tramo concreto.',
      _bZoom(_anios(d)),
    ),
    (
      'A19 · Pastel con degradado',
      'Qué proporción de personajes está vivo, muerto o con estado desconocido.',
      _pastelDegradado(d.status),
    ),
    (
      'A20 · Dona con badges',
      'Qué proporción de personajes pertenece a cada especie, identificada por su inicial.',
      _donaBadges(d.species),
    ),
    (
      'A21 · Pastel contiguo con bordes',
      'Cuántos personajes son hombres, mujeres, sin género o desconocidos.',
      _pastelContiguo(d.gender),
    ),
    (
      'A22 · Pastel de radios variables',
      'De qué planetas vienen los personajes; a más personajes, más grande la porción (rosa de Nightingale).',
      _pastelRosa(d.origin),
    ),
    (
      'A23 · Pastel táctil',
      'Las ubicaciones con más personajes; toca una porción para resaltarla y ver cuántos hay en ella.',
      _pastelTactil(d.location),
    ),
    (
      'A24 · Radar de dos series',
      'Cuántos episodios tiene cada temporada comparados con su promedio.',
      _radarDosSeries(d.epsPorTemporada),
    ),
    (
      'A25 · Radar con degradado',
      'Cuántos personajes están vivos, muertos o con estado desconocido.',
      _radarDegradado(d.status),
    ),
    (
      'A26 · Radar táctil',
      'Las especies más comunes; toca un vértice para ver cuántos personajes hay de esa especie.',
      _radarTactil(d.species),
    ),
    (
      'A27 · Dispersión con tooltip',
      'Cuántos personajes aparecen en cada uno de los primeros episodios; toca un punto para ver su valor.',
      _bDispTouch(d.charsPorEpisodio),
    ),
    (
      'A28 · Dispersión con error bars',
      'Cuántos episodios se estrenaron cada año, con su margen de variación en cada punto.',
      _bDispError(_anios(d)),
    ),
    (
      'A29 · Dispersión con zoom',
      'Los personajes con más episodios; acerca y mueve la vista para leer el ranking completo.',
      _bDispZoom(d.topPersonajesEps),
    ),
    (
      'A30 · Dispersión con etiquetas y toque',
      'Cuántos personajes tienen 1, 2-5, 6-10 o más de 10 episodios; toca un punto para ver su valor.',
      _bDispLabelsTouch(d.epsPorPersonaje),
    ),
    (
      'A31 · Barras apiladas con degradado y tooltip',
      'Cuántos personajes son hombres, mujeres o desconocidos; toca una barra para ver el detalle.',
      _bApiladasTouch(d.gender),
    ),
    (
      'A32 · Doble línea con área y tooltip',
      'Episodios por año y total acumulado; toca un año para ver sus dos cifras.',
      _bDobleTouch(_anios(d), _acum(_anios(d))),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('fl_chart', style: T.title)),
      body: FutureBuilder<StatsData>(
        future: _fut,
        builder: (context, s) {
          if (s.connectionState == ConnectionState.waiting) {
            return const Busy(text: 'Calculando stats...');
          }
          if (s.hasError || !s.hasData) {
            return Oops(
              message: 'No se pudo calcular.',
              retry: () =>
                  setState(() => _fut = _svc.load(context.read<Api>())),
            );
          }
          final d = s.data!;
          final b = _basicas(d);
          final a = _avanzadas(d);
          return Centered(
            max: Rx.reading,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(D.pad, 12, D.pad, 24),
              children: [
                ChartViewer(
                  etiqueta: 'BÁSICA',
                  titulos: [for (final x in b) x.$1],
                  descripciones: [for (final x in b) x.$2],
                  hijos: [for (final x in b) x.$3],
                  indice: _basic,
                  onChanged: (v) => setState(() => _basic = v),
                ),
                const SizedBox(height: 14),
                ChartViewer(
                  etiqueta: 'AVANZADA',
                  titulos: [for (final x in a) x.$1],
                  descripciones: [for (final x in a) x.$2],
                  hijos: [for (final x in a) x.$3],
                  indice: _adv,
                  onChanged: (v) => setState(() => _adv = v),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Extensión mínima para las divergentes (valor por referencia).
extension on double {
  R also<R>(R Function(double) fn) => fn(this);
}
