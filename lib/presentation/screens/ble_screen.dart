import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:muscle_monitoring/controller/ble_controller.dart';

class BleScreen extends StatelessWidget {
  const BleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('BLE scanner')),
      body: GetBuilder<BleController>(
        init: BleController(),
        builder: (controller) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: StreamBuilder<List<ScanResult>>(
                  stream: controller.scanResults,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final data = snapshot.data![index];
                          return Card(
                            elevation: 2,
                            child: ListTile(
                              title: Text(data.device.advName),
                              subtitle: Text(data.device.remoteId.str),
                              trailing: Text(data.rssi.toString()),
                              onTap: () =>
                                  controller.connectDevice(data.device),
                            ),
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
              Text("Datos recibidos"),
              Obx(
                () => Column(
                  children: controller.receivedDataList
                      .map((data) => Text(data.toString()))
                      .toList(),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => controller.startDevicesScan(),
                child: Text('Start Scan BLE'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => controller.stopDevicesScan(),
                child: Text('Stop Scan BLE'),
              ),
            ],
          );
        },
      ),
    );
  }
}
