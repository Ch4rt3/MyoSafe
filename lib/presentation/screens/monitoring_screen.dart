import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:muscle_monitoring/presentation/providers/ble_provider.dart';

class MonitoringScreen extends StatelessWidget {
  static const name = 'monitoring-screen';

  const MonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: _MonitoringScreenView());
  }
}

class _MonitoringScreenView extends ConsumerWidget {
  const _MonitoringScreenView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var deviceName = ref.watch(bleProvider).currentDevice?.advName;

    if (deviceName != null && deviceName.isEmpty) {
      deviceName = 'dispositivo';
    }

    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          title: Text('Monitoreo muscular', style: TextStyle(fontSize: 20)),
          toolbarHeight: 40,
          floating: true,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: EdgeInsets.zero,
            centerTitle: false,
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            return Column(
              children: [
                (deviceName != null)
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('Conectado a $deviceName'),
                      )
                    : const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('Esperando conexion...'),
                      ),

                const SizedBox(height: 12),
                // Chart de Fuerza
                SectionChart(
                  title: 'Fuerza',
                  color: Colors.blue,
                  getPoints: (ref) => ref.watch(bleProvider).dataFuerza,
                ),
                const SizedBox(height: 16),
                // Chart de Fatiga
                SectionChart(
                  title: 'Fatiga',
                  color: Colors.pink,
                  getPoints: (ref) => ref.watch(bleProvider).dataFatiga,
                ),
                const SizedBox(height: 24),
              ],
            );
          }, childCount: 1),
        ),
      ],
    );
  }
}

typedef PointsSelector = List<BleDataPoint> Function(WidgetRef ref);

class SectionChart extends ConsumerWidget {
  final String title;
  final Color color;
  final PointsSelector getPoints;
  final int visiblePoints;

  const SectionChart({
    super.key,
    required this.title,
    required this.color,
    required this.getPoints,
    this.visiblePoints = 120,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = getPoints(ref);
    final recent = data.length <= visiblePoints
        ? data
        : data.sublist(data.length - visiblePoints);

    final points = List<FlSpot>.generate(recent.length, (i) {
      return FlSpot(i.toDouble(), recent[i].y);
    });

    final lastValue = recent.isNotEmpty ? recent.last.y : null;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Spacer(),
                Text(
                  lastValue != null ? lastValue.toStringAsFixed(0) : '--',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: points.isNotEmpty
                  ? LineChart(
                      LineChartData(
                        minY: points
                            .map((e) => e.y)
                            .reduce((a, b) => a < b ? a : b),
                        maxY: points
                            .map((e) => e.y)
                            .reduce((a, b) => a > b ? a : b),
                        minX: 0,
                        maxX: visiblePoints.toDouble(),
                        lineTouchData: const LineTouchData(enabled: false),
                        clipData: const FlClipData.all(),
                        gridData: const FlGridData(
                          show: true,
                          drawVerticalLine: false,
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: points,
                            dotData: const FlDotData(show: false),
                            gradient: LinearGradient(
                              colors: [color.withAlpha(0), color],
                              stops: const [0.1, 1.0],
                            ),
                            barWidth: 3,
                            isCurved: false,
                          ),
                        ],
                        titlesData: const FlTitlesData(show: false),
                      ),
                    )
                  : const Center(child: Text('Esperando datos...')),
            ),
          ],
        ),
      ),
    );
  }
}
