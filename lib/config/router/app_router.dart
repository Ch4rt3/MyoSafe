import 'package:go_router/go_router.dart';
import 'package:muscle_monitoring/presentation/screens/ble_screen.dart';
import 'package:muscle_monitoring/presentation/screens/monitoring_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: BleScreen.name,
        builder: (context, state) => BleScreen(),
        routes: [
          GoRoute(
            path: '/device/:name',
            name: MonitoringScreen.name,
            builder: (context, state) {
              final deviceName = state.pathParameters['name'] ?? 'no-name';
              return MonitoringScreen(deviceName: deviceName);
            },
          ),
        ],
      ),
      // Puedes agregar más rutas aquí
    ],
  );
}
