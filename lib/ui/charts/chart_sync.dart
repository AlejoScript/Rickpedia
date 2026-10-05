// ─── Pantalla 4/4: syncfusion ─────────────────────────────────────
// SOLO importa syncfusion_flutter_charts.
// BÁSICAS = una variante visual por familia, sin toque ni degradados.
// AVANZADAS = tooltip, leyendas, degradados, multi-serie, apiladas,
// indicadores técnicos y zoom. Ninguna repite estructura ni presentación.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../core/adaptive.dart';
import '../../core/theme.dart';
import '../../data/api.dart';
import '../../data/stats_service.dart';
import '../widgets/chart_viewer.dart';
import '../widgets/common.dart';

class ChartSyncScreen extends StatefulWidget {
  const ChartSyncScreen({super.key});
  @override
  State<ChartSyncScreen> createState() => _ChartSyncScreenState();
}

class _ChartSyncScreenState extends State<ChartSyncScreen> {
  Future<StatsData>? _fut;
  int _basic = 0;
  int _adv = 0;
  final _svc = StatsService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fut ??= _svc.load(context.read<Api>());
  }

  static const _cols = [
    Color(0xFF39FF14),
    Color(0xFF22D3EE),
    Color(0xFFFBBF24),
    Color(0xFFF472B6),
    Color(0xFFA78BFA),
    Color(0xFFFF6B6B),
  ];
  Color _c(int i) => _cols[i % _cols.length];
  static const _lbl = TextStyle(color: C.muted, fontSize: 9);

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

  List<Dato> _acum(List<Dato> ds) {
    var s = 0.0;
    return [for (final d in ds) Dato(d.nombre, s += d.valor)];
  }

  List<Dato> _constante(List<Dato> ds, double v) => [
    for (final d in ds) Dato(d.nombre, v),
  ];

  List<Dato> _resto(List<Dato> ds) {
    final t = _tot(ds);
    return [for (final d in ds) Dato(d.nombre, t - d.valor)];
  }

  List<(DateTime, double)> _fechas(StatsData d) {
    final out = <(DateTime, double)>[];
    var i = 0;
    for (final x in _anios(d)) {
      out.add((DateTime(int.tryParse(x.nombre) ?? 2013 + i), x.valor));
      i++;
    }
    return out;
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  Widget _vacio(IconData i) =>
      Nada(icon: i, title: 'Sin datos', body: 'Reintenta.');

  // ══════════════════════ BÁSICAS ══════════════════════

  Widget _bColumnas(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      series: [
        ColumnSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: C.neon,
        ),
      ],
    );
  }

  Widget _bColMulti(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      series: [
        ColumnSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          pointColorMapper: (d, i) => _c(i),
        ),
      ],
    );
  }

  Widget _bColEtiquetas(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      series: [
        ColumnSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: _c(1),
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            textStyle: _lbl,
          ),
        ),
      ],
    );
  }

  Widget _bBarra(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.view_week_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      series: [
        BarSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: _c(2),
        ),
      ],
    );
  }

  Widget _bApiladas(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      series: [
        StackedColumnSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: C.neon,
          name: 'Valor',
        ),
        StackedColumnSeries<Dato, String>(
          dataSource: _resto(ds),
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: C.line,
          name: 'Resto',
        ),
      ],
    );
  }

  Widget _bBarraApilada(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.view_week_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      series: [
        StackedBarSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: _c(3),
          name: 'Valor',
        ),
        StackedBarSeries<Dato, String>(
          dataSource: _resto(ds),
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: C.line,
          name: 'Resto',
        ),
      ],
    );
  }

  Widget _bCol100(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      series: [
        StackedColumn100Series<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: _c(4),
          name: 'Valor',
        ),
        StackedColumn100Series<Dato, String>(
          dataSource: _resto(ds),
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: C.line,
          name: 'Resto',
        ),
      ],
    );
  }

  Widget _bLinea(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      series: [
        LineSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: C.neon,
          width: 3,
        ),
      ],
    );
  }

  Widget _bLineaPuntos(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      series: [
        LineSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: _c(1),
          width: 3,
          markerSettings: const MarkerSettings(isVisible: true),
        ),
      ],
    );
  }

  Widget _bLineaPunteada(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      series: [
        LineSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: _c(2),
          width: 3,
          dashArray: [8, 6],
        ),
      ],
    );
  }

  Widget _bFast(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      series: [
        FastLineSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: _c(5),
          width: 3,
        ),
      ],
    );
  }

  Widget _bCurva(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      series: [
        SplineSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: _c(3),
          width: 3,
        ),
      ],
    );
  }

  Widget _bEscalones(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      series: [
        StepLineSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: _c(4),
          width: 3,
        ),
      ],
    );
  }

  Widget _bArea(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.area_chart_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      series: [
        AreaSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: C.neon.withValues(alpha: .4),
          borderColor: C.neon,
          borderWidth: 2,
        ),
      ],
    );
  }

  Widget _bAreaSuave(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.area_chart_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      series: [
        SplineAreaSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: _c(1).withValues(alpha: .35),
          borderColor: _c(1),
          borderWidth: 2,
        ),
      ],
    );
  }

  Widget _bAreaEscalon(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.area_chart_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      series: [
        StepAreaSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: _c(2).withValues(alpha: .35),
          borderColor: _c(2),
          borderWidth: 2,
        ),
      ],
    );
  }

  Widget _bDispersion(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.scatter_plot_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      series: [
        ScatterSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: _c(3),
          markerSettings: const MarkerSettings(
            isVisible: true,
            height: 12,
            width: 12,
          ),
        ),
      ],
    );
  }

  Widget _bBurbuja(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bubble_chart_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      series: [
        BubbleSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          sizeValueMapper: (d, _) => d.valor,
          minimumRadius: 5,
          maximumRadius: 22,
          color: _c(4).withValues(alpha: .7),
        ),
      ],
    );
  }

  Widget _bRangoCol(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      series: [
        RangeColumnSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          highValueMapper: (d, _) => d.valor * 1.15,
          lowValueMapper: (d, _) => d.valor * .85,
          color: _c(5),
        ),
      ],
    );
  }

  Widget _bRangoArea(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.area_chart_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      series: [
        RangeAreaSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          highValueMapper: (d, _) => d.valor * 1.15,
          lowValueMapper: (d, _) => d.valor * .85,
          color: C.neon.withValues(alpha: .3),
          borderColor: C.neon,
        ),
      ],
    );
  }

  Widget _bFechas(StatsData d) {
    final ds = _fechas(d);
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return SfCartesianChart(
      primaryXAxis: const DateTimeAxis(
        intervalType: DateTimeIntervalType.years,
      ),
      series: [
        LineSeries<(DateTime, double), DateTime>(
          dataSource: ds,
          xValueMapper: (r, _) => r.$1,
          yValueMapper: (r, _) => r.$2,
          color: C.neon,
          width: 3,
        ),
      ],
    );
  }

  Widget _bColRedonda(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      series: [
        ColumnSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: _c(1),
          borderRadius: BorderRadius.circular(7),
          borderColor: C.line,
          borderWidth: 1,
        ),
      ],
    );
  }

  Widget _bPastel(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.pie_chart_outline);
    return SfCircularChart(
      series: [
        PieSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            textStyle: _lbl,
          ),
        ),
      ],
    );
  }

  Widget _bPastelFuera(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.pie_chart_outline);
    return SfCircularChart(
      series: [
        PieSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            labelPosition: ChartDataLabelPosition.outside,
            textStyle: _lbl,
            connectorLineSettings: ConnectorLineSettings(color: C.muted),
          ),
        ),
      ],
    );
  }

  Widget _bPastelExplotado(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.pie_chart_outline);
    return SfCircularChart(
      series: [
        PieSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          explode: true,
          explodeIndex: 0,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            textStyle: _lbl,
          ),
        ),
      ],
    );
  }

  Widget _bDona(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.donut_large_outlined);
    return SfCircularChart(
      series: [
        DoughnutSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
        ),
      ],
    );
  }

  Widget _bDonaCentro(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.donut_large_outlined);
    return SfCircularChart(
      annotations: [
        CircularChartAnnotation(
          widget: Text(
            _fmt(_tot(ds)),
            style: const TextStyle(color: C.text, fontSize: 20),
          ),
        ),
      ],
      series: [
        DoughnutSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          pointColorMapper: (d, i) => _c(i),
        ),
      ],
    );
  }

  Widget _bDonaLeyenda(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.donut_large_outlined);
    return SfCircularChart(
      legend: const Legend(
        isVisible: true,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      series: [
        DoughnutSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
        ),
      ],
    );
  }

  Widget _bPiramide(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.change_history_outlined);
    return SfPyramidChart(
      series: PyramidSeries<Dato, String>(
        dataSource: ds,
        xValueMapper: (d, _) => d.nombre,
        yValueMapper: (d, _) => d.valor,
        dataLabelSettings: const DataLabelSettings(
          isVisible: true,
          textStyle: _lbl,
        ),
      ),
    );
  }

  Widget _bEmbudo(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.filter_alt_outlined);
    return SfFunnelChart(
      series: FunnelSeries<Dato, String>(
        dataSource: ds,
        xValueMapper: (d, _) => d.nombre,
        yValueMapper: (d, _) => d.valor,
        dataLabelSettings: const DataLabelSettings(
          isVisible: true,
          textStyle: _lbl,
        ),
      ),
    );
  }

  Widget _bRadial(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.donut_large_outlined);
    return SfCircularChart(
      series: [
        RadialBarSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          trackColor: C.line,
          cornerStyle: CornerStyle.bothCurve,
        ),
      ],
    );
  }

  // ══════════════════════ AVANZADAS ══════════════════════

  Widget _aTooltip(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: [
        ColumnSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: _c(1),
        ),
      ],
    );
  }

  Widget _aGradiente(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: [
        ColumnSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          gradient: const LinearGradient(
            colors: [Color(0xFF39FF14), Color(0xFF22D3EE)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
      ],
    );
  }

  Widget _aAgrupadas(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      legend: const Legend(
        isVisible: true,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: [
        ColumnSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: C.neon,
          name: 'Valor',
        ),
        ColumnSeries<Dato, String>(
          dataSource: _constante(ds, _prom(ds)),
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: _c(2),
          name: 'Promedio',
        ),
      ],
    );
  }

  Widget _aApiladas(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      legend: const Legend(
        isVisible: true,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: [
        StackedColumnSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: C.neon,
          name: 'Valor',
        ),
        StackedColumnSeries<Dato, String>(
          dataSource: _resto(ds),
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: C.line,
          name: 'Resto',
        ),
      ],
    );
  }

  Widget _aError(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: [
        ColumnSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: _c(1),
          name: 'Valor',
        ),
        ErrorBarSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: C.red,
          width: 2,
          type: ErrorBarType.percentage,
          direction: Direction.both,
          mode: RenderingMode.vertical,
          verticalErrorValue: 15,
          horizontalErrorValue: 0,
        ),
      ],
    );
  }

  Widget _aOrden(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: [
        ColumnSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: _c(4),
          sortingOrder: SortingOrder.descending,
          sortFieldValueMapper: (d, _) => d.valor,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            textStyle: _lbl,
          ),
        ),
      ],
    );
  }

  Widget _aUmbral(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    final p = _prom(ds);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: [
        ColumnSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          pointColorMapper: (d, _) => d.valor >= p ? C.neon : C.red,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            textStyle: _lbl,
          ),
        ),
      ],
    );
  }

  Widget _aBarraApilada(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.view_week_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      legend: const Legend(
        isVisible: true,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: [
        StackedBarSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: _c(3),
          name: 'Valor',
        ),
        StackedBarSeries<Dato, String>(
          dataSource: _resto(ds),
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: C.line,
          name: 'Resto',
        ),
      ],
    );
  }

  Widget _aTrackball(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.longPress,
        lineType: TrackballLineType.vertical,
      ),
      series: [
        LineSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: C.neon,
          width: 3,
          markerSettings: const MarkerSettings(isVisible: true),
        ),
      ],
    );
  }

  Widget _aPuntos(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: [
        LineSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: _c(3),
          width: 3,
          markerSettings: MarkerSettings(
            isVisible: true,
            height: 16,
            width: 16,
            color: _c(3),
            borderColor: C.bg,
            borderWidth: 2,
          ),
        ),
      ],
    );
  }

  Widget _aTendencia(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      legend: const Legend(
        isVisible: true,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      series: [
        LineSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: C.neon,
          width: 3,
          name: 'Episodios',
          trendlines: [
            Trendline(
              type: TrendlineType.linear,
              color: C.red,
              width: 2,
              dashArray: [6, 4],
              name: 'Tendencia',
            ),
          ],
        ),
      ],
    );
  }

  Widget _aPromedio(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      legend: const Legend(
        isVisible: true,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: [
        LineSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: _c(2),
          width: 3,
          name: 'Episodios',
        ),
        LineSeries<Dato, String>(
          dataSource: _constante(ds, _prom(ds)),
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: C.red,
          width: 2,
          dashArray: [6, 4],
          name: 'Promedio',
        ),
      ],
    );
  }

  Widget _aZoom(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      zoomPanBehavior: ZoomPanBehavior(
        enablePinching: true,
        enablePanning: true,
        zoomMode: ZoomMode.xy,
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: [
        LineSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: _c(5),
          width: 3,
          markerSettings: const MarkerSettings(isVisible: true),
        ),
      ],
    );
  }

  Widget _aAnotacion(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    var top = ds.first;
    for (final d in ds) {
      if (d.valor > top.valor) top = d;
    }
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      annotations: [
        CartesianChartAnnotation(
          widget: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: C.card2,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: C.neon),
            ),
            child: Text(
              'Máx ${_fmt(top.valor)}',
              style: const TextStyle(color: C.neon, fontSize: 10),
            ),
          ),
          x: top.nombre,
          y: top.valor,
          coordinateUnit: CoordinateUnit.point,
        ),
      ],
      tooltipBehavior: TooltipBehavior(enable: true),
      series: [
        LineSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: C.neon,
          width: 3,
          markerSettings: const MarkerSettings(isVisible: true),
        ),
      ],
    );
  }

  Widget _aDosAreas(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.area_chart_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      legend: const Legend(
        isVisible: true,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: [
        AreaSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: C.neon.withValues(alpha: .35),
          borderColor: C.neon,
          borderWidth: 2,
          name: 'Episodios',
        ),
        AreaSeries<Dato, String>(
          dataSource: _acum(ds),
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: _c(2).withValues(alpha: .3),
          borderColor: _c(2),
          borderWidth: 2,
          name: 'Acumulado',
        ),
      ],
    );
  }

  Widget _aAreaGradiente(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.area_chart_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: [
        SplineAreaSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          gradient: const LinearGradient(
            colors: [Color(0xFF39FF14), Color(0xFF22D3EE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderColor: C.neon,
          borderWidth: 2,
        ),
      ],
    );
  }

  Widget _aDispersion(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.scatter_plot_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: [
        ScatterSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: _c(4),
          markerSettings: const MarkerSettings(
            isVisible: true,
            height: 14,
            width: 14,
          ),
        ),
      ],
    );
  }

  Widget _aBurbuja(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bubble_chart_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      legend: const Legend(
        isVisible: true,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: [
        BubbleSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          sizeValueMapper: (d, _) => d.valor,
          minimumRadius: 5,
          maximumRadius: 22,
          color: _c(5).withValues(alpha: .75),
          name: 'Tamaño = valor',
        ),
      ],
    );
  }

  Widget _aLog(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.scatter_plot_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      primaryYAxis: const LogarithmicAxis(
        title: AxisTitle(text: 'escala logarítmica'),
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: [
        ScatterSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: _c(1),
          markerSettings: const MarkerSettings(
            isVisible: true,
            height: 14,
            width: 14,
          ),
        ),
      ],
    );
  }

  Widget _aSma(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      legend: const Legend(
        isVisible: true,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: [
        LineSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: C.neon,
          width: 3,
          name: 'valor',
          markerSettings: const MarkerSettings(isVisible: true),
        ),
      ],
      indicators: [
        SmaIndicator<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          closeValueMapper: (d, _) => d.valor,
          seriesName: 'valor',
          period: 3,
          signalLineColor: C.red,
          signalLineWidth: 2,
          dashArray: [6, 4],
          name: 'SMA 3',
        ),
      ],
    );
  }

  Widget _aBanda(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    final p = _prom(ds);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      primaryYAxis: NumericAxis(
        plotBands: [
          PlotBand(
            start: p,
            end: _maxV(ds) * 1.4,
            color: C.neon.withValues(alpha: .12),
            text: 'Sobre el promedio',
            textStyle: const TextStyle(color: C.muted, fontSize: 10),
          ),
        ],
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: [
        ColumnSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: _c(1),
        ),
      ],
    );
  }

  Widget _aFaltante(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.show_chart);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: [
        LineSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, i) => i == 2 ? null : d.valor,
          color: _c(5),
          width: 3,
          markerSettings: const MarkerSettings(isVisible: true),
          emptyPointSettings: const EmptyPointSettings(
            mode: EmptyPointMode.gap,
            color: C.red,
          ),
        ),
      ],
    );
  }

  Widget _aPastel(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.pie_chart_outline);
    return SfCircularChart(
      legend: const Legend(
        isVisible: true,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: [
        PieSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            textStyle: _lbl,
          ),
        ),
      ],
    );
  }

  Widget _aPastelSel(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.pie_chart_outline);
    return SfCircularChart(
      selectionGesture: ActivationMode.singleTap,
      legend: const Legend(
        isVisible: true,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      series: [
        PieSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          selectionBehavior: SelectionBehavior(
            enable: true,
            selectedColor: C.neon,
            unselectedOpacity: .4,
          ),
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            textStyle: _lbl,
          ),
        ),
      ],
    );
  }

  Widget _aDona(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.donut_large_outlined);
    return SfCircularChart(
      legend: const Legend(
        isVisible: true,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: [
        DoughnutSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            textStyle: _lbl,
          ),
        ),
      ],
    );
  }

  Widget _aDonaExplota(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.donut_large_outlined);
    return SfCircularChart(
      tooltipBehavior: TooltipBehavior(enable: true),
      series: [
        DoughnutSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          explode: true,
          explodeGesture: ActivationMode.singleTap,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            textStyle: _lbl,
          ),
        ),
      ],
    );
  }

  Widget _aRadial(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.donut_large_outlined);
    return SfCircularChart(
      legend: const Legend(
        isVisible: true,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      series: [
        RadialBarSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          trackColor: C.line,
          cornerStyle: CornerStyle.bothCurve,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            textStyle: _lbl,
          ),
        ),
      ],
    );
  }

  Widget _aPiramide(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.change_history_outlined);
    return SfPyramidChart(
      legend: const Legend(
        isVisible: true,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: PyramidSeries<Dato, String>(
        dataSource: ds,
        xValueMapper: (d, _) => d.nombre,
        yValueMapper: (d, _) => d.valor,
        selectionBehavior: SelectionBehavior(
          enable: true,
          selectedColor: C.neon,
          unselectedOpacity: .45,
        ),
        dataLabelSettings: const DataLabelSettings(
          isVisible: true,
          textStyle: _lbl,
        ),
      ),
    );
  }

  Widget _aEmbudo(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.filter_alt_outlined);
    return SfFunnelChart(
      tooltipBehavior: TooltipBehavior(enable: true),
      series: FunnelSeries<Dato, String>(
        dataSource: ds,
        xValueMapper: (d, _) => d.nombre,
        yValueMapper: (d, _) => d.valor,
        dataLabelSettings: const DataLabelSettings(
          isVisible: true,
          textStyle: _lbl,
        ),
      ),
    );
  }

  Widget _aDobleEje(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      primaryYAxis: const NumericAxis(title: AxisTitle(text: 'Episodios')),
      axes: const [
        NumericAxis(
          name: 'y2',
          opposedPosition: true,
          title: AxisTitle(text: 'Promedio'),
        ),
      ],
      legend: const Legend(
        isVisible: true,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: [
        ColumnSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: _c(1),
          name: 'Episodios',
        ),
        LineSeries<Dato, String>(
          dataSource: _constante(ds, _prom(ds)),
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          yAxisName: 'y2',
          color: C.red,
          width: 2,
          dashArray: [6, 4],
          name: 'Promedio',
        ),
      ],
    );
  }

  Widget _aWaterfall(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: [
        WaterfallSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: C.neon,
          negativePointsColor: C.red,
          connectorLineSettings: const WaterfallConnectorLineSettings(
            color: C.line,
            width: 1,
            dashArray: [4, 4],
          ),
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            textStyle: _lbl,
          ),
        ),
      ],
    );
  }

  Widget _aCombo(List<Dato> ds) {
    if (ds.isEmpty) return _vacio(Icons.bar_chart_outlined);
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      legend: const Legend(
        isVisible: true,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.longPress,
      ),
      series: [
        ColumnSeries<Dato, String>(
          dataSource: ds,
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: _c(1),
          name: 'Episodios',
        ),
        LineSeries<Dato, String>(
          dataSource: _acum(ds),
          xValueMapper: (d, _) => d.nombre,
          yValueMapper: (d, _) => d.valor,
          color: C.red,
          width: 3,
          markerSettings: const MarkerSettings(isVisible: true),
          name: 'Acumulado',
        ),
      ],
    );
  }

  // ══════════════════ LISTADOS ══════════════════

  List<(String, String, Widget)> _basicas(StatsData d) => [
    (
      'B01 · Columnas clásicas',
      'Cuántos personajes están vivos, muertos o con estado desconocido.',
      _bColumnas(d.status),
    ),
    (
      'B02 · Columnas multicolor',
      'Las especies más comunes entre los personajes de la serie.',
      _bColMulti(d.species),
    ),
    (
      'B03 · Columnas con etiquetas',
      'De qué planetas vienen los personajes, con su número sobre cada columna.',
      _bColEtiquetas(d.origin),
    ),
    (
      'B04 · Barras horizontales',
      'Las ubicaciones o planetas donde más personajes se encuentran.',
      _bBarra(d.location),
    ),
    (
      'B05 · Columnas apiladas',
      'Cuántos personajes hay por estado y cuántos no son de ese estado, sumados en la misma columna.',
      _bApiladas(d.status),
    ),
    (
      'B06 · Barras apiladas',
      'De qué planetas vienen los personajes, con cada origen contra el resto del total.',
      _bBarraApilada(d.origin),
    ),
    (
      'B07 · Columnas al 100%',
      'Qué porcentaje del total de personajes vive en cada ubicación.',
      _bCol100(d.location),
    ),
    (
      'B08 · Línea simple',
      'Cuántos episodios se estrenaron cada año.',
      _bLinea(d.epsPorAnio),
    ),
    (
      'B09 · Línea con marcadores',
      'Cuántos personajes aparecen en cada uno de los primeros episodios.',
      _bLineaPuntos(d.charsPorEpisodio),
    ),
    (
      'B10 · Línea punteada',
      'Cuántos episodios tiene cada temporada de la serie.',
      _bLineaPunteada(d.epsPorTemporada),
    ),
    (
      'B11 · Línea rápida',
      'Cuántos episodios se estrenaron cada año, de principio a fin de la serie.',
      _bFast(_anios(d)),
    ),
    (
      'B12 · Curva suave',
      'Cuántos personajes aparecen en cada uno de los primeros episodios.',
      _bCurva(d.charsPorEpisodio),
    ),
    (
      'B13 · Línea escalonada',
      'Cuántos personajes hay por estado de vida o muerte.',
      _bEscalones(d.status),
    ),
    (
      'B14 · Área',
      'Cuántos episodios tiene cada temporada, con el volumen total bajo la curva.',
      _bArea(d.epsPorTemporada),
    ),
    (
      'B15 · Área suave',
      'Cuántos personajes aparecen en cada uno de los primeros episodios, con el volumen bajo la curva.',
      _bAreaSuave(d.charsPorEpisodio),
    ),
    (
      'B16 · Área escalonada',
      'Cuántos personajes hay por estado, mostrando el salto de un grupo a otro.',
      _bAreaEscalon(d.status),
    ),
    (
      'B17 · Dispersión',
      'Las ubicaciones o planetas donde más personajes se encuentran, uno por punto.',
      _bDispersion(d.location),
    ),
    (
      'B18 · Burbujas',
      'Cuántos personajes tienen 1, 2-5, 6-10 o más de 10 episodios; más grande, más personajes.',
      _bBurbuja(d.epsPorPersonaje),
    ),
    (
      'B19 · Columnas de rango',
      'Cuántos episodios tiene cada temporada, con su margen de variación alrededor del valor.',
      _bRangoCol(d.epsPorTemporada),
    ),
    (
      'B20 · Banda de área',
      'Cuántos episodios se estrenaron cada año, con la banda de su margen de variación.',
      _bRangoArea(d.epsPorAnio),
    ),
    (
      'B21 · Eje de fechas',
      'Cuántos episodios se estrenaron cada año, situados en su fecha real del calendario.',
      _bFechas(d),
    ),
    (
      'B22 · Columnas redondeadas',
      'Los personajes con más episodios de la serie (top del ranking).',
      _bColRedonda(d.topPersonajesEps),
    ),
    (
      'B23 · Pastel con etiquetas',
      'Cuántos personajes están vivos, muertos o desconocidos, con su cifra en cada rebanada.',
      _bPastel(d.status),
    ),
    (
      'B24 · Pastel con etiquetas exteriores',
      'Qué proporción de personajes pertenece a cada especie, con el nombre de cada una.',
      _bPastelFuera(d.species),
    ),
    (
      'B25 · Pastel con rebanada separada',
      'Cuántos personajes son hombres, mujeres, sin género o desconocidos, destacando el grupo mayor.',
      _bPastelExplotado(d.gender),
    ),
    (
      'B26 · Dona',
      'De qué planetas vienen los personajes: los orígenes más comunes.',
      _bDona(d.origin),
    ),
    (
      'B27 · Dona con centro',
      'Las ubicaciones con más personajes, con el total de personajes en el centro.',
      _bDonaCentro(d.location),
    ),
    (
      'B28 · Dona con leyenda',
      'Cuántos episodios tiene cada temporada, con la lista de temporadas al costado.',
      _bDonaLeyenda(d.epsPorTemporada),
    ),
    (
      'B29 · Pirámide',
      'Los personajes con más episodios de la serie, del más al menos.',
      _bPiramide(d.topPersonajesEps),
    ),
    (
      'B30 · Embudo',
      'Cuántos episodios se estrenaron cada año, de mayor a menor cantidad.',
      _bEmbudo(d.epsPorAnio),
    ),
    (
      'B31 · Barra radial',
      'Las especies más comunes entre los personajes, medidas sobre un círculo.',
      _bRadial(d.species),
    ),
  ];

  List<(String, String, Widget)> _avanzadas(StatsData d) => [
    (
      'A01 · Columnas con tooltip',
      'Las especies más comunes; toca una columna para ver exactamente cuántos personajes hay.',
      _aTooltip(d.species),
    ),
    (
      'A02 · Columnas con degradado',
      'De qué planetas vienen los personajes: los orígenes más comunes.',
      _aGradiente(d.origin),
    ),
    (
      'A03 · Columnas agrupadas',
      'Las ubicaciones con más personajes frente a su promedio, una al lado de la otra.',
      _aAgrupadas(d.location),
    ),
    (
      'A04 · Columnas apiladas con leyenda',
      'Cuántos personajes hay por estado y cuántos no, con la leyenda de cada tramo.',
      _aApiladas(d.status),
    ),
    (
      'A05 · Columnas con barras de error',
      'Los personajes con más episodios y el margen de variación de cada uno.',
      _aError(d.topPersonajesEps),
    ),
    (
      'A06 · Columnas ordenadas',
      'Los años con más estrenos, ordenados de mayor a menor.',
      _aOrden(d.epsPorAnio),
    ),
    (
      'A07 · Color por umbral',
      'Los personajes con más episodios: en verde los que superan el promedio y en rojo los que no.',
      _aUmbral(d.topPersonajesEps),
    ),
    (
      'A08 · Barras apiladas con tooltip',
      'Cuántos episodios tiene cada temporada; toca una barra para ver cada tramo.',
      _aBarraApilada(d.epsPorTemporada),
    ),
    (
      'A09 · Línea con trackball',
      'Cuántos episodios se estrenaron cada año; mantén pulsado y la guía recorre los años mostrando valores.',
      _aTrackball(_anios(d)),
    ),
    (
      'A10 · Línea con marcadores grandes',
      'Cuántos personajes aparecen en cada uno de los primeros episodios; toca un punto para ver su valor.',
      _aPuntos(d.charsPorEpisodio),
    ),
    (
      'A11 · Línea con tendencia',
      'Si los estrenos por año van subiendo o bajando: la tendencia general de la serie.',
      _aTendencia(_anios(d)),
    ),
    (
      'A12 · Promedio punteado',
      'Cuántos episodios tiene cada temporada frente al promedio de la serie.',
      _aPromedio(d.epsPorTemporada),
    ),
    (
      'A13 · Línea con zoom',
      'Cuántos episodios se estrenaron cada año; pellizca y arrastra para ver un tramo concreto.',
      _aZoom(_anios(d)),
    ),
    (
      'A14 · Línea con anotación',
      'El año con más episodios estrenados de toda la serie, señalado en la curva.',
      _aAnotacion(_anios(d)),
    ),
    (
      'A15 · Dos áreas superpuestas',
      'Cuántos episodios se estrenaron cada año y cuántos llevamos acumulados en total.',
      _aDosAreas(d.epsPorAnio),
    ),
    (
      'A16 · Área con degradado',
      'Cuántos personajes aparecen en cada uno de los primeros episodios, con más peso en los picos.',
      _aAreaGradiente(d.charsPorEpisodio),
    ),
    (
      'A17 · Dispersión con tooltip',
      'Cuántos personajes aparecen en cada episodio; toca un punto para ver su valor exacto.',
      _aDispersion(d.charsPorEpisodio),
    ),
    (
      'A18 · Burbujas con leyenda',
      'Los personajes con más episodios; a mayor burbuja, más episodios. Toca una para ver su cifra.',
      _aBurbuja(d.topPersonajesEps),
    ),
    (
      'A19 · Eje logarítmico',
      'Cuántos episodios se estrenaron cada año, en escala logarítmica para ver mejor los rangos.',
      _aLog(d.epsPorAnio),
    ),
    (
      'A20 · Media móvil (SMA)',
      'La tendencia de estrenos por año, suavizada con el promedio de 3 años.',
      _aSma(_anios(d)),
    ),
    (
      'A21 · Banda objetivo',
      'Las especies más comunes, resaltando las que están por encima del promedio.',
      _aBanda(d.species),
    ),
    (
      'A22 · Dato faltante',
      'Cuántos personajes aparecen en cada episodio, dejando visible un episodio sin datos.',
      _aFaltante(d.charsPorEpisodio),
    ),
    (
      'A23 · Pastel con tooltip',
      'Qué proporción de personajes está vivo, muerto o desconocido; toca una rebanada para ver su cifra.',
      _aPastel(d.status),
    ),
    (
      'A24 · Pastel con selección',
      'Cuántos personajes son hombres, mujeres o desconocidos; toca una rebanada para resaltarla.',
      _aPastelSel(d.gender),
    ),
    (
      'A25 · Dona con leyenda y tooltip',
      'De qué planetas vienen los personajes; toca un sector para ver cuántos hay en cada origen.',
      _aDona(d.origin),
    ),
    (
      'A26 · Dona explotada al tocar',
      'Las ubicaciones con más personajes; toca un sector para separarlo y verlo con claridad.',
      _aDonaExplota(d.location),
    ),
    (
      'A27 · Radial con etiquetas',
      'Las especies más comunes, con cuántos personajes hay de cada una dentro de cada barra.',
      _aRadial(d.species),
    ),
    (
      'A28 · Pirámide con selección',
      'Los personajes con más episodios; toca un nivel para resaltar a ese personaje.',
      _aPiramide(d.topPersonajesEps),
    ),
    (
      'A29 · Embudo con tooltip',
      'Cuántos episodios se estrenaron cada año, con su cifra en cada tramo; toca para el detalle.',
      _aEmbudo(d.epsPorAnio),
    ),
    (
      'A30 · Doble eje',
      'Cuántos episodios tiene cada temporada contra su promedio, cada uno en su propio eje.',
      _aDobleEje(d.epsPorTemporada),
    ),
    (
      'A31 · Waterfall',
      'Cómo se van sumando los episodios año a año hasta el total de la serie.',
      _aWaterfall(d.epsPorAnio),
    ),
    (
      'A32 · Combo con acumulado',
      'Cuántos episodios se estrenaron cada año y el total acumulado de la serie.',
      _aCombo(_anios(d)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('syncfusion', style: T.title)),
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
