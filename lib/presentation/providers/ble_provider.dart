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
  final Random _rand = Random();
  // UUIDs esperadas del ESP32
  static const String serviceFuerzaUuid =
      '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const String charFuerzaUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';

  static const String serviceFatigaUuid =
      '6b2f0001-0000-1000-8000-00805f9b34fb';
  static const String charFatigaUuid = '6b2f0002-0000-1000-8000-00805f9b34fb';

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  void setConnectionState(BleConnectionState newState) {
    state = state.copyWith(connectionState: newState);
  }

  void setCurrentDevice(BluetoothDevice? device) {
    state = state.copyWith(currentDevice: device);
    // Si se desconecta, detenemos la simulación (si estaba corriendo)
    if (device == null) {
      _simTimer?.cancel();
      _simTimer = null;
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
      await device.connect(timeout: Duration(seconds: 15));
      setConnectionState(BleConnectionState.connected);
      device.connectionState.listen((connState) {
        if (connState == BluetoothConnectionState.connected) {
          setConnectionState(BleConnectionState.connected);
        } else if (connState == BluetoothConnectionState.disconnected) {
          setConnectionState(BleConnectionState.disconnected);
          setCurrentDevice(null);
        }
      });

      // --- Código original para descubrir servicios y suscribirse a notificaciones ---
      List<BluetoothService> services = await device.discoverServices();

      BluetoothCharacteristic? fuerzaChar;
      BluetoothCharacteristic? fatigaChar;

      for (var service in services) {
        final svcUuid = service.uuid.toString();
        for (var characteristic in service.characteristics) {
          final charUuid = characteristic.uuid.toString();
          if (charUuid == charFuerzaUuid || svcUuid == serviceFuerzaUuid) {
            fuerzaChar = characteristic;
          }
          if (charUuid == charFatigaUuid || svcUuid == serviceFatigaUuid) {
            fatigaChar = characteristic;
          }
        }
      }

      if (fuerzaChar != null) {
        await fuerzaChar.setNotifyValue(true);
        fuerzaChar.lastValueStream.listen((value) {
          if (value.isNotEmpty) {
            final v = value.first.toDouble();
            addFuerza(v);
          }
        });
      }

      if (fatigaChar != null) {
        await fatigaChar.setNotifyValue(true);
        fatigaChar.lastValueStream.listen((value) {
          if (value.isNotEmpty) {
            final v = value.first.toDouble();
            addFatiga(v);
          }
        });
      }

      // --- Modo simulación: generar datos aleatorios 0..255 para Fuerza y Fatiga ---
      // _simTimer?.cancel();
      // _simTimer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      //   final f = _rand.nextInt(256).toDouble();
      //   final fa = _rand.nextInt(256).toDouble();
      //   addFuerza(f);
      //   addFatiga(fa);
      // });
    } catch (e) {
      setConnectionState(BleConnectionState.disconnected);
      setCurrentDevice(null);
    }
  }
}

final bleProvider = StateNotifierProvider<BleNotifier, BleState>(
  (ref) => BleNotifier(),
);
