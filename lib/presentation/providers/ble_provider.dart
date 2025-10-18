// Provider para el índice de la pestaña actual
import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

// final pageIndexProvider = StateProvider<int>((ref) => 0);

enum BleConnectionState { idle, connecting, connected, disconnected }

class BleDataPoint {
  final double x;
  final double y;
  BleDataPoint(this.x, this.y);
}

class BleState {
  final List<BleDataPoint> dataFuerza;
  final List<BleDataPoint> dataFatiga;
  final BleConnectionState connectionState;
  final BluetoothDevice? currentDevice;

  BleState({
    required this.dataFuerza,
    required this.dataFatiga,
    required this.connectionState,
    required this.currentDevice,
  });

  BleState copyWith({
    List<BleDataPoint>? dataFuerza,
    List<BleDataPoint>? dataFatiga,
    BleConnectionState? connectionState,
    BluetoothDevice? currentDevice,
  }) {
    return BleState(
      dataFuerza: dataFuerza ?? this.dataFuerza,
      dataFatiga: dataFatiga ?? this.dataFatiga,
      connectionState: connectionState ?? this.connectionState,
      currentDevice: currentDevice ?? this.currentDevice,
    );
  }
}

class BleNotifier extends StateNotifier<BleState> {
  BleNotifier()
    : super(
        BleState(
          dataFuerza: [],
          dataFatiga: [],
          connectionState: BleConnectionState.idle,
          currentDevice: null,
        ),
      );

  double _xValue = 0;
  // Máximo de puntos a mantener en memoria (ajusta según rendimiento/UX)
  final int maxDataPoints = 200;
  Timer? _simTimer;
  // ignore: unused_field
  final Random _rand = Random(); // Usado en modo simulación (comentado abajo)

  // Subscripciones a los streams BLE (para cancelarlas al desconectar)
  StreamSubscription? _fuerzaSubscription;
  StreamSubscription? _fatigaSubscription;

  // UUIDs esperadas del ESP32 (en minúsculas para comparación)
  static const String serviceFuerzaUuid =
      '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const String charFuerzaUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';

  // UUIDs de FATIGA (formato completo y corto)
  static const String serviceFatigaUuid =
      '6b2f0001-0000-1000-8000-00805f9b34fb';
  static const String serviceFatigaUuidCorto =
      '6b2f0001'; // UUID corto (16-bit)

  static const String charFatigaUuid = '6b2f0002-0000-1000-8000-00805f9b34fb';
  static const String charFatigaUuidCorto = '6b2f0002'; // UUID corto (16-bit)

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  void setConnectionState(BleConnectionState newState) {
    state = state.copyWith(connectionState: newState);
  }

  void setCurrentDevice(BluetoothDevice? device) {
    state = state.copyWith(currentDevice: device);
    // Si se desconecta, cancelamos todas las suscripciones y timers
    if (device == null) {
      _simTimer?.cancel();
      _simTimer = null;
      _fuerzaSubscription?.cancel();
      _fuerzaSubscription = null;
      _fatigaSubscription?.cancel();
      _fatigaSubscription = null;
    }
  }

  void addFuerza(double y) {
    final newData = [...state.dataFuerza, BleDataPoint(_xValue, y)];
    if (newData.length > maxDataPoints) {
      final excess = newData.length - maxDataPoints;
      newData.removeRange(0, excess);
    }
    _xValue += 1;
    state = state.copyWith(dataFuerza: newData);
  }

  void addFatiga(double y) {
    final newData = [...state.dataFatiga, BleDataPoint(_xValue, y)];
    if (newData.length > maxDataPoints) {
      final excess = newData.length - maxDataPoints;
      newData.removeRange(0, excess);
    }
    _xValue += 1;
    state = state.copyWith(dataFatiga: newData);
  }

  Future<void> startDevicesScan() async {
    if (await Permission.locationWhenInUse.request().isGranted) {
      if (await Permission.bluetoothScan.request().isGranted) {
        if (await Permission.bluetoothConnect.request().isGranted) {
          await FlutterBluePlus.startScan(timeout: Duration(seconds: 10));
        }
      }
    }
  }

  Future<void> stopDevicesScan() async {
    if (await Permission.bluetoothScan.request().isGranted) {
      if (await Permission.bluetoothConnect.request().isGranted) {
        FlutterBluePlus.stopScan();
      }
    }
  }

