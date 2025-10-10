import 'package:go_router/go_router.dart';
import 'package:muscle_monitoring/presentation/screens/ble_screen.dart';
import 'package:muscle_monitoring/presentation/screens/home_screen.dart';
import 'package:muscle_monitoring/presentation/screens/monitoring_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/home/0',
    routes: [
      GoRoute(
        path: '/home/:page',
        name: BleScreen.name,
        builder: (context, state) {
          int.parse(state.pathParameters['page'] ?? '0');

          return HomeScreen();
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) {
              return const BleScreen();
            },
          ),
          GoRoute(
            path: '/device',
            name: MonitoringScreen.name,
            builder: (context, state) {
              return MonitoringScreen();
            },
          ),
        ],
      ),
      GoRoute(path: '/', redirect: (_, __) => '/home/0'),
    ],
  );
}
