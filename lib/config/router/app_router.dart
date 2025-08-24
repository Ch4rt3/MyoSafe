import 'package:get/get.dart';
import 'package:muscle_monitoring/presentation/screens/ble_screen.dart';


class AppRouter {
  static final List<GetPage> routes = [
    GetPage(name: '/', page: () => BleScreen()),
  ];
}
