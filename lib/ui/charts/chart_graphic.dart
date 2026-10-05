// ─── Pantalla 2/4: graphic ────────────────────────────────────────
// SOLO importa graphic (gramática de gráficos).
// BÁSICAS = una variante visual por familia, sin toque, degradados
// ni animación.
// AVANZADAS = tooltip, selección, crosshair, anotaciones, multi-serie,
// apiladas, degradados y animación. Ninguna repite estructura ni
// presentación con otra dentro de esta pantalla.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart';
import 'package:provider/provider.dart';

import '../../core/adaptive.dart';
import '../../core/theme.dart';
import '../../data/api.dart';
import '../../data/stats_service.dart';
import '../widgets/chart_viewer.dart';
import '../widgets/common.dart';

class ChartGraphicScreen extends StatefulWidget {
  const ChartGraphicScreen({super.key});
  @override
  State<ChartGraphicScreen> createState() => _ChartGraphicScreenState();
}

class _ChartGraphicScreenState extends State<ChartGraphicScreen> {
  Future<StatsData>? _fut;
  int _basic = 0;
  int _adv = 0;
  final _svc = StatsService();

  @override
  void initState() {
    super.initState();
    Defaults.primaryColor = C.neon;
    Defaults.strokeColor = C.line;
    Defaults.textColor = C.muted;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fut ??= _svc.load(context.read<Api>());
  }

  static const _lbl = TextStyle(color: C.muted, fontSize: 9);

  static const _cols = [
    Color(0xFF39FF14),
    Color(0xFF22D3EE),
    Color(0xFFFBBF24),
    Color(0xFFF472B6),
    Color(0xFFA78BFA),
    Color(0xFFFF6B6B),
  ];
  Color _c(int i) => _cols[i % _cols.length];

  List<Map> _rows(List<Dato> ds) => [
    for (final d in ds) {'nombre': d.nombre, 'valor': d.valor},
  ];

  Map<String, Variable<Map, dynamic>> _vars() => {
    'nombre': Variable(accessor: (Map m) => m['nombre'] as String),
    'valor': Variable(
      accessor: (Map m) => m['valor'] as num,
      scale: LinearScale(min: 0, niceRange: true),
    ),
  };

  Map<String, Variable<Map, dynamic>> _varsTopo(List<Dato> ds) => {
    'nombre': Variable(accessor: (Map m) => m['nombre'] as String),
    'valor': Variable(
      accessor: (Map m) => m['valor'] as num,
      scale: LinearScale(min: 0, max: _maxV(ds) * 1.2, tickCount: 4),
    ),
  };

  Map<String, Variable<Map, dynamic>> _varsSerie() => {
    'nombre': Variable(accessor: (Map m) => m['nombre'] as String),
    'valor': Variable(
      accessor: (Map m) => m['valor'] as num,
      scale: LinearScale(min: 0, niceRange: true),
    ),
    'serie': Variable(accessor: (Map m) => m['serie'] as String),
  };

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

  double _tot(List<Dato> ds) {
    var s = 0.0;
    for (final d in ds) {
      s += d.valor;
    }
    return s;
  }

  List<Dato> _anios(StatsData d) =>
      [...d.epsPorAnio]..sort((a, b) => a.nombre.compareTo(b.nombre));

  List<Map> _valorResto(List<Dato> ds) {
    final t = _tot(ds);
    return [
      for (final d in ds) ...[
        {'nombre': d.nombre, 'serie': 'Valor', 'valor': d.valor},
        {'nombre': d.nombre, 'serie': 'Resto', 'valor': t - d.valor},
      ],
    ];
  }

  List<Map> _valorProm(List<Dato> ds) {
    final p = _prom(ds);
    return [
      for (final d in ds) ...[
        {'nombre': d.nombre, 'serie': 'Valor', 'valor': d.valor},
        {'nombre': d.nombre, 'serie': 'Promedio', 'valor': p},
      ],
    ];
  }

  List<Map> _dosEjes(List<Dato> ds) {
    final p = _prom(ds);
    return [
      for (final d in ds)
        {'nombre': d.nombre, 'valor': d.valor, 'promedio': p},
    ];
  }

  List<Map> _fechas(StatsData d) {
    final out = <Map>[];
    var i = 0;
    for (final x in _anios(d)) {
      out.add({
        'nombre': DateTime(int.tryParse(x.nombre) ?? 2013 + i),
        'valor': x.valor,
      });
      i++;
    }
    return out;
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  Widget _vacio(IconData i) =>
      Nada(icon: i, title: 'Sin datos', body: 'Reintenta.');

  // ══════════════════════ BÁSICAS ══════════════════════

  Widget _bBarras(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [IntervalMark()],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
    );
  }

  Widget _bRedondas(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [
        IntervalMark(
          shape: ShapeEncode(
            value: RectShape(
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
          ),
        ),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
    );
  }

  Widget _bEtiquetas(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [
        IntervalMark(
          label: LabelEncode(
            encoder: (t) =>
                Label(t['valor'].toString(), LabelStyle(textStyle: _lbl)),
          ),
        ),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
    );
  }

  Widget _bHorizontales(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.view_week_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [IntervalMark()],
      coord: RectCoord(transposed: true),
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
    );
  }

