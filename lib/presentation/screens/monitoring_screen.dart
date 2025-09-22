import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

import 'package:muscle_monitoring/presentation/providers/ble_provider.dart';

class MonitoringScreen extends StatelessWidget {
  static const name = 'monitoring-screen';
  final String deviceName;

  const MonitoringScreen({super.key, required this.deviceName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _MonitoringScreenView());
  }
}

class _MonitoringScreenView extends StatelessWidget {
  const _MonitoringScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          toolbarHeight: 40,
          floating: true,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: EdgeInsets.zero,
            centerTitle: false,
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            return Column(children: [_MonitoringChart()]);
          }, childCount: 1),
        ),
      ],
    );
  }
}

class _MonitoringChart extends ConsumerStatefulWidget {
  const _MonitoringChart();

  final Color sinColor = Colors.blue;
  final Color cosColor = Colors.pink;

  @override
  ConsumerState<_MonitoringChart> createState() => _MonitoringChartState();
}

class _MonitoringChartState extends ConsumerState<_MonitoringChart> {
  final limitCount = 100;
  final sinPoints = <FlSpot>[];
  final cosPoints = <FlSpot>[];

  double xValue = 0;
  double step = 0.05;

  late Timer timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      while (sinPoints.length > limitCount) {
        sinPoints.removeAt(0);
        cosPoints.removeAt(0);
      }
      setState(() {
        sinPoints.add(FlSpot(xValue, math.sin(xValue)));
        cosPoints.add(FlSpot(xValue, math.cos(xValue)));
      });
      xValue += step;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bleDataList = ref.watch(bleProvider); // List<BleDataPoint>
    final points = bleDataList.map((e) => FlSpot(e.x, e.y)).toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        if (points.isNotEmpty) ...[
          Text(
            'x: ${points.last.x.toStringAsFixed(1)}',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'y: ${points.last.y.toStringAsFixed(1)}',
            style: TextStyle(
              color: widget.sinColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ] else ...[
          Text(
            'Esperando datos...',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 1.5,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: LineChart(
              LineChartData(
                minY: points.isNotEmpty
                    ? points.map((e) => e.y).reduce((a, b) => a < b ? a : b)
                    : 0,
                maxY: points.isNotEmpty
                    ? points.map((e) => e.y).reduce((a, b) => a > b ? a : b)
                    : 1,
                minX: points.isNotEmpty ? points.first.x : 0,
                maxX: points.isNotEmpty ? points.last.x : 100,
                lineTouchData: const LineTouchData(enabled: false),
                clipData: const FlClipData.all(),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                lineBarsData: points.isNotEmpty
                    ? [
                        LineChartBarData(
                          spots: points,
                          dotData: const FlDotData(show: false),
                          gradient: LinearGradient(
                            colors: [
                              widget.sinColor.withAlpha(0),
                              widget.sinColor,
                            ],
                            stops: const [0.1, 1.0],
                          ),
                          barWidth: 4,
                          isCurved: false,
                        ),
                      ]
                    : [],
                titlesData: const FlTitlesData(show: false),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }
}
