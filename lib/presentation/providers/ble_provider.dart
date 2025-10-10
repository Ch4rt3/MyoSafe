// Provider para el índice de la pestaña actual
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
  final List<BleDataPoint> data;
  final BleConnectionState connectionState;
  final BluetoothDevice? currentDevice;

  BleState({
    required this.data,
    required this.connectionState,
    required this.currentDevice,
  });

  BleState copyWith({
    List<BleDataPoint>? data,
    BleConnectionState? connectionState,
    BluetoothDevice? currentDevice,
  }) {
    return BleState(
      data: data ?? this.data,
      connectionState: connectionState ?? this.connectionState,
      currentDevice: currentDevice ?? this.currentDevice,
    );
  }
}

class BleNotifier extends StateNotifier<BleState> {
  BleNotifier()
    : super(
        BleState(
          data: [],
          connectionState: BleConnectionState.idle,
          currentDevice: null,
        ),
      );

  double _xValue = 0;

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  void setConnectionState(BleConnectionState newState) {
    state = state.copyWith(connectionState: newState);
  }

  void setCurrentDevice(BluetoothDevice? device) {
    state = state.copyWith(currentDevice: device);
  }

  void addData(double y) {
    final newData = [...state.data, BleDataPoint(_xValue, y)];
    _xValue += 1;
    state = state.copyWith(data: newData);
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

      List<BluetoothService> services = await device.discoverServices();
      BluetoothCharacteristic? targetCharacteristic;
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
            targetCharacteristic = characteristic;
            break;
          }
        }
      }
      if (targetCharacteristic != null) {
        targetCharacteristic.setNotifyValue(true);
        targetCharacteristic.lastValueStream.listen((value) {
          if (value.isNotEmpty) {
            addData(value.first.toDouble());
          }
        });
      }
    } catch (e) {
      setConnectionState(BleConnectionState.disconnected);
      setCurrentDevice(null);
    }
  }
}

final bleProvider = StateNotifierProvider<BleNotifier, BleState>(
  (ref) => BleNotifier(),
);
