import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muscle_monitoring/presentation/providers/ble_provider.dart';
import 'package:muscle_monitoring/presentation/widgets/ble/device_card.dart';

class BleScreen extends ConsumerWidget {
  static const String name = 'ble-screen';

  const BleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleController = ref.read(bleProvider.notifier);
    // final receivedDataList = ref.watch(bleProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Prueba de concepto')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: StreamBuilder<List<ScanResult>>(
              stream: bleController.scanResults,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final data = snapshot.data![index];
                      return DeviceCard(
                        data: data,
                        bleController: bleController,
                      );
                    },
                  );
                } else {
                  return Center(child: Text('No device founds'));
                }
              },
            ),
          ),
          SizedBox(height: 40),
          // Text("Datos recibidos"),
          // Column(
          //   children: receivedDataList
          //       .map((data) => Text(data.toString()))
          //       .toList(),
          // ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => bleController.startDevicesScan(),
            child: Text('Start Scan BLE'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => bleController.stopDevicesScan(),
            child: Text('Stop Scan BLE'),
          ),
        ],
      ),
    );
  }
}