  Future<void> connectDevice(BluetoothDevice device) async {
    setCurrentDevice(device);
    setConnectionState(BleConnectionState.connecting);

    try {
      // Conectar al dispositivo
      await device.connect(timeout: Duration(seconds: 15));
      print('✅ Conectado al dispositivo: ${device.platformName}');

      setConnectionState(BleConnectionState.connected);

      // Escuchar cambios de estado de conexión
      device.connectionState.listen((connState) {
        if (connState == BluetoothConnectionState.connected) {
          setConnectionState(BleConnectionState.connected);
        } else if (connState == BluetoothConnectionState.disconnected) {
          print('❌ Dispositivo desconectado');
          setConnectionState(BleConnectionState.disconnected);
          setCurrentDevice(null);
        }
      });

      // ⏳ DELAY IMPORTANTE: Esperar a que el dispositivo esté completamente listo
      await Future.delayed(const Duration(seconds: 2));
      print('🔍 Iniciando descubrimiento de servicios...');

      // Descubrir servicios BLE
      List<BluetoothService> services = await device.discoverServices();
      print('📡 Servicios descubiertos: ${services.length}');
      print('');
      print('═══════════════════════════════════════════════════════');
      print('🔎 LISTADO COMPLETO DE SERVICIOS Y CARACTERÍSTICAS');
      print('═══════════════════════════════════════════════════════');

      BluetoothCharacteristic? fuerzaChar;
      BluetoothCharacteristic? fatigaChar;

      // Recorrer servicios y características CON LOGGING DETALLADO
      for (int i = 0; i < services.length; i++) {
        var service = services[i];
        final svcUuid = service.uuid.toString().toLowerCase();

        print('');
        print('┌─ SERVICIO #${i + 1}');
        print('│  UUID: $svcUuid');
        print('│  UUID Original: ${service.uuid.toString()}');
        print('│  Características: ${service.characteristics.length}');

        // Comparar con UUIDs esperados
        bool esFuerza = svcUuid == serviceFuerzaUuid.toLowerCase();
        bool esFatiga =
            svcUuid == serviceFatigaUuid.toLowerCase() ||
            svcUuid == serviceFatigaUuidCorto.toLowerCase();

        if (esFuerza) {
          print('│  ✅ ¡Este es el servicio de FUERZA!');
        }
        if (esFatiga) {
          print('│  ✅ ¡Este es el servicio de FATIGA!');
        }
        if (!esFuerza && !esFatiga) {
          print('│  ℹ️  Servicio desconocido/genérico');
        }

        print('│');

        for (int j = 0; j < service.characteristics.length; j++) {
          var characteristic = service.characteristics[j];
          final charUuid = characteristic.uuid.toString().toLowerCase();

          print('│  ├─ Characteristic #${j + 1}');
          print('│  │   UUID: $charUuid');
          print('│  │   UUID Original: ${characteristic.uuid.toString()}');
          print('│  │   Properties: ${characteristic.properties}');

          // Comparar con UUIDs esperados
          bool esCharFuerza = charUuid == charFuerzaUuid.toLowerCase();
          bool esCharFatiga =
              charUuid == charFatigaUuid.toLowerCase() ||
              charUuid == charFatigaUuidCorto.toLowerCase();

          if (esCharFuerza) {
            print('│  │   ✅ ¡Esta es la characteristic de FUERZA!');
          }
          if (esCharFatiga) {
            print('│  │   ✅ ¡Esta es la characteristic de FATIGA!');
          }

          // ✅ CORRECCIÓN: Comparar correctamente cada UUID
          // Buscar characteristic de FUERZA
          if (svcUuid == serviceFuerzaUuid.toLowerCase() &&
              charUuid == charFuerzaUuid.toLowerCase()) {
            fuerzaChar = characteristic;
            print('│  │   💪 ¡ASIGNADA como characteristic de FUERZA!');
          }

          // Buscar characteristic de FATIGA (soporta UUID corto y largo)
          if ((svcUuid == serviceFatigaUuid.toLowerCase() ||
                  svcUuid == serviceFatigaUuidCorto.toLowerCase()) &&
              (charUuid == charFatigaUuid.toLowerCase() ||
                  charUuid == charFatigaUuidCorto.toLowerCase())) {
            fatigaChar = characteristic;
            print('│  │   ⚡ ¡ASIGNADA como characteristic de FATIGA!');
          }

          print('│  │');
        }
        print('└─────────────────────────────────────────────────');
      }

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📊 RESUMEN DE DETECCIÓN');
      print('═══════════════════════════════════════════════════════');
      print('UUIDs ESPERADOS:');
      print('  Fuerza Service:  ${serviceFuerzaUuid.toLowerCase()}');
      print('  Fuerza Char:     ${charFuerzaUuid.toLowerCase()}');
      print(
        '  Fatiga Service:  ${serviceFatigaUuid.toLowerCase()} O $serviceFatigaUuidCorto',
      );
      print(
        '  Fatiga Char:     ${charFatigaUuid.toLowerCase()} O $charFatigaUuidCorto',
      );
      print('');
      print('RESULTADO:');
      print(
        '  Fuerza Char encontrada: ${fuerzaChar != null ? "✅ SÍ" : "❌ NO"}',
      );
      print(
        '  Fatiga Char encontrada: ${fatigaChar != null ? "✅ SÍ" : "❌ NO"}',
      );
      print('═══════════════════════════════════════════════════════');
      print('');

      // Suscribirse a la characteristic de FUERZA
      if (fuerzaChar != null) {
        print('🔔 Activando notificaciones de FUERZA...');
        await fuerzaChar.setNotifyValue(true);

        // Cancelar suscripción anterior si existe
        await _fuerzaSubscription?.cancel();

        _fuerzaSubscription = fuerzaChar.lastValueStream.listen(
          (value) {
            if (value.isNotEmpty) {
              final v = value.first.toDouble();
              //print('💪 Fuerza recibida: $v');
              addFuerza(v);
            }
          },
          onError: (error) {
            print('❌ Error en stream de fuerza: $error');
          },
        );

        print('✅ Suscrito a notificaciones de FUERZA');
      } else {
        print('⚠️ No se encontró la characteristic de FUERZA');
      }

      // Suscribirse a la characteristic de FATIGA
      if (fatigaChar != null) {
        print('🔔 Activando notificaciones de FATIGA...');
        await fatigaChar.setNotifyValue(true);

        // Cancelar suscripción anterior si existe
        await _fatigaSubscription?.cancel();

        _fatigaSubscription = fatigaChar.lastValueStream.listen(
          (value) {
            if (value.isNotEmpty) {
              final v = value.first.toDouble();
              //print('⚡ Fatiga recibida: $v');
              addFatiga(v);
            }
          },
          onError: (error) {
            print('❌ Error en stream de fatiga: $error');
          },
        );

        print('✅ Suscrito a notificaciones de FATIGA');
      } else {
        print('⚠️ No se encontró la characteristic de FATIGA');
      }

      // Resumen final
      if (fuerzaChar != null && fatigaChar != null) {
        print('🎉 Ambas características configuradas correctamente');
      } else if (fuerzaChar != null || fatigaChar != null) {
        print('⚠️ Solo una característica está disponible');
      } else {
        print('❌ No se encontraron las características esperadas');
      }

      // --- Modo simulación (comentado, descomentar si necesitas probar sin hardware) ---
      // _simTimer?.cancel();
      // _simTimer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      //   final f = _rand.nextInt(256).toDouble();
      //   final fa = _rand.nextInt(256).toDouble();
      //   addFuerza(f);
      //   addFatiga(fa);
      // });
    } catch (e) {
      print('❌ Error al conectar: $e');
      setConnectionState(BleConnectionState.disconnected);
      setCurrentDevice(null);
    }
  }

  /// Desconectar dispositivo BLE limpiamente
  Future<void> disconnectDevice() async {
    final device = state.currentDevice;
    if (device == null) return;

    try {
      print('🔌 Desconectando dispositivo...');

      // Cancelar suscripciones
      await _fuerzaSubscription?.cancel();
      _fuerzaSubscription = null;

      await _fatigaSubscription?.cancel();
      _fatigaSubscription = null;

      // Cancelar timer de simulación
      _simTimer?.cancel();
      _simTimer = null;

      // Desconectar
      await device.disconnect();

      setConnectionState(BleConnectionState.disconnected);
      setCurrentDevice(null);

      print('✅ Dispositivo desconectado correctamente');
    } catch (e) {
      print('❌ Error al desconectar: $e');
    }
  }

  @override
  void dispose() {
    // Limpiar recursos al destruir el provider
    _fuerzaSubscription?.cancel();
    _fatigaSubscription?.cancel();
    _simTimer?.cancel();
    super.dispose();
  }
}

final bleProvider = StateNotifierProvider<BleNotifier, BleState>(
  (ref) => BleNotifier(),
);
