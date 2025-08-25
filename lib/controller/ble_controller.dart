import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class BleController extends GetxController {
  // Variable observable para los datos recibidos
  final receivedDataList = RxList<List<int>>([]);
  Future startDevicesScan() async {
    if (await Permission.locationWhenInUse.request().isGranted) {
      if (await Permission.bluetoothScan.request().isGranted) {
        if (await Permission.bluetoothConnect.request().isGranted) {
          await FlutterBluePlus.startScan(
            // androidScanMode: AndroidScanMode.lowLatency,
            timeout: Duration(seconds: 10),
          );
        }
      }
    }
  }

  Future stopDevicesScan() async {
    if (await Permission.bluetoothScan.request().isGranted) {
      if (await Permission.bluetoothConnect.request().isGranted) {
        FlutterBluePlus.stopScan();
      }
    }
  }

  Future<void> connectDevice(BluetoothDevice device) async {
    print(device);
    await device.connect(timeout: Duration(seconds: 15));
    device.connectionState.listen((state) {
      switch (state) {
        case BluetoothConnectionState.connected:
          print('Conectado');
          break;
        case BluetoothConnectionState.disconnected:
          print('Desconectado');
          break;
        default:
          print('Estado ${BluetoothConnectionState.values}');
      }
    });

    List<BluetoothService> services = await device.discoverServices();

    BluetoothCharacteristic? targetCharacteristic;

    for (var service in services) {
      // print("Service: ${service.uuid}");
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.notify) {
          // print("Characteristic: ${characteristic.uuid} -> ${characteristic.properties}",);
          targetCharacteristic = characteristic;
          break;
        }
      }
    }

    if (targetCharacteristic != null) {
      targetCharacteristic.setNotifyValue(true);
      targetCharacteristic.lastValueStream.listen((value) {
        receivedDataList.add(value);
        print('Datos recibidos $value');
      });
    }
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;
}
