import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muscle_monitoring/presentation/providers/page_index_provider.dart';
import 'package:muscle_monitoring/presentation/screens/ble_screen.dart';
import 'package:muscle_monitoring/presentation/screens/monitoring_screen.dart';
import 'package:muscle_monitoring/presentation/widgets/shared/custom_bottom_navigation.dart';

class HomeScreen extends ConsumerWidget {
  static const name = 'home-screen';

  const HomeScreen({super.key});

  final viewRoutes = const <Widget>[BleScreen(), MonitoringScreen()];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageIndex = ref.watch(pageIndexProvider);
    return Scaffold(
      body: IndexedStack(index: pageIndex, children: viewRoutes),
      bottomNavigationBar: CustomBottomNavigation(),
    );
  }
}