  Widget _bMulticolor(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [IntervalMark(color: ColorEncode(variable: 'nombre', values: Defaults.colors10))],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
    );
  }

  Widget _bSinEjes(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return Chart(data: _rows(ds), variables: _vars(), marks: [IntervalMark()]);
  }

  Widget _bEjeFijo(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return Chart(
      data: _rows(ds),
      variables: _varsTopo(ds),
      marks: [IntervalMark()],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
    );
  }

  Widget _bEjesCustom(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [IntervalMark()],
      axes: [
        AxisGuide(
          dim: Dim.x,
          line: PaintStyle(strokeColor: C.line),
          label: LabelStyle(textStyle: _lbl, offset: const Offset(0, 7.5)),
        ),
        AxisGuide(
          dim: Dim.y,
          grid: PaintStyle(strokeColor: C.line),
          label: LabelStyle(textStyle: _lbl, offset: const Offset(-7.5, 0)),
        ),
      ],
    );
  }

  Widget _bFina(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [IntervalMark(size: SizeEncode(value: 6))],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
    );
  }

  Widget _bLinea(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [LineMark()],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
    );
  }

  Widget _bLineaSuave(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [
        LineMark(shape: ShapeEncode(value: BasicLineShape(smooth: true))),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
    );
  }

  Widget _bLineaEscalon(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [
        LineMark(shape: ShapeEncode(value: BasicLineShape(stepped: true))),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
    );
  }

  Widget _bLineaPunteada(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [
        LineMark(shape: ShapeEncode(value: BasicLineShape(dash: [6, 6]))),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
    );
  }

  Widget _bLineaPuntos(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [
        LineMark(color: ColorEncode(value: C.neon)),
        PointMark(color: ColorEncode(value: C.neon)),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
    );
  }

  Widget _bFecha(StatsData d) {
    final ds = _fechas(d);
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return Chart(
      data: ds,
      variables: {
        'nombre': Variable(
          accessor: (Map m) => m['nombre'] as DateTime,
          scale: TimeScale(formatter: (t) => t.year.toString()),
        ),
        'valor': Variable(
          accessor: (Map m) => m['valor'] as num,
          scale: LinearScale(min: 0, niceRange: true),
        ),
      },
      marks: [LineMark(color: ColorEncode(value: C.neon))],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
    );
  }

  Widget _bArea(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.area_chart_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [
        AreaMark(color: ColorEncode(value: C.neon.withValues(alpha: .35))),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
    );
  }

  Widget _bAreaSuave(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.area_chart_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [
        AreaMark(
          shape: ShapeEncode(value: BasicAreaShape(smooth: true)),
          color: ColorEncode(value: _c(1).withValues(alpha: .35)),
        ),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
    );
  }

  Widget _bAreaEscalon(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.area_chart_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [
        AreaMark(
          shape: ShapeEncode(value: BasicAreaShape(stepped: true)),
          color: ColorEncode(value: _c(2).withValues(alpha: .35)),
        ),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
    );
  }

  Widget _bPuntos(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.scatter_plot_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [PointMark()],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
    );
  }

  Widget _bPuntoHueco(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.scatter_plot_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [
        PointMark(shape: ShapeEncode(value: CircleShape(hollow: true))),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
    );
  }

  Widget _bCuadrado(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.scatter_plot_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [PointMark(shape: ShapeEncode(value: SquareShape()))],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
    );
  }

  Widget _bBurbuja(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bubble_chart_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [
        PointMark(size: SizeEncode(variable: 'valor', values: [4, 24])),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
    );
  }

  Widget _bPastel(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.pie_chart_outline);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      transforms: [Proportion(variable: 'valor', as: 'parte')],
      marks: [
        IntervalMark(
          position: Varset('parte') / Varset('nombre'),
          color: ColorEncode(variable: 'nombre', values: Defaults.colors10),
          modifiers: [StackModifier()],
        ),
      ],
      coord: PolarCoord(transposed: true, dimCount: 1),
    );
  }

  Widget _bDona(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.donut_large_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      transforms: [Proportion(variable: 'valor', as: 'parte')],
      marks: [
        IntervalMark(
          position: Varset('parte') / Varset('nombre'),
          color: ColorEncode(variable: 'nombre', values: Defaults.colors10),
          modifiers: [StackModifier()],
        ),
      ],
      coord: PolarCoord(transposed: true, dimCount: 1, startRadius: 0.45),
    );
  }

  Widget _bMediaLuna(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.pie_chart_outline);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      transforms: [Proportion(variable: 'valor', as: 'parte')],
      marks: [
        IntervalMark(
          position: Varset('parte') / Varset('nombre'),
          color: ColorEncode(variable: 'nombre', values: Defaults.colors10),
          modifiers: [StackModifier()],
        ),
      ],
      coord: PolarCoord(
        transposed: true,
        dimCount: 1,
        startAngle: -pi,
        endAngle: 0,
      ),
    );
  }

  Widget _bPastelEtiquetas(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.pie_chart_outline);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      transforms: [Proportion(variable: 'valor', as: 'parte')],
      marks: [
        IntervalMark(
          position: Varset('parte') / Varset('nombre'),
          color: ColorEncode(variable: 'nombre', values: Defaults.colors10),
          modifiers: [StackModifier()],
          label: LabelEncode(encoder: (t) => Label(t['nombre'].toString())),
        ),
      ],
      coord: PolarCoord(transposed: true, dimCount: 1),
    );
  }

  Widget _bRosa(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.local_florist_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [IntervalMark(color: ColorEncode(variable: 'nombre', values: Defaults.colors10))],
      coord: PolarCoord(startRadius: 0.15),
      axes: [Defaults.circularAxis, Defaults.radialAxis],
    );
  }

  Widget _bRosaRedonda(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.local_florist_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [
        IntervalMark(
          shape: ShapeEncode(
            value: RectShape(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
          ),
          color: ColorEncode(variable: 'nombre', values: Defaults.colors10),
        ),
      ],
      coord: PolarCoord(startRadius: 0.15),
      axes: [Defaults.circularAxis, Defaults.radialAxis],
    );
  }

  Widget _bEmbudo(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.filter_alt_outlined);
    final s = [...ds]..sort((a, b) => b.valor.compareTo(a.valor));
    return Chart(
      data: _rows(s),
      variables: _vars(),
      marks: [
        IntervalMark(
          shape: ShapeEncode(value: FunnelShape(labelPosition: 0.5)),
          color: ColorEncode(variable: 'nombre', values: Defaults.colors10),
        ),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
    );
  }

  Widget _bPiramide(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.change_history_outlined);
    final s = [...ds]..sort((a, b) => b.valor.compareTo(a.valor));
    return Chart(
      data: _rows(s),
      variables: _vars(),
      marks: [
        IntervalMark(
          shape: ShapeEncode(value: FunnelShape(pyramid: true)),
          color: ColorEncode(variable: 'nombre', values: Defaults.colors10),
        ),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
    );
  }

  Widget _bCalor(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.grid_on_outlined);
    return Chart(
      data: _valorResto(ds),
      variables: _varsSerie(),
      marks: [
        PolygonMark(
          color: ColorEncode(
            variable: 'valor',
            values: [Color(0xFF12331A), Color(0xFF39FF14)],
          ),
        ),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
    );
  }

  // ══════════════════════ AVANZADAS ══════════════════════

  TooltipGuide get _tt => TooltipGuide(
    backgroundColor: C.card2,
    radius: const Radius.circular(6),
    textStyle: const TextStyle(color: C.text, fontSize: 11),
  );

  CrosshairGuide get _ch => CrosshairGuide(
    styles: [
      PaintStyle(strokeColor: C.neon.withValues(alpha: .7)),
      PaintStyle(strokeColor: C.neon.withValues(alpha: .7)),
    ],
    labelStyles: [
      LabelStyle(textStyle: const TextStyle(color: C.neon, fontSize: 9)),
      LabelStyle(textStyle: const TextStyle(color: C.neon, fontSize: 9)),
    ],
  );

  Widget _aTooltip(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.touch_app_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [IntervalMark()],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
      selections: {'tap': PointSelection(dim: Dim.x)},
      tooltip: _tt,
    );
  }

  Widget _aCrosshair(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.touch_app_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [IntervalMark()],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
      selections: {'tap': PointSelection(dim: Dim.x)},
      crosshair: _ch,
      tooltip: _tt,
    );
  }

  Widget _aAgrupadas(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.dashboard_outlined);
    return Chart(
      data: _valorResto(ds),
      variables: _varsSerie(),
      marks: [
        IntervalMark(
          position: Varset('nombre') * Varset('valor') / Varset('serie'),
          color: ColorEncode(variable: 'serie', values: [C.neon, C.dim]),
          modifiers: [DodgeModifier()],
        ),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
      selections: {'tap': PointSelection(dim: Dim.x)},
      tooltip: _tt,
    );
  }

  Widget _aApiladas(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.stacked_bar_chart_outlined);
    return Chart(
      data: _valorResto(ds),
      variables: _varsSerie(),
      marks: [
        IntervalMark(
          position: Varset('nombre') * Varset('valor') / Varset('serie'),
          color: ColorEncode(variable: 'serie', values: [C.neon, C.dim]),
          modifiers: [StackModifier()],
        ),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
      selections: {'tap': PointSelection(dim: Dim.x)},
      tooltip: _tt,
    );
  }

  Widget _aDegradado(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.gradient_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [
        IntervalMark(
          gradient: GradientEncode(
            value: const LinearGradient(
              colors: [Color(0xFF39FF14), Color(0xFF22D3EE)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
      selections: {'tap': PointSelection(dim: Dim.x)},
      tooltip: _tt,
    );
  }

  Widget _aOrdenada(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.sort_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      transforms: [
        Sort(compare: (a, b) => (b['valor'] as num).compareTo(a['valor'] as num)),
      ],
      marks: [
        IntervalMark(color: ColorEncode(variable: 'nombre', values: Defaults.colors10)),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
      selections: {'tap': PointSelection(dim: Dim.x)},
      tooltip: _tt,
    );
  }

  Widget _aObjetivo(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.my_location);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [LineMark(color: ColorEncode(value: C.neon))],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
      annotations: [
        LineAnnotation(
          dim: Dim.y,
          variable: 'valor',
          value: _prom(ds),
          style: PaintStyle(strokeColor: C.red, dash: [4, 2]),
        ),
      ],
      selections: {'tap': PointSelection(dim: Dim.x)},
      tooltip: _tt,
    );
  }

  Widget _aRegion(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.highlight_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [IntervalMark(color: ColorEncode(value: C.neon))],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
      annotations: [
        RegionAnnotation(
          dim: Dim.x,
          variable: 'nombre',
          values: [ds.first.nombre, ds.last.nombre],
          color: C.neon.withValues(alpha: .12),
        ),
      ],
      selections: {'tap': PointSelection(dim: Dim.x)},
      tooltip: _tt,
    );
  }

  Widget _aAnimada(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.animation);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [
        IntervalMark(
          color: ColorEncode(value: C.neon),
          transition: Transition(duration: const Duration(milliseconds: 900)),
          entrance: const {MarkEntrance.y, MarkEntrance.opacity},
          tag: (t) => t['nombre'].toString(),
        ),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
    );
  }

  Widget _aHorizTouch(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.touch_app_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [IntervalMark(color: ColorEncode(value: C.neon))],
      coord: RectCoord(transposed: true),
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
      selections: {'tap': PointSelection(dim: Dim.x)},
      tooltip: _tt,
    );
  }

  Widget _aLineaTooltip(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [
        LineMark(
          color: ColorEncode(value: C.neon),
          size: SizeEncode(value: 2.5),
        ),
        PointMark(color: ColorEncode(value: C.neon), size: SizeEncode(value: 5)),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
      selections: {'tap': PointSelection(dim: Dim.x)},
      tooltip: _tt,
    );
  }

  Widget _aLineaCrosshair(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [LineMark(color: ColorEncode(value: C.neon))],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
      selections: {'tap': PointSelection(dim: Dim.x)},
      crosshair: CrosshairGuide(followPointer: const [true, false]),
      tooltip: _tt,
    );
  }

  Widget _aDosLineas(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return Chart(
      data: _valorProm(ds),
      variables: _varsSerie(),
      marks: [
        LineMark(
          position: Varset('nombre') * Varset('valor') / Varset('serie'),
          color: ColorEncode(variable: 'serie', values: [C.neon, C.red]),
          size: SizeEncode(value: 2.5),
          shape: ShapeEncode(value: BasicLineShape(smooth: true)),
        ),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
      selections: {'tap': PointSelection(dim: Dim.x)},
      tooltip: _tt,
    );
  }

  Widget _aEtiquetasPunto(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.label_outline);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [
        PointMark(
          color: ColorEncode(value: C.neon),
          size: SizeEncode(value: 6),
          label: LabelEncode(
            encoder: (t) => Label(t['valor'].toString(), LabelStyle(textStyle: _lbl)),
          ),
        ),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
      selections: {'tap': PointSelection(dim: Dim.x)},
      tooltip: _tt,
    );
  }

  Widget _aTag(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.emoji_flags_outlined);
    final top = ds.reduce((a, b) => a.valor > b.valor ? a : b);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [IntervalMark(color: ColorEncode(value: C.dim))],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
      annotations: [
        TagAnnotation(
          label: Label(
            'Máx ${_fmt(top.valor)}',
            LabelStyle(
              textStyle: const TextStyle(
                color: C.neon,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          values: [top.nombre, top.valor],
        ),
      ],
    );
  }

  Widget _aLineaAnimada(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [
        LineMark(
          color: ColorEncode(value: C.neon),
          transition: Transition(duration: const Duration(milliseconds: 1100)),
          entrance: const {MarkEntrance.x, MarkEntrance.opacity},
          tag: (t) => t['nombre'].toString(),
        ),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
    );
  }

  Widget _aLineaGradiente(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [
        LineMark(
          size: SizeEncode(value: 3),
          gradient: GradientEncode(
            value: const LinearGradient(
              colors: [Color(0xFF39FF14), Color(0xFFFF6B6B)],
            ),
          ),
        ),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
      selections: {'tap': PointSelection(dim: Dim.x)},
      tooltip: _tt,
    );
  }

  Widget _aAreaApilada(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.area_chart_outlined);
    return Chart(
      data: _valorResto(ds),
      variables: _varsSerie(),
      marks: [
        AreaMark(
          position: Varset('nombre') * Varset('valor') / Varset('serie'),
          color: ColorEncode(
            variable: 'serie',
            values: [C.neon.withValues(alpha: .55), C.dim.withValues(alpha: .55)],
          ),
          modifiers: [StackModifier()],
        ),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
      selections: {'tap': PointSelection(dim: Dim.x)},
      tooltip: _tt,
    );
  }

  Widget _aStream(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.waves_outlined);
    return Chart(
      data: _valorResto(ds),
      variables: _varsSerie(),
      marks: [
        AreaMark(
          position: Varset('nombre') * Varset('valor') / Varset('serie'),
          shape: ShapeEncode(value: BasicAreaShape(smooth: true)),
          color: ColorEncode(variable: 'serie', values: Defaults.colors10),
          modifiers: [StackModifier(), SymmetricModifier()],
        ),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
      selections: {'tap': PointSelection(dim: Dim.x)},
      tooltip: _tt,
    );
  }

  Widget _aAreaGradiente(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.area_chart_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [
        AreaMark(
          gradient: GradientEncode(
            value: LinearGradient(
              colors: [
                C.neon.withValues(alpha: .7),
                C.neon.withValues(alpha: .05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
      selections: {'tap': PointSelection(dim: Dim.x)},
      tooltip: _tt,
    );
  }

  Widget _aRegionArea(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.area_chart_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [
        AreaMark(
          color: ColorEncode(value: C.neon.withValues(alpha: .3)),
          shape: ShapeEncode(value: BasicAreaShape(stepped: true)),
        ),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
      annotations: [
        RegionAnnotation(
          dim: Dim.x,
          variable: 'nombre',
          values: [ds.first.nombre, ds.last.nombre],
          gradient: LinearGradient(
            colors: [C.red.withValues(alpha: 0), C.red.withValues(alpha: .25)],
          ),
        ),
      ],
      selections: {'tap': PointSelection(dim: Dim.x)},
      tooltip: _tt,
    );
  }

  Widget _aPuntosTouch(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.scatter_plot_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [
        PointMark(
          shape: ShapeEncode(value: CircleShape(hollow: true)),
          size: SizeEncode(value: 10),
          color: ColorEncode(value: C.neon),
        ),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
      selections: {'tap': PointSelection(dim: Dim.x)},
      tooltip: _tt,
    );
  }

  Widget _aJitter(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.blur_on);
    return Chart(
      data: _valorProm(ds),
      variables: _varsSerie(),
      marks: [
        PointMark(
          position: Varset('nombre') * Varset('valor') / Varset('serie'),
          color: ColorEncode(variable: 'serie', values: [C.neon, C.red]),
          size: SizeEncode(value: 9),
          modifiers: [JitterModifier(ratio: 0.6)],
        ),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
      selections: {'tap': PointSelection(dim: Dim.x)},
      tooltip: _tt,
    );
  }

  Widget _aBurbujaTouch(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bubble_chart_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [
        PointMark(
          size: SizeEncode(variable: 'valor', values: [5, 28]),
          color: ColorEncode(value: C.neon.withValues(alpha: .8)),
        ),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
      selections: {'tap': PointSelection(dim: Dim.x)},
      tooltip: _tt,
    );
  }

  Widget _aPastelTouch(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.pie_chart_outline);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      transforms: [Proportion(variable: 'valor', as: 'parte')],
      marks: [
        IntervalMark(
          position: Varset('parte') / Varset('nombre'),
          color: ColorEncode(variable: 'nombre', values: Defaults.colors10),
          modifiers: [StackModifier()],
        ),
      ],
      coord: PolarCoord(transposed: true, dimCount: 1),
      axes: [Defaults.circularAxis],
      selections: {'tap': PointSelection()},
      tooltip: _tt,
    );
  }

  Widget _aDonaGradiente(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.donut_large_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      transforms: [Proportion(variable: 'valor', as: 'parte')],
      marks: [
        IntervalMark(
          position: Varset('parte') / Varset('nombre'),
          gradient: GradientEncode(
            value: const LinearGradient(
              colors: [Color(0xFF39FF14), Color(0xFF22D3EE)],
            ),
          ),
          modifiers: [StackModifier()],
        ),
      ],
      coord: PolarCoord(transposed: true, dimCount: 1, startRadius: 0.45),
      axes: [Defaults.circularAxis],
    );
  }

  Widget _aPastelPorcentaje(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.pie_chart_outline);
    final t = _tot(ds);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      transforms: [Proportion(variable: 'valor', as: 'parte')],
      marks: [
        IntervalMark(
          position: Varset('parte') / Varset('nombre'),
          color: ColorEncode(variable: 'nombre', values: Defaults.colors10),
          modifiers: [StackModifier()],
          label: LabelEncode(
            encoder: (r) => Label(
              '${((r['valor'] as num) / t * 100).toStringAsFixed(0)}%',
              LabelStyle(textStyle: const TextStyle(color: C.text, fontSize: 9)),
            ),
          ),
        ),
      ],
      coord: PolarCoord(transposed: true, dimCount: 1, startRadius: 0.35),
      axes: [Defaults.circularAxis],
      selections: {'tap': PointSelection()},
      tooltip: _tt,
    );
  }

  Widget _aRosaTouch(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.local_florist_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [
        IntervalMark(
          shape: ShapeEncode(
            value: RectShape(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
          ),
          color: ColorEncode(variable: 'nombre', values: Defaults.colors10),
        ),
      ],
      coord: PolarCoord(startRadius: 0.15),
      axes: [Defaults.circularAxis, Defaults.radialAxis],
      selections: {'tap': PointSelection()},
      tooltip: _tt,
    );
  }

  Widget _aEmbudoPorcentaje(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.filter_alt_outlined);
    final t = _tot(ds);
    final s = [...ds]..sort((a, b) => b.valor.compareTo(a.valor));
    return Chart(
      data: _rows(s),
      variables: _vars(),
      marks: [
        IntervalMark(
          shape: ShapeEncode(value: FunnelShape(labelPosition: 0.4)),
          color: ColorEncode(variable: 'nombre', values: Defaults.colors10),
          label: LabelEncode(
            encoder: (r) => Label(
              '${r['nombre']} · ${((r['valor'] as num) / t * 100).toStringAsFixed(0)}%',
              LabelStyle(textStyle: const TextStyle(color: C.text, fontSize: 9)),
            ),
          ),
        ),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
      selections: {'tap': PointSelection(dim: Dim.x)},
      tooltip: _tt,
    );
  }

  Widget _aCalorTouch(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.grid_on_outlined);
    return Chart(
      data: _valorResto(ds),
      variables: _varsSerie(),
      marks: [
        PolygonMark(
          color: ColorEncode(
            variable: 'valor',
            values: [Color(0xFF12331A), Color(0xFF39FF14)],
          ),
        ),
      ],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
      selections: {'tap': PointSelection(dim: Dim.x)},
      tooltip: _tt,
    );
  }

  Widget _aDobleEje(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.swap_vert_outlined);
    return Chart(
      data: _dosEjes(ds),
      variables: {
        'nombre': Variable(accessor: (Map m) => m['nombre'] as String),
        'valor': Variable(
          accessor: (Map m) => m['valor'] as num,
          scale: LinearScale(min: 0, niceRange: true),
        ),
        'promedio': Variable(
          accessor: (Map m) => m['promedio'] as num,
          scale: LinearScale(min: 0, max: _maxV(ds) * 1.2, tickCount: 4),
        ),
      },
      marks: [IntervalMark(color: ColorEncode(value: C.neon))],
      axes: [
        Defaults.horizontalAxis,
        Defaults.verticalAxis,
        AxisGuide(
          dim: Dim.y,
          variable: 'promedio',
          position: 1,
          flip: true,
          line: PaintStyle(strokeColor: C.red),
          label: LabelStyle(textStyle: const TextStyle(color: C.red, fontSize: 9)),
        ),
      ],
      selections: {'tap': PointSelection(dim: Dim.x)},
      tooltip: _tt,
    );
  }

  Widget _aIntervalo(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.compare_arrows_outlined);
    return Chart(
      data: _rows(ds),
      variables: _vars(),
      marks: [LineMark(color: ColorEncode(value: C.neon))],
      axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
      selections: {
        'brush': IntervalSelection(
          dim: Dim.x,
          color: C.neon.withValues(alpha: .15),
        ),
      },
      tooltip: TooltipGuide(
        selections: const {'brush'},
        backgroundColor: C.card2,
        radius: const Radius.circular(6),
        textStyle: const TextStyle(color: C.text, fontSize: 11),
      ),
    );
  }

  // ══════════════════ LISTADOS ══════════════════

  List<(String, String, Widget)> _basicas(StatsData d) => [
    (
      'B01 · Barras verticales',
      'Cuántos personajes están vivos, muertos o con estado desconocido.',
      _bBarras(d.status),
    ),
    (
      'B02 · Barras redondeadas',
      'El reparto de personajes por estado de vida o muerte.',
      _bRedondas(d.status),
    ),
    (
      'B03 · Barras con etiquetas',
      'Cuántos episodios tiene cada temporada, con su número sobre cada columna.',
      _bEtiquetas(d.epsPorTemporada),
    ),
    (
      'B04 · Barras horizontales',
      'Las ubicaciones o planetas donde más personajes se encuentran.',
      _bHorizontales(d.location),
    ),
    (
      'B05 · Barras multicolor',
      'Cuántos personajes hay de cada especie (Human, Alien, Robot...).',
      _bMulticolor(d.species),
    ),
    (
      'B06 · Barras sin ejes',
      'Cuántos personajes son hombres, mujeres, sin género o desconocidos.',
      _bSinEjes(d.gender),
    ),
    (
      'B07 · Barras eje fijo',
      'Cuántos personajes aparecen en 1, 2-5, 6-10 o más de 10 episodios.',
      _bEjeFijo(d.epsPorPersonaje),
    ),
    (
      'B08 · Barras ejes custom',
      'Cuántos personajes aparecen en cada uno de los primeros episodios.',
      _bEjesCustom(d.charsPorEpisodio),
    ),
    (
      'B09 · Barras finas',
      'De qué planetas vienen los personajes: los orígenes más comunes.',
      _bFina(d.origin),
    ),
    (
      'B10 · Línea',
      'Cuántos episodios tiene cada temporada de la serie.',
      _bLinea(d.epsPorTemporada),
    ),
    (
      'B11 · Línea suave',
      'Cuántos episodios se estrenaron cada año, año tras año.',
      _bLineaSuave(d.epsPorAnio),
    ),
    (
      'B12 · Línea escalonada',
      'Cuántos episodios tiene cada temporada, marcando cada salto entre una y otra.',
      _bLineaEscalon(d.epsPorTemporada),
    ),
    (
      'B13 · Línea punteada',
      'Cuántos episodios se estrenaron en cada año.',
      _bLineaPunteada(d.epsPorAnio),
    ),
    (
      'B14 · Línea con puntos',
      'Los personajes con más episodios de la serie (top del ranking).',
      _bLineaPuntos(d.topPersonajesEps),
    ),
    (
      'B15 · Línea de fechas',
      'Cuántos episodios se estrenaron cada año, con el año real en el eje.',
      _bFecha(d),
    ),
    (
      'B16 · Área',
      'Cuántos episodios tiene cada temporada, con el volumen total bajo la curva.',
      _bArea(d.epsPorTemporada),
    ),
    (
      'B17 · Área suave',
      'Cuántos episodios se estrenaron cada año, resaltando el volumen acumulado.',
      _bAreaSuave(d.epsPorAnio),
    ),
    (
      'B18 · Área escalonada',
      'Cuántos episodios tiene cada temporada, mostrando el salto de una a otra.',
      _bAreaEscalon(d.epsPorTemporada),
    ),
    (
      'B19 · Dispersión',
      'Cuántos personajes aparecen en cada uno de los primeros episodios.',
      _bPuntos(d.charsPorEpisodio),
    ),
    (
      'B20 · Puntos huecos',
      'Cuántos personajes tienen 1, 2-5, 6-10 o más de 10 episodios.',
      _bPuntoHueco(d.epsPorPersonaje),
    ),
    (
      'B21 · Puntos cuadrados',
      'Cuántos episodios tiene cada temporada, punto por temporada.',
      _bCuadrado(d.epsPorTemporada),
    ),
    (
      'B22 · Burbuja',
      'Cuántos personajes hay de cada especie; cuanto más grande la burbuja, más personajes.',
      _bBurbuja(d.species),
    ),
    (
      'B23 · Pastel',
      'Qué proporción de personajes pertenece a cada especie.',
      _bPastel(d.species),
    ),
    (
      'B24 · Dona',
      'Cómo se reparten los episodios de la serie entre las temporadas.',
      _bDona(d.epsPorTemporada),
    ),
    (
      'B25 · Media luna',
      'Cuántos personajes están vivos, muertos o con estado desconocido.',
      _bMediaLuna(d.status),
    ),
    (
      'B26 · Pastel con etiquetas',
      'Cuántos personajes son hombres, mujeres, sin género o desconocidos, con el nombre de cada grupo.',
      _bPastelEtiquetas(d.gender),
    ),
    (
      'B27 · Rosa',
      'Cuántos episodios tiene cada temporada, con pétalos de distinto largo.',
      _bRosa(d.epsPorTemporada),
    ),
    (
      'B28 · Rosa redondeada',
      'Las especies más comunes entre los personajes, con pétalos suaves.',
      _bRosaRedonda(d.species),
    ),
    (
      'B29 · Embudo',
      'Las ubicaciones con más personajes, de la más común a la menos común.',
      _bEmbudo(d.location),
    ),
    (
      'B30 · Pirámide',
      'De qué planetas vienen los personajes, de la mayoría a la minoría.',
      _bPiramide(d.origin),
    ),
    (
      'B31 · Mapa de calor',
      'Cuántos personajes hay por estado; a más brillo del color, más personajes.',
      _bCalor(d.status),
    ),
  ];

  List<(String, String, Widget)> _avanzadas(StatsData d) => [
    (
      'A01 · Columnas con tooltip',
      'Cuántos personajes están vivos, muertos o desconocidos; toca una columna para ver su valor.',
      _aTooltip(d.status),
    ),
    (
      'A02 · Columnas con crosshair',
      'Las especies más comunes; pasa el dedo para leer el valor exacto de cada una.',
      _aCrosshair(d.species),
    ),
    (
      'A03 · Columnas agrupadas',
      'De qué planetas vienen los personajes, con los de cada origen lado a lado.',
      _aAgrupadas(d.origin),
    ),
    (
      'A04 · Columnas apiladas',
      'Las ubicaciones más comunes: cuántos personajes viven en cada una y cuántos en el resto.',
      _aApiladas(d.location),
    ),
    (
      'A05 · Columnas con degradado',
      'Cuántos episodios tiene cada temporada, resaltando la temporada más larga.',
      _aDegradado(d.epsPorTemporada),
    ),
    (
      'A06 · Columnas ordenadas',
      'Las especies ordenadas de la más común a la menos común.',
      _aOrdenada(d.species),
    ),
    (
      'A07 · Línea con objetivo',
      'Cuántos episodios tiene cada temporada contra su promedio de la serie.',
      _aObjetivo(d.epsPorTemporada),
    ),
    (
      'A08 · Columnas con región',
      'Cuántos episodios se estrenaron cada año, marcando todo el rango de años de la serie.',
      _aRegion(d.epsPorAnio),
    ),
    (
      'A09 · Columnas animadas',
      'Cuántos episodios tiene cada temporada, presentados al entrar en pantalla.',
      _aAnimada(d.epsPorTemporada),
    ),
    (
      'A10 · Barras horizontales con tooltip',
      'Las ubicaciones con más personajes; toca una barra para ver cuántos hay en cada una.',
      _aHorizTouch(d.location),
    ),
    (
      'A11 · Línea con tooltip',
      'Cuántos episodios se estrenaron cada año; toca un año para ver su cifra exacta.',
      _aLineaTooltip(d.epsPorAnio),
    ),
    (
      'A12 · Línea con crosshair',
      'Cuántos episodios se estrenaron cada año; la guía sigue al dedo por el eje.',
      _aLineaCrosshair(d.epsPorAnio),
    ),
    (
      'A13 · Dos líneas',
      'Cuántos episodios tiene cada temporada frente a su promedio de la serie.',
      _aDosLineas(d.epsPorTemporada),
    ),
    (
      'A14 · Puntos con etiquetas',
      'Cuántos episodios tiene cada temporada, con el valor impreso en cada punto.',
      _aEtiquetasPunto(d.epsPorTemporada),
    ),
    (
      'A15 · Anotación de máximo',
      'La temporada con más episodios de la serie, señalada por su nombre.',
      _aTag(d.epsPorTemporada),
    ),
    (
      'A16 · Línea animada',
      'Cuántos episodios se estrenaron cada año, trazándose al entrar en pantalla.',
      _aLineaAnimada(d.epsPorAnio),
    ),
    (
      'A17 · Línea con degradado',
      'Cuántos episodios tiene cada temporada, del valor más alto al más bajo.',
      _aLineaGradiente(d.epsPorTemporada),
    ),
    (
      'A18 · Área apilada',
      'De qué planetas vienen los personajes, sumando cada origen sobre el resto.',
      _aAreaApilada(d.origin),
    ),
    (
      'A19 · Stream',
      'Las especies más comunes, reflejadas hacia arriba y abajo del centro.',
      _aStream(d.species),
    ),
    (
      'A20 · Área con degradado',
      'Cuántos episodios se estrenaron cada año, con más intensidad en los años altos.',
      _aAreaGradiente(d.epsPorAnio),
    ),
    (
      'A21 · Área con región',
      'Cuántos episodios se estrenaron cada año, con el rango completo de años sombreado.',
      _aRegionArea(d.epsPorAnio),
    ),
    (
      'A22 · Dispersión con tooltip',
      'Cuántos personajes aparecen en cada episodio; toca un punto para ver su valor.',
      _aPuntosTouch(d.charsPorEpisodio),
    ),
    (
      'A23 · Dispersión con jitter',
      'Cuántos episodios tiene cada temporada, separando los puntos que caen en el mismo nivel.',
      _aJitter(d.epsPorTemporada),
    ),
    (
      'A24 · Burbuja con tooltip',
      'Cuántos personajes hay de cada especie; toca una burbuja para ver la cifra.',
      _aBurbujaTouch(d.species),
    ),
    (
      'A25 · Pastel con tooltip',
      'Cuántos episodios tiene cada temporada; toca una porción para verla destacada.',
      _aPastelTouch(d.epsPorTemporada),
    ),
    (
      'A26 · Dona con degradado',
      'De qué planetas vienen los personajes, en un anillo de color variable.',
      _aDonaGradiente(d.origin),
    ),
    (
      'A27 · Pastel con porcentaje',
      'Qué porcentaje de personajes está vivo, muerto o con estado desconocido.',
      _aPastelPorcentaje(d.status),
    ),
    (
      'A28 · Rosa con tooltip',
      'Las especies más comunes; toca un pétalo para ver cuántos personajes hay.',
      _aRosaTouch(d.species),
    ),
    (
      'A29 · Embudo con porcentaje',
      'Qué porcentaje del total de personajes vive en cada ubicación, de la más común a la menos.',
      _aEmbudoPorcentaje(d.location),
    ),
    (
      'A30 · Mapa de calor con tooltip',
      'Cuántos personajes hay por estado; toca una celda para ver la cifra exacta.',
      _aCalorTouch(d.status),
    ),
    (
      'A31 · Doble eje',
      'Cuántos episodios tiene cada temporada contra su promedio, cada uno en su propio eje.',
      _aDobleEje(d.epsPorTemporada),
    ),
    (
      'A32 · Selección de rango',
      'Cuántos episodios se estrenaron cada año; arrastra para elegir un tramo de años y verlo en detalle.',
      _aIntervalo(d.epsPorAnio),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('graphic', style: T.title)),
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
