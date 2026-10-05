// ─── Pantalla 3/4: d_chart ────────────────────────────────────────
// SOLO importa d_chart (la más simple de usar, basada en
// community_charts).
// BÁSICAS = una variante visual por familia, sin animación, sin
// degradados y con un solo grupo de datos.
// AVANZADAS = animación, selección táctil, degradados, multi-serie,
// apiladas, eje secundario, viewport/zoom y dominio temporal.
// Ninguna repite estructura ni presentación con otra de esta pantalla.

import 'dart:math';

import 'package:d_chart/d_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/adaptive.dart';
import '../../core/theme.dart';
import '../../data/api.dart';
import '../../data/stats_service.dart';
import '../widgets/chart_viewer.dart';
import '../widgets/common.dart';

class ChartDScreen extends StatefulWidget {
  const ChartDScreen({super.key});
  @override
  State<ChartDScreen> createState() => _ChartDScreenState();
}

class _ChartDScreenState extends State<ChartDScreen> {
  Future<StatsData>? _fut;
  int _basic = 0;
  int _adv = 0;
  final _svc = StatsService();
  String? _tocado; // último dato seleccionado (A02)

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fut ??= _svc.load(context.read<Api>());
  }

  // ── Paleta ──
  static const _cols = [
    Color(0xFF39FF14),
    Color(0xFF22D3EE),
    Color(0xFFFBBF24),
    Color(0xFFF472B6),
    Color(0xFFA78BFA),
    Color(0xFFFF6B6B),
    Color(0xFF4ADE80),
    Color(0xFF38BDF8),
  ];
  Color _c(int i) => _cols[i % _cols.length];

  // ── Ejes por defecto (oscuros) ──
  DomainAxisO get _dom => const DomainAxisO(
    labelStyle: LabelStyle(color: C.muted, fontSize: 10),
    axisLineStyle: LineStyle(color: C.line),
    tickLineStyle: LineStyle(color: C.line),
  );

  DomainAxisN get _domN => const DomainAxisN(
    labelStyle: LabelStyle(color: C.muted, fontSize: 10),
    axisLineStyle: LineStyle(color: C.line),
    tickLineStyle: LineStyle(color: C.line),
  );

  MeasureAxis get _med => const MeasureAxis(
    labelStyle: LabelStyle(color: C.muted, fontSize: 10),
    axisLineStyle: LineStyle(color: C.line),
    tickLineStyle: LineStyle(color: C.line),
    gridlineStyle: LineStyle(color: C.line),
  );

  MeasureAxis get _medGrid => MeasureAxis(
    labelStyle: const LabelStyle(color: C.muted, fontSize: 10),
    axisLineStyle: const LineStyle(color: C.line),
    tickLineStyle: const LineStyle(color: C.line),
    gridlineStyle: const LineStyle(color: C.line),
    axisRenderType: AxisRenderType.gridline,
  );

  // ── Datos ──
  List<OrdinalData> _ord(List<Dato> ds) => [
    for (final d in ds) OrdinalData(domain: d.nombre, measure: d.valor),
  ];

  List<NumericData> _num(List<Dato> ds) => [
    for (var i = 0; i < ds.length; i++)
      NumericData(domain: i + 1, measure: ds[i].valor),
  ];

  List<Dato> _anios(StatsData d) =>
      [...d.epsPorAnio]..sort((a, b) => a.nombre.compareTo(b.nombre));

  List<TimeData> _time(StatsData d) => [
    for (final x in _anios(d))
      TimeData(
        domain: DateTime(int.tryParse(x.nombre) ?? 2013),
        measure: x.valor,
      ),
  ];

  int _y0(StatsData d) {
    final a = _anios(d);
    return a.isEmpty ? 2013 : (int.tryParse(a.first.nombre) ?? 2013);
  }

  double _prom(List<Dato> ds) {
    if (ds.isEmpty) return 0;
    var s = 0.0;
    for (final d in ds) {
      s += d.valor;
    }
    return s / ds.length;
  }

  double _maxV(List<Dato> ds) {
    var m = 0.0;
    for (final d in ds) {
      if (d.valor > m) m = d.valor;
    }
    return m;
  }

  // Dos series: valor y resto del total (para apiladas y agrupadas).
  List<OrdinalGroup> _par(List<Dato> ds) {
    var t = 0.0;
    for (final d in ds) {
      t += d.valor;
    }
    return [
      OrdinalGroup(id: 'valor', data: _ord(ds)),
      OrdinalGroup(
        id: 'resto',
        data: [
          for (final d in ds) OrdinalData(domain: d.nombre, measure: t - d.valor),
        ],
      ),
    ];
  }

  Color _colorGrupo(String id) =>
      id == 'valor' ? C.neon : (id == 'prom' ? C.red : C.dim);

  Widget _vacio(IconData i) =>
      Nada(icon: i, title: 'Sin datos', body: 'Reintenta.');

  // ══════════════════════ BÁSICAS ══════════════════════

  Widget _bBarras(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return DChartBarO(
      groupList: [OrdinalGroup(id: 'v', data: _ord(ds))],
      domainAxis: _dom,
      measureAxis: _med,
      configSeriesBar: ConfigSeriesBarO(seriesColor: C.neon),
    );
  }

  Widget _bRedondas(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return DChartBarO(
      groupList: [OrdinalGroup(id: 'v', data: _ord(ds))],
      domainAxis: _dom,
      measureAxis: _med,
      configSeriesBar: ConfigSeriesBarO(seriesColor: C.neon, cornerRadius: 12),
    );
  }

  Widget _bEtiquetas(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return DChartBarO(
      groupList: [OrdinalGroup(id: 'v', data: _ord(ds))],
      domainAxis: _dom,
      measureAxis: _med,
      configSeriesBar: ConfigSeriesBarO(
        seriesColor: C.neon,
        showBarLabel: true,
        labelAccessor: (g, d, i) => d.measure?.toStringAsFixed(0) ?? '',
        barLabelDecorator: const BarLabelDecoratorO(
          outsideLabelStyle: LabelStyle(color: C.text, fontSize: 10),
        ),
      ),
    );
  }

  Widget _bHorizontales(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.view_week_outlined);
    return DChartBarO(
      arrangeVertically: true,
      groupList: [OrdinalGroup(id: 'v', data: _ord(ds))],
      domainAxis: _dom,
      measureAxis: _med,
      configSeriesBar: ConfigSeriesBarO(seriesColor: C.neon),
    );
  }

  Widget _bMulticolor(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return DChartBarO(
      groupList: [OrdinalGroup(id: 'v', data: _ord(ds))],
      domainAxis: _dom,
      measureAxis: _med,
      configSeriesBar: ConfigSeriesBarO(customColor: (g, d, i) => _c(i ?? 0)),
    );
  }

  Widget _bFina(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return DChartBarO(
      groupList: [OrdinalGroup(id: 'v', data: _ord(ds))],
      domainAxis: _dom,
      measureAxis: _med,
      configSeriesBar: ConfigSeriesBarO(
        seriesColor: C.neon,
        maxBarWidthPx: 8,
      ),
    );
  }

  Widget _bTrama(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return DChartBarO(
      groupList: [OrdinalGroup(id: 'v', data: _ord(ds))],
      domainAxis: _dom,
      measureAxis: _med,
      configSeriesBar: ConfigSeriesBarO(
        seriesColor: C.neon,
        fillPatternBase: FillPattern.forwarHatch,
      ),
    );
  }

  Widget _bGridline(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return DChartBarO(
      groupList: [OrdinalGroup(id: 'v', data: _ord(ds))],
      domainAxis: _dom,
      measureAxis: _medGrid,
      configSeriesBar: ConfigSeriesBarO(seriesColor: C.neon),
    );
  }

  Widget _bSinEje(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return DChartBarO(
      groupList: [OrdinalGroup(id: 'v', data: _ord(ds))],
      domainAxis: const DomainAxisO(noRenderSpec: true),
      measureAxis: _med,
      configSeriesBar: ConfigSeriesBarO(seriesColor: C.neon),
    );
  }

  Widget _bEjeRotado(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return DChartBarO(
      groupList: [OrdinalGroup(id: 'v', data: _ord(ds))],
      domainAxis: DomainAxisO(
        labelRotation: -45,
        labelStyle: const LabelStyle(color: C.muted, fontSize: 10),
        axisLineStyle: const LineStyle(color: C.line),
      ),
      measureAxis: _med,
      configSeriesBar: ConfigSeriesBarO(seriesColor: C.neon),
    );
  }

  Widget _bVentana(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    final n = ds.length < 4 ? ds.length : 4;
    return DChartBarO(
      groupList: [OrdinalGroup(id: 'v', data: _ord(ds))],
      domainAxis: DomainAxisO(
        viewport: OrdinalViewport(startingDomain: ds.first.nombre, dataSize: n),
        labelStyle: const LabelStyle(color: C.muted, fontSize: 10),
        axisLineStyle: const LineStyle(color: C.line),
      ),
      measureAxis: _med,
      configSeriesBar: ConfigSeriesBarO(seriesColor: C.neon),
    );
  }

  Widget _bLinea(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return DChartLineN(
      groupList: [NumericGroup(id: 'l', data: _num(ds))],
      domainAxis: _domN,
      measureAxis: _med,
      configSeriesLine: ConfigSeriesLineN(seriesColor: C.neon),
    );
  }

  Widget _bLineaPuntos(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return DChartLineN(
      groupList: [NumericGroup(id: 'l', data: _num(ds))],
      domainAxis: _domN,
      measureAxis: _med,
      configSeriesLine: ConfigSeriesLineN(
        seriesColor: C.neon,
        includePoints: true,
        pointRadiusBase: 4,
      ),
    );
  }

  Widget _bLineaArea(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.area_chart_outlined);
    return DChartLineN(
      groupList: [NumericGroup(id: 'l', data: _num(ds))],
      domainAxis: _domN,
      measureAxis: _med,
      configSeriesLine: ConfigSeriesLineN(
        seriesColor: C.neon,
        includeArea: true,
        areaOpacity: .3,
      ),
    );
  }

  Widget _bLineaPunteada(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return DChartLineN(
      groupList: [NumericGroup(id: 'l', data: _num(ds))],
      domainAxis: _domN,
      measureAxis: _med,
      configSeriesLine: ConfigSeriesLineN(
        seriesColor: C.neon,
        dashPatternBase: [6, 6],
      ),
    );
  }

  Widget _bLineaGruesa(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return DChartLineN(
      groupList: [NumericGroup(id: 'l', data: _num(ds))],
      domainAxis: _domN,
      measureAxis: _med,
      configSeriesLine: ConfigSeriesLineN(
        seriesColor: C.neon,
        strokeWidthPxBase: 4,
        roundEndCaps: true,
      ),
    );
  }

  Widget _bLineaEtiquetas(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.label_outline);
    return DChartLineN(
      groupList: [NumericGroup(id: 'l', data: _num(ds))],
      domainAxis: _domN,
      measureAxis: _med,
      configSeriesLine: ConfigSeriesLineN(
        seriesColor: C.neon,
        includePoints: true,
        pointRadiusBase: 4,
        includePointLabel: true,
        pointLabelDecorator: const PointLabelDecoratorN(
          labelStyle: LabelStyle(color: C.muted, fontSize: 9),
        ),
      ),
    );
  }

  Widget _bDispersion(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.scatter_plot_outlined);
    return DChartScatterN(
      groupList: [NumericGroup(id: 's', data: _num(ds))],
      domainAxis: _domN,
      measureAxis: _med,
      configSeriesScatter: ConfigSeriesScatterN(
        seriesColor: C.neon,
        pointRadiusBase: 6,
      ),
    );
  }

  Widget _bDispCuadrada(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.scatter_plot_outlined);
    return DChartScatterN(
      groupList: [NumericGroup(id: 's', data: _num(ds))],
      domainAxis: _domN,
      measureAxis: _med,
      configSeriesScatter: ConfigSeriesScatterN(
        seriesColor: C.neon,
        symbolRender: const SymbolRenderRect(),
        pointRadiusBase: 7,
      ),
    );
  }

  Widget _bDispTriangular(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.scatter_plot_outlined);
    return DChartScatterN(
      groupList: [NumericGroup(id: 's', data: _num(ds))],
      domainAxis: _domN,
      measureAxis: _med,
      configSeriesScatter: ConfigSeriesScatterN(
        seriesColor: C.neon,
        symbolRender: const SymbolRenderTriangle(),
        pointRadiusBase: 7,
      ),
    );
  }

  Widget _bDispHueca(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.scatter_plot_outlined);
    return DChartScatterN(
      groupList: [NumericGroup(id: 's', data: _num(ds))],
      domainAxis: _domN,
      measureAxis: _med,
      configSeriesScatter: ConfigSeriesScatterN(
        seriesColor: C.neon,
        symbolRender: const SymbolRenderCircle(isSolid: false),
        strokeWidthBase: 2,
        pointRadiusBase: 8,
      ),
    );
  }

  Widget _bComboBarraLinea(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return DChartComboO(
      groupList: [
        OrdinalGroup(id: 'b', data: _ord(ds)),
        OrdinalGroup(id: 'l', data: _ord(ds)),
      ],
      renderType: (g) => g.id == 'b' ? RenderType.bar : RenderType.line,
      domainAxis: _dom,
      measureAxis: _med,
      configSeriesBar: ConfigSeriesBarO(seriesColor: C.dim),
      configSeriesLine: ConfigSeriesLineO(seriesColor: C.neon),
    );
  }

  Widget _bComboLineaPunto(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return DChartComboO(
      groupList: [
        OrdinalGroup(id: 'l', data: _ord(ds)),
        OrdinalGroup(id: 'p', data: _ord(ds)),
      ],
      renderType: (g) => g.id == 'l' ? RenderType.line : RenderType.scatterPlot,
      domainAxis: _dom,
      measureAxis: _med,
      configSeriesLine: ConfigSeriesLineO(
        seriesColor: C.neon,
        strokeWidthPxBase: 2,
      ),
      configSeriesScatter: ConfigSeriesScatterO(
        seriesColor: C.red,
        pointRadiusBase: 6,
      ),
    );
  }

  Widget _bPastel(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.pie_chart_outline);
    return DChartPieO(
      data: _ord(ds),
      configSeriesPie: ConfigSeriesPieO(customColor: (g, d, i) => _c(i ?? 0)),
    );
  }

  Widget _bPastelEtiquetas(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.pie_chart_outline);
    return DChartPieO(
      data: _ord(ds),
      configSeriesPie: ConfigSeriesPieO(
        customColor: (g, d, i) => _c(i ?? 0),
        showLabel: true,
        labelAccessor: (g, d, i) => d.domain,
        arcLabelDecorator: const ArcLabelDecoratorO(
          insideLabelStyle: LabelStyle(color: C.card, fontSize: 10),
          outsideLabelStyle: LabelStyle(color: C.text, fontSize: 10),
        ),
      ),
    );
  }

  Widget _bDona(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.donut_large_outlined);
    return DChartPieO(
      data: _ord(ds),
      configSeriesPie: ConfigSeriesPieO(
        customColor: (g, d, i) => _c(i ?? 0),
        arcRatio: 0.55,
      ),
    );
  }

  Widget _bMediaLuna(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.pie_chart_outline);
    return DChartPieO(
      data: _ord(ds),
      configSeriesPie: ConfigSeriesPieO(
        customColor: (g, d, i) => _c(i ?? 0),
        arcLength: pi,
      ),
    );
  }

  Widget _bPastelDerecha(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.pie_chart_outline);
    return DChartPieO(
      data: _ord(ds),
      configSeriesPie: ConfigSeriesPieO(
        customColor: (g, d, i) => _c(i ?? 0),
        startAngle: 0,
      ),
    );
  }

  Widget _bLane(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.linear_scale_outlined);
    return DChartBarO(
      renderType: (g) => RenderType.barLane,
      groupList: [OrdinalGroup(id: 'v', data: _ord(ds))],
      domainAxis: _dom,
      measureAxis: _med,
      configSeriesBarLane: ConfigSeriesBarLaneO(
        seriesColor: C.neon,
        backgroundBarColor: C.card2,
        cornerRadius: 6,
      ),
    );
  }

  Widget _bTarget(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return DChartBarO(
      renderType: (g) => RenderType.barTargetLine,
      groupList: [OrdinalGroup(id: 'v', data: _ord(ds))],
      domainAxis: _dom,
      measureAxis: _med,
      configSeriesBarTargetLine: ConfigSeriesBarTargetLineO(
        strokeWidthPx: (g, d, i) => 4,
        roundEndCaps: false,
        customColor: (g, d, i) => C.neon,
      ),
    );
  }

  Widget _bApiladas(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.stacked_bar_chart_outlined);
    return DChartBarO(
      groupList: _par(ds),
      domainAxis: _dom,
      measureAxis: _med,
      configSeriesBar: ConfigSeriesBarO(
        barGroupingType: BarGroupingType.stacked,
        customColor: (g, d, i) => _colorGrupo(g.id),
        stackedBarPaddingPx: 0,
      ),
    );
  }

  // ══════════════════════ AVANZADAS ══════════════════════

  Widget _aAnimDegradado(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return DChartBarO(
      animate: true,
      animationDuration: const Duration(milliseconds: 900),
      groupList: [OrdinalGroup(id: 'v', data: _ord(ds))],
      domainAxis: _dom,
      measureAxis: _med,
      configSeriesBar: ConfigSeriesBarO(
        fillGradient: (g, d, i) => const LinearGradient(
          colors: [Color(0xFF39FF14), Color(0xFF22D3EE)],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
    );
  }

  Widget _aSeleccion(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.touch_app_outlined);
    return Column(
      children: [
        Expanded(
          child: DChartBarO(
            defaultInteractions: true,
            onChangedListener: (d) => setState(
              () => _tocado = '${d.domain}: ${d.measure}',
            ),
            groupList: [OrdinalGroup(id: 'v', data: _ord(ds))],
            domainAxis: _dom,
            measureAxis: _med,
            configSeriesBar: ConfigSeriesBarO(
              customColor: (g, d, i) => _c(i ?? 0),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            _tocado == null ? 'Toca una barra' : 'Tocado: $_tocado',
            style: TextStyle(
              color: _tocado == null ? C.dim : C.neon,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _aTicks(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return DChartBarO(
      groupList: [OrdinalGroup(id: 'v', data: _ord(ds))],
      domainAxis: _dom,
      measureAxis: MeasureAxis(
        labelStyle: const LabelStyle(color: C.muted, fontSize: 10),
        axisLineStyle: const LineStyle(color: C.line),
        tickLineStyle: const LineStyle(color: C.line),
        numericTickProvider: const NumericTickProvider(desiredTickCount: 4),
        tickLabelFormatter: (v) => '${v?.round().toString() ?? '0'} ep',
      ),
      configSeriesBar: ConfigSeriesBarO(seriesColor: C.neon),
    );
  }

  Widget _aPeso(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return DChartBarO(
      groupList: _par(ds),
      domainAxis: _dom,
      measureAxis: _med,
      configSeriesBar: ConfigSeriesBarO(
        weightPattern: [2, 1],
        customColor: (g, d, i) => _colorGrupo(g.id),
      ),
    );
  }

  Widget _aAgrupStack(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.dashboard_outlined);
    var t = 0.0;
    for (final d in ds) {
      t += d.valor;
    }
    final p = _prom(ds);
    return DChartBarO(
      groupList: [
        OrdinalGroup(id: 'valor', seriesCategory: 'a', data: _ord(ds)),
        OrdinalGroup(
          id: 'resto',
          seriesCategory: 'a',
          data: [
            for (final d in ds)
              OrdinalData(domain: d.nombre, measure: t - d.valor),
          ],
        ),
        OrdinalGroup(
          id: 'prom',
          seriesCategory: 'b',
          data: [
            for (final d in ds) OrdinalData(domain: d.nombre, measure: p),
          ],
        ),
      ],
      domainAxis: _dom,
      measureAxis: _med,
      configSeriesBar: ConfigSeriesBarO(
        barGroupingType: BarGroupingType.groupedStacked,
        customColor: (g, d, i) => _colorGrupo(g.id),
      ),
    );
  }

  Widget _aEjeSecundario(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.swap_vert_outlined);
    final p = _prom(ds);
    return DChartBarO(
      groupList: [
        OrdinalGroup(id: 'valor', data: _ord(ds)),
        OrdinalGroup(
          id: 'prom',
          data: [
            for (final d in ds) OrdinalData(domain: d.nombre, measure: p),
          ],
        ),
      ],
      useSecondaryMeasureAxis: (g) => g.id == 'prom',
      domainAxis: _dom,
      measureAxis: _med,
      secondaryMeasureAxis: const MeasureAxis(
        labelStyle: LabelStyle(color: C.red, fontSize: 10),
        axisLineStyle: LineStyle(color: C.red),
        tickLineStyle: LineStyle(color: C.red),
      ),
      configSeriesBar: ConfigSeriesBarO(customColor: (g, d, i) {
        final v = d.measure ?? 0;
        return g.id == 'prom'
            ? C.red
            : (v >= p ? C.neon : C.dim);
      }),
    );
  }

  Widget _aZoomMeasure(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    final p = _prom(ds);
    final m = _maxV(ds);
    return DChartBarO(
      groupList: [OrdinalGroup(id: 'v', data: _ord(ds))],
      domainAxis: _dom,
      measureAxis: MeasureAxis(
        labelStyle: const LabelStyle(color: C.muted, fontSize: 10),
        axisLineStyle: const LineStyle(color: C.line),
        tickLineStyle: const LineStyle(color: C.line),
        viewport: NumericViewport(min: p, max: m + 1),
      ),
      configSeriesBar: ConfigSeriesBarO(seriesColor: C.neon),
    );
  }

  Widget _aPaneo(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    final n = ds.length < 3 ? ds.length : 3;
    return DChartBarO(
      allowSliding: true,
      groupList: [OrdinalGroup(id: 'v', data: _ord(ds))],
      domainAxis: DomainAxisO(
        viewport: OrdinalViewport(startingDomain: ds.first.nombre, dataSize: n),
        labelStyle: const LabelStyle(color: C.muted, fontSize: 10),
        axisLineStyle: const LineStyle(color: C.line),
      ),
      measureAxis: _med,
      configSeriesBar: ConfigSeriesBarO(seriesColor: C.neon),
    );
  }

  Widget _aHorizAnim(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.view_week_outlined);
    return DChartBarO(
      arrangeVertically: true,
      animate: true,
      animationDuration: const Duration(milliseconds: 800),
      groupList: [OrdinalGroup(id: 'v', data: _ord(ds))],
      domainAxis: _dom,
      measureAxis: _med,
      configSeriesBar: ConfigSeriesBarO(
        seriesColor: C.neon,
        showBarLabel: true,
        labelAccessor: (g, d, i) => d.measure?.toStringAsFixed(0) ?? '',
        barLabelDecorator: const BarLabelDecoratorO(
          outsideLabelStyle: LabelStyle(color: C.text, fontSize: 10),
        ),
      ),
    );
  }

  Widget _aLaneAnim(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.linear_scale_outlined);
    return DChartBarO(
      renderType: (g) => RenderType.barLane,
      animate: true,
      animationDuration: const Duration(milliseconds: 800),
      groupList: [OrdinalGroup(id: 'v', data: _ord(ds))],
      domainAxis: _dom,
      measureAxis: _med,
      configSeriesBarLane: ConfigSeriesBarLaneO(
        seriesColor: C.neon,
        backgroundBarColor: C.card2,
        cornerRadius: 6,
        showBarLabel: true,
        barLabelDecorator: const BarLabelDecoratorO(
          outsideLabelStyle: LabelStyle(color: C.text, fontSize: 9),
        ),
        labelAccessor: (g, d, i) => d.measure?.toStringAsFixed(0) ?? '',
      ),
    );
  }

  Widget _aTargetPunteada(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return DChartBarO(
      renderType: (g) => RenderType.barTargetLine,
      animate: true,
      animationDuration: const Duration(milliseconds: 800),
      groupList: [OrdinalGroup(id: 'v', data: _ord(ds))],
      domainAxis: _dom,
      measureAxis: _med,
      configSeriesBarTargetLine: ConfigSeriesBarTargetLineO(
        strokeWidthPx: (g, d, i) => 4,
        dashPatternBase: [4, 3],
        roundEndCaps: false,
        customColor: (g, d, i) => C.neon,
      ),
    );
  }

  Widget _aBullet(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    final p = _prom(ds);
    return DChartBarO(
      groupList: [OrdinalGroup(id: 'v', data: _ord(ds))],
      domainAxis: _dom,
      measureAxis: _med,
      configSeriesBar: ConfigSeriesBarO(
        customColor: (g, d, i) => (d.measure ?? 0) >= p ? C.neon : C.dim,
        measureOffset: (g, d, i) => p,
        cornerRadius: 6,
      ),
    );
  }

  Widget _aLineaAnim(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return DChartLineN(
      animate: true,
      animationDuration: const Duration(milliseconds: 900),
      groupList: [NumericGroup(id: 'l', data: _num(ds))],
      domainAxis: _domN,
      measureAxis: _med,
      configSeriesLine: ConfigSeriesLineN(
        seriesColor: C.neon,
        includePoints: true,
        pointRadiusBase: 5,
        strokeWidthPxBase: 3,
      ),
    );
  }

  Widget _aAreaGradiente(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.area_chart_outlined);
    return DChartLineN(
      groupList: [NumericGroup(id: 'l', data: _num(ds))],
      domainAxis: _domN,
      measureAxis: _med,
      configSeriesLine: ConfigSeriesLineN(
        seriesColor: C.neon,
        includeArea: true,
        areaOpacity: 1,
        areaGradient: (g, d, i) => const LinearGradient(
          colors: [Color(0x9939FF14), Color(0x1039FF14)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _aTrazoGradiente(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return DChartLineN(
      groupList: [NumericGroup(id: 'l', data: _num(ds))],
      domainAxis: _domN,
      measureAxis: _med,
      configSeriesLine: ConfigSeriesLineN(
        strokeWidthPxBase: 4,
        strokeGradient: (g, d, i) => const LinearGradient(
          colors: [Color(0xFF39FF14), Color(0xFFFF6B6B)],
        ),
        includePoints: true,
        pointRadiusBase: 5,
      ),
    );
  }

  Widget _aSimbolosRect(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return DChartLineN(
      groupList: [NumericGroup(id: 'l', data: _num(ds))],
      domainAxis: _domN,
      measureAxis: _med,
      configSeriesLine: ConfigSeriesLineN(
        seriesColor: C.neon,
        includePoints: true,
        pointSymbol: const SymbolRenderRect(),
        pointRadiusBase: 7,
        strokeWidthPxBase: 2,
        includePointLabel: true,
        pointLabelDecorator: const PointLabelDecoratorN(
          labelStyle: LabelStyle(color: C.muted, fontSize: 9),
        ),
      ),
    );
  }

  Widget _aLineaApilada(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.area_chart_outlined);
    return DChartLineN(
      groupList: [
        NumericGroup(id: 'valor', data: _num(ds)),
        NumericGroup(id: 'resto', data: _numResto(ds)),
      ],
      domainAxis: _domN,
      measureAxis: _med,
      configSeriesLine: ConfigSeriesLineN(
        customColor: (grp, d, i) => _colorGrupo(grp.id),
        includeArea: true,
        areaOpacity: .5,
        stacked: true,
      ),
    );
  }

  List<NumericData> _numResto(List<Dato> ds) {
    var t = 0.0;
    for (final d in ds) {
      t += d.valor;
    }
    return [
      for (var i = 0; i < ds.length; i++)
        NumericData(domain: i + 1, measure: t - ds[i].valor),
    ];
  }

  Widget _aLineaTemporal(StatsData d) {
    final t = _time(d);
    if (t.isEmpty) return _vacio(Icons.show_chart);
    final y0 = _y0(d);
    final max = _maxV(d.epsPorAnio) + 2;
    return DChartLineT(
      groupList: [TimeGroup(id: 't', data: t)],
      domainAxis: DomainAxisT(
        labelStyle: const LabelStyle(color: C.muted, fontSize: 10),
        axisLineStyle: const LineStyle(color: C.line),
        tickLabelFormatter: _anio,
        viewport: TimeViewport(start: DateTime(y0), end: DateTime(y0 + 5)),
      ),
      measureAxis: MeasureAxis(
        labelStyle: const LabelStyle(color: C.muted, fontSize: 10),
        axisLineStyle: const LineStyle(color: C.line),
        tickLineStyle: const LineStyle(color: C.line),
        viewport: NumericViewport(min: 0, max: max),
      ),
      configSeriesLine: ConfigSeriesLineT(
        seriesColor: C.neon,
        includePoints: true,
        pointRadiusBase: 4,
      ),
    );
  }

  static String _anio(DateTime? v) => v == null ? '' : '${v.year}';

  Widget _aLineaGridline(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return DChartLineN(
      groupList: [NumericGroup(id: 'l', data: _num(ds))],
      domainAxis: _domN,
      measureAxis: MeasureAxis(
        labelStyle: const LabelStyle(color: C.muted, fontSize: 10),
        axisLineStyle: const LineStyle(color: C.line),
        tickLineStyle: const LineStyle(color: C.line),
        gridlineStyle: const LineStyle(color: C.line, dashPattern: [3, 3]),
        axisRenderType: AxisRenderType.gridline,
        tickLabelFormatter: (v) => '${v?.round() ?? 0}',
      ),
      configSeriesLine: ConfigSeriesLineN(seriesColor: C.neon),
    );
  }

  Widget _aDispEtiquetas(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.scatter_plot_outlined);
    return DChartScatterN(
      groupList: [NumericGroup(id: 's', data: _num(ds))],
      domainAxis: _domN,
      measureAxis: _med,
      configSeriesScatter: ConfigSeriesScatterN(
        seriesColor: C.neon,
        pointRadiusBase: 7,
        showPointLabel: true,
        pointLabelDecorator: PointLabelDecoratorN(
          labelFormatter: (d) => d.measure?.toStringAsFixed(0) ?? '',
          labelStyle: const LabelStyle(color: C.muted, fontSize: 9),
        ),
      ),
    );
  }

  Widget _aDispComparacion(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.scatter_plot_outlined);
    return DChartScatterN(
      groupList: [NumericGroup(id: 's', data: _num(ds))],
      domainAxis: _domN,
      measureAxis: _med,
      configSeriesScatter: ConfigSeriesScatterN(
        seriesColor: C.neon,
        pointRadiusBase: 7,
        showComparisonPoint: true,
        comparisonSymbolRender: const ComparisonSymbolRenderCylinder(),
      ),
    );
  }

  Widget _aDispLinea(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.scatter_plot_outlined);
    return DChartScatterN(
      groupList: [NumericGroup(id: 's', data: _num(ds))],
      domainAxis: _domN,
      measureAxis: _med,
      configSeriesScatter: ConfigSeriesScatterN(
        seriesColor: C.neon,
        symbolRender: const SymbolRenderLine(strokeWidth: 2),
        strokeWidthBase: 2,
        pointRadiusBase: 9,
      ),
    );
  }

  Widget _aDispTemporal(StatsData d) {
    final t = _time(d);
    if (t.isEmpty) return _vacio(Icons.scatter_plot_outlined);
    return DChartScatterT(
      animate: true,
      animationDuration: const Duration(milliseconds: 900),
      groupList: [TimeGroup(id: 't', data: t)],
      domainAxis: const DomainAxisT(
        labelStyle: LabelStyle(color: C.muted, fontSize: 10),
        axisLineStyle: LineStyle(color: C.line),
        tickLabelFormatter: _anio,
      ),
      measureAxis: _med,
      configSeriesScatter: ConfigSeriesScatterT(
        seriesColor: C.neon,
        pointRadiusBase: 7,
        symbolRender: const SymbolRenderTriangle(),
      ),
    );
  }

  Widget _aComboTres(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return DChartComboO(
      groupList: [
        OrdinalGroup(id: 'b', data: _ord(ds)),
        OrdinalGroup(id: 'l', data: _ord(ds)),
        OrdinalGroup(id: 'p', data: _ord(ds)),
      ],
      renderType: (g) => switch (g.id) {
        'b' => RenderType.bar,
        'l' => RenderType.line,
        _ => RenderType.scatterPlot,
      },
      domainAxis: _dom,
      measureAxis: _med,
      configSeriesBar: ConfigSeriesBarO(seriesColor: C.dim),
      configSeriesLine: ConfigSeriesLineO(
        seriesColor: C.neon,
        strokeWidthPxBase: 2,
      ),
      configSeriesScatter: ConfigSeriesScatterO(
        seriesColor: C.red,
        pointRadiusBase: 5,
      ),
    );
  }

  Widget _aComboSecundario(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    final p = _prom(ds);
    return DChartComboO(
      groupList: [
        OrdinalGroup(id: 'b', data: _ord(ds)),
        OrdinalGroup(
          id: 'prom',
          data: [
            for (final d in ds) OrdinalData(domain: d.nombre, measure: p),
          ],
        ),
      ],
      renderType: (g) => g.id == 'b' ? RenderType.bar : RenderType.line,
      useSecondaryMeasureAxis: (g) => g.id == 'prom',
      domainAxis: _dom,
      measureAxis: _med,
      secondaryMeasureAxis: const MeasureAxis(
        labelStyle: LabelStyle(color: C.red, fontSize: 10),
        axisLineStyle: LineStyle(color: C.red),
        tickLineStyle: LineStyle(color: C.red),
      ),
      configSeriesBar: ConfigSeriesBarO(seriesColor: C.neon),
      configSeriesLine: ConfigSeriesLineO(
        seriesColor: C.red,
        strokeWidthPxBase: 2,
        includePoints: true,
      ),
    );
  }

  Widget _aComboTarget(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return DChartComboO(
      renderType: (g) => g.id == 'b' ? RenderType.bar : RenderType.barTargetLine,
      groupList: [
        OrdinalGroup(id: 'b', data: _ord(ds)),
        OrdinalGroup(id: 't', data: _ord(ds)),
      ],
      domainAxis: _dom,
      measureAxis: _med,
      configSeriesBar: ConfigSeriesBarO(seriesColor: C.dim, cornerRadius: 6),
      configSeriesBarTargetLine: ConfigSeriesBarTargetLineO(
        strokeWidthPx: (g, d, i) => 4,
        roundEndCaps: false,
        customColor: (g, d, i) => C.neon,
      ),
    );
  }

  Widget _aComboTemporal(StatsData d) {
    final t = _time(d);
    if (t.isEmpty) return _vacio(Icons.show_chart);
    return DChartComboT(
      animate: true,
      animationDuration: const Duration(milliseconds: 900),
      renderType: (g) => g.id == 'b' ? RenderType.bar : RenderType.line,
      groupList: [
        TimeGroup(id: 'b', data: t),
        TimeGroup(id: 'l', data: t),
      ],
      domainAxis: const DomainAxisT(
        labelStyle: LabelStyle(color: C.muted, fontSize: 10),
        axisLineStyle: LineStyle(color: C.line),
        tickLabelFormatter: _anio,
      ),
      measureAxis: _med,
      configSeriesBar: ConfigSeriesBarT(seriesColor: C.dim),
      configSeriesLine: ConfigSeriesLineT(seriesColor: C.neon),
    );
  }

  Widget _aPastelBorde(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.pie_chart_outline);
    return DChartPieO(
      animate: true,
      animationDuration: const Duration(milliseconds: 900),
      data: _ord(ds),
      configSeriesPie: ConfigSeriesPieO(
        customColor: (g, d, i) => _c(i ?? 0),
        strokeColor: C.bg,
        strokeWidthBase: 3,
      ),
    );
  }

  Widget _aDonaEtiquetas(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.donut_large_outlined);
    return DChartPieO(
      data: _ord(ds),
      configSeriesPie: ConfigSeriesPieO(
        customColor: (g, d, i) => _c(i ?? 0),
        arcRatio: 0.5,
        showLabel: true,
        labelAccessor: (g, d, i) => d.domain,
        arcLabelDecorator: const ArcLabelDecoratorO(
          labelPosition: ArcLabelPosition.outside,
          showLeaderLines: true,
          outsideLabelStyle: LabelStyle(color: C.text, fontSize: 10),
          leaderLineStyle: ArcLabelLeaderLineStyle(
            color: C.dim,
            length: 16,
            thickness: 1,
          ),
        ),
      ),
    );
  }

  Widget _aComboApilado(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    var t = 0.0;
    for (final d in ds) {
      t += d.valor;
    }
    final p = _prom(ds);
    return DChartComboO(
      renderType: (g) => g.id == 'prom' ? RenderType.line : RenderType.bar,
      groupList: [
        OrdinalGroup(id: 'valor', seriesCategory: 'a', data: _ord(ds)),
        OrdinalGroup(
          id: 'resto',
          seriesCategory: 'a',
          data: [
            for (final d in ds)
              OrdinalData(domain: d.nombre, measure: t - d.valor),
          ],
        ),
        OrdinalGroup(
          id: 'prom',
          data: [
            for (final d in ds) OrdinalData(domain: d.nombre, measure: p),
          ],
        ),
      ],
      domainAxis: _dom,
      measureAxis: _med,
      configSeriesBar: ConfigSeriesBarO(
        barGroupingType: BarGroupingType.groupedStacked,
        customColor: (g, d, i) => _colorGrupo(g.id),
      ),
      configSeriesLine: ConfigSeriesLineO(
        seriesColor: C.red,
        strokeWidthPxBase: 2,
        dashPatternBase: [4, 3],
      ),
    );
  }

  Widget _aBarrasTemporales(StatsData d) {
    final t = _time(d);
    if (t.isEmpty) return _vacio(Icons.bar_chart_outlined);
    final y0 = _y0(d);
    return DChartBarT(
      animate: true,
      animationDuration: const Duration(milliseconds: 900),
      groupList: [TimeGroup(id: 't', data: t)],
      domainAxis: DomainAxisT(
        labelStyle: const LabelStyle(color: C.muted, fontSize: 10),
        axisLineStyle: const LineStyle(color: C.line),
        tickLabelFormatter: _anio,
        viewport: TimeViewport(
          start: DateTime(y0),
          end: DateTime(y0 + 5),
        ),
      ),
      measureAxis: _med,
      configSeriesBar: ConfigSeriesBarT(
        customColor: (g, d, i) => _c(i ?? 0),
        cornerRadius: 6,
      ),
    );
  }

  Widget _aComboNumerico(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return DChartComboN(
      animate: true,
      animationDuration: const Duration(milliseconds: 900),
      renderType: (g) => g.id == 'b' ? RenderType.bar : RenderType.line,
      groupList: [
        NumericGroup(id: 'b', data: _num(ds)),
        NumericGroup(id: 'l', data: _num(ds)),
      ],
      domainAxis: _domN,
      measureAxis: _med,
      configSeriesBar: ConfigSeriesBarN(
        seriesColor: C.dim,
        maxBarWidthPx: 14,
      ),
      configSeriesLine: ConfigSeriesLineN(
        seriesColor: C.neon,
        strokeWidthPxBase: 3,
        includePoints: true,
      ),
    );
  }

  // ══════════════════ LISTADOS ══════════════════

  List<(String, String, Widget)> _basicas(StatsData d) => [
    (
      'B01 · Barras clásicas',
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
      'B06 · Barras finas',
      'De qué planetas vienen los personajes: los orígenes más comunes.',
      _bFina(d.origin),
    ),
    (
      'B07 · Barras con trama',
      'Cuántos personajes son hombres, mujeres, sin género o desconocidos.',
      _bTrama(d.gender),
    ),
    (
      'B08 · Barras con gridline',
      'Cuántos personajes aparecen en 1, 2-5, 6-10 o más de 10 episodios.',
      _bGridline(d.epsPorPersonaje),
    ),
    (
      'B09 · Barras sin eje de dominio',
      'Cuántos personajes hay por estado, sin rótulos en el eje horizontal.',
      _bSinEje(d.status),
    ),
    (
      'B10 · Barras con eje rotado',
      'Cuántos personajes aparecen en cada uno de los primeros episodios.',
      _bEjeRotado(d.charsPorEpisodio),
    ),
    (
      'B11 · Barras en ventana',
      'Los 4 personajes con más episodios de la serie (top del ranking).',
      _bVentana(d.topPersonajesEps),
    ),
    (
      'B12 · Línea',
      'Cuántos episodios tiene cada temporada de la serie.',
      _bLinea(d.epsPorTemporada),
    ),
    (
      'B13 · Línea con puntos',
      'Cuántos episodios se estrenaron en cada año.',
      _bLineaPuntos(d.epsPorAnio),
    ),
    (
      'B14 · Línea con área',
      'Cuántos episodios tiene cada temporada, con el volumen total bajo la curva.',
      _bLineaArea(d.epsPorTemporada),
    ),
    (
      'B15 · Línea punteada',
      'Cuántos episodios se estrenaron cada año, año tras año.',
      _bLineaPunteada(d.epsPorAnio),
    ),
    (
      'B16 · Línea gruesa redonda',
      'Cuántos episodios tiene cada temporada, trazando la evolución entre temporadas.',
      _bLineaGruesa(d.epsPorTemporada),
    ),
    (
      'B17 · Línea con etiquetas',
      'Cuántos episodios tiene cada temporada, con su valor escrito en cada punto.',
      _bLineaEtiquetas(d.epsPorTemporada),
    ),
    (
      'B18 · Dispersión',
      'Cuántos personajes aparecen en cada uno de los primeros episodios.',
      _bDispersion(d.charsPorEpisodio),
    ),
    (
      'B19 · Dispersión cuadrada',
      'Cuántos personajes tienen 1, 2-5, 6-10 o más de 10 episodios.',
      _bDispCuadrada(d.epsPorPersonaje),
    ),
    (
      'B20 · Dispersión triangular',
      'Cuántos episodios tiene cada temporada, punto por temporada.',
      _bDispTriangular(d.epsPorTemporada),
    ),
    (
      'B21 · Dispersión hueca',
      'Cuántos personajes salen en cada uno de los primeros episodios de la serie.',
      _bDispHueca(d.charsPorEpisodio),
    ),
    (
      'B22 · Combo barras + línea',
      'Cuántos episodios tiene cada temporada y cómo cambia entre unas y otras.',
      _bComboBarraLinea(d.epsPorTemporada),
    ),
    (
      'B23 · Combo línea + dispersión',
      'Episodios por año, con la tendencia anual y cada año marcado por separado.',
      _bComboLineaPunto(d.epsPorAnio),
    ),
    (
      'B24 · Pastel',
      'Qué proporción de personajes pertenece a cada especie.',
      _bPastel(d.species),
    ),
    (
      'B25 · Pastel con etiquetas',
      'Cuántos episodios tiene cada temporada y el nombre de cada una.',
      _bPastelEtiquetas(d.epsPorTemporada),
    ),
    (
      'B26 · Dona',
      'Cómo se reparten los 51 episodios de la serie entre las temporadas.',
      _bDona(d.epsPorTemporada),
    ),
    (
      'B27 · Media luna',
      'Cuántos personajes están vivos, muertos o con estado desconocido.',
      _bMediaLuna(d.status),
    ),
    (
      'B28 · Pastel desde la derecha',
      'De qué planetas vienen los personajes: los orígenes más comunes.',
      _bPastelDerecha(d.origin),
    ),
    (
      'B29 · Barra lane',
      'Cuántos episodios tiene cada temporada, comparando cada una con las demás.',
      _bLane(d.epsPorTemporada),
    ),
    (
      'B30 · Línea de objetivo',
      'Cuántos episodios tiene cada temporada marcados como una línea de valor.',
      _bTarget(d.epsPorTemporada),
    ),
    (
      'B31 · Barras apiladas',
      'Cuántos personajes hay por estado y cuántos NO son de ese estado, sumados en la misma barra.',
      _bApiladas(d.status),
    ),
  ];

  List<(String, String, Widget)> _avanzadas(StatsData d) => [
    (
      'A01 · Barras animadas con degradado',
      'Cuántos episodios tiene cada temporada, presentados al entrar en pantalla.',
      _aAnimDegradado(d.epsPorTemporada),
    ),
    (
      'A02 · Barras con selección táctil',
      'Cuántos personajes hay de cada especie; toca una barra para ver su valor.',
      _aSeleccion(d.species),
    ),
    (
      'A03 · Barras con ticks y formato',
      'Cuántos episodios tiene cada temporada, rotulados como "8 ep".',
      _aTicks(d.epsPorTemporada),
    ),
    (
      'A04 · Barras con peso desigual',
      'De qué planetas vienen los personajes, resaltando el primer origen.',
      _aPeso(d.origin),
    ),
    (
      'A05 · Barras agrupadas apiladas',
      'Las ubicaciones más comunes: cuántos personajes viven en cada una y el resto repartido.',
      _aAgrupStack(d.location),
    ),
    (
      'A06 · Barras con eje secundario',
      'Cuántos episodios tiene cada temporada contra su promedio en un eje aparte.',
      _aEjeSecundario(d.epsPorTemporada),
    ),
    (
      'A07 · Barras con zoom vertical',
      'Las especies más comunes, ampliadas entre el promedio y el máximo.',
      _aZoomMeasure(d.species),
    ),
    (
      'A08 · Barras con paneo',
      'Los personajes con más episodios; arrastra para explorar el ranking completo.',
      _aPaneo(d.topPersonajesEps),
    ),
    (
      'A09 · Barras horizontales animadas',
      'Las ubicaciones o planetas con más personajes, con su número en cada barra.',
      _aHorizAnim(d.location),
    ),
    (
      'A10 · Lane animado con etiquetas',
      'Cuántos episodios tiene cada temporada, con su valor sobre cada pista.',
      _aLaneAnim(d.epsPorTemporada),
    ),
    (
      'A11 · Objetivo punteado animado',
      'Cuántos episodios tiene cada temporada, comparados con un valor de referencia.',
      _aTargetPunteada(d.epsPorTemporada),
    ),
    (
      'A12 · Barras tipo bullet',
      'Las especies más comunes medidas desde el promedio hasta su valor real.',
      _aBullet(d.species),
    ),
    (
      'A13 · Línea animada con puntos',
      'Cuántos episodios tiene cada temporada, dibujándose al entrar en pantalla.',
      _aLineaAnim(d.epsPorTemporada),
    ),
    (
      'A14 · Área con degradado',
      'Cuántos episodios se estrenaron cada año, con el volumen destacado bajo la curva.',
      _aAreaGradiente(d.epsPorAnio),
    ),
    (
      'A15 · Trazo con degradado',
      'Cuántos episodios tiene cada temporada, del valor más alto al más bajo.',
      _aTrazoGradiente(d.epsPorTemporada),
    ),
    (
      'A16 · Línea con símbolos rectos',
      'Cuántos episodios tiene cada temporada, con el valor impreso en cada punto.',
      _aSimbolosRect(d.epsPorTemporada),
    ),
    (
      'A17 · Líneas apiladas con área',
      'De qué planetas vienen los personajes: cada origen contra el resto del total.',
      _aLineaApilada(d.origin),
    ),
    (
      'A18 · Línea temporal con viewport',
      'Cuántos episodios se estrenaron cada año, centrado en los primeros años de la serie.',
      _aLineaTemporal(d),
    ),
    (
      'A19 · Línea con gridline punteada',
      'Cuántos episodios se estrenaron cada año, con líneas guía de referencia.',
      _aLineaGridline(d.epsPorAnio),
    ),
    (
      'A20 · Dispersión con etiquetas',
      'Cuántos episodios tiene cada temporada, con su número junto a cada punto.',
      _aDispEtiquetas(d.epsPorTemporada),
    ),
    (
      'A21 · Dispersión con comparación',
      'Cuántos personajes aparecen en cada episodio, comparados con su promedio.',
      _aDispComparacion(d.charsPorEpisodio),
    ),
    (
      'A22 · Dispersión con símbolo línea',
      'Cuántos personajes tienen 1, 2-5, 6-10 o más de 10 episodios en la serie.',
      _aDispLinea(d.epsPorPersonaje),
    ),
    (
      'A23 · Dispersión temporal',
      'Episodios estrenados en cada año, con un punto por año.',
      _aDispTemporal(d),
    ),
    (
      'A24 · Combo de tres renderers',
      'Cuántos episodios tiene cada temporada, visto como barras, línea y puntos a la vez.',
      _aComboTres(d.epsPorTemporada),
    ),
    (
      'A25 · Combo con eje secundario',
      'Las especies más comunes contra su promedio, cada uno en su propio eje.',
      _aComboSecundario(d.species),
    ),
    (
      'A26 · Combo barras + objetivo',
      'Cuántos episodios tiene cada temporada marcados contra un valor de referencia.',
      _aComboTarget(d.epsPorTemporada),
    ),
    (
      'A27 · Combo temporal',
      'Cuántos episodios se estrenaron cada año, en barras con la tendencia encima.',
      _aComboTemporal(d),
    ),
    (
      'A28 · Pastel animado con borde',
      'Qué proporción de personajes pertenece a cada especie.',
      _aPastelBorde(d.species),
    ),
    (
      'A29 · Dona con etiquetas y guías',
      'Cuántos episodios tiene cada temporada, con el nombre de cada una fuera del anillo.',
      _aDonaEtiquetas(d.epsPorTemporada),
    ),
    (
      'A30 · Combo apilado con promedio',
      'Las ubicaciones más comunes apiladas contra su promedio de personajes.',
      _aComboApilado(d.location),
    ),
    (
      'A31 · Barras temporales con zoom',
      'Cuántos episodios se estrenaron en una ventana de 6 años, con zoom de fechas.',
      _aBarrasTemporales(d),
    ),
    (
      'A32 · Combo numérico',
      'Cuántos personajes aparecen en cada uno de los primeros episodios, en barras y línea.',
      _aComboNumerico(d.charsPorEpisodio),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('d_chart', style: T.title)),
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
