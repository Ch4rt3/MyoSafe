import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

enum BleConnectionState { idle, connecting, connected, disconnected }

class BleDataPoint {
  final double x;
  final double y;
  BleDataPoint(this.x, this.y);
}

class BleNotifier extends StateNotifier<List<BleDataPoint>> {
  BleNotifier() : super([]);

  BleConnectionState connectionState = BleConnectionState.idle;
  BluetoothDevice? currentDevice;
  double _xValue = 0;

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  void setConnectionState(BleConnectionState newState) {
    connectionState = newState;
  }

  void addData(double y) {
    // x es el tiempo o el índice
    state = [...state, BleDataPoint(_xValue, y)];
    _xValue += 1;
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
    currentDevice = device;
    setConnectionState(BleConnectionState.connecting);
    try {
      await device.connect(timeout: Duration(seconds: 15));
      setConnectionState(BleConnectionState.connected);
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.connected) {
          setConnectionState(BleConnectionState.connected);
        } else if (state == BluetoothConnectionState.disconnected) {
          setConnectionState(BleConnectionState.disconnected);
          currentDevice = null;
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
          // value es List<int>, puedes procesarlo aquí
          // Por ejemplo, si solo te interesa el primer valor:
          if (value.isNotEmpty) {
            addData(value.first.toDouble());
          }
        });
      }
    } catch (e) {
      setConnectionState(BleConnectionState.disconnected);
      currentDevice = null;
    }
  }
}

final bleProvider = StateNotifierProvider<BleNotifier, List<BleDataPoint>>(
  (ref) => BleNotifier(),
);
