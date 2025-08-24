import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:muscle_monitoring/config/router/app_router.dart';
import 'package:muscle_monitoring/config/theme/app_theme.dart';

void main() {
  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
  WidgetsFlutterBinding.ensureInitialized();
  // _requestPermissions().then((_) {
    runApp(const MainApp());
  // });
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      getPages: AppRouter.routes,
      debugShowCheckedModeBanner: false,
      theme: AppTheme().getTheme(),
    );
  }
}


