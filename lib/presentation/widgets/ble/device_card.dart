import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muscle_monitoring/presentation/providers/ble_provider.dart';
import 'package:muscle_monitoring/presentation/providers/page_index_provider.dart';

class DeviceCard extends ConsumerWidget {
  final ScanResult data;
  final BleNotifier bleController;

  const DeviceCard({
    super.key,
    required this.data,
    required this.bleController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(bleProvider).connectionState;
    final currentDevice = ref.watch(bleProvider).currentDevice;

    final isCurrent = currentDevice?.remoteId == data.device.remoteId;

    // 👇 definimos un solo "estado visual" para este dispositivo
    final deviceStatus = switch (connectionState) {
      BleConnectionState.connecting when isCurrent => 'connecting',
      BleConnectionState.connected when isCurrent => 'connected',
      _ => 'idle',
    };

    // 👇 widgets según estado
    Widget trailing = switch (deviceStatus) {
      'connecting' => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      'connected' => const Icon(Icons.check_circle, color: Colors.green),
      _ => Text('${data.rssi}'),
    };

    // 👇 color y desactivación según estado global
    final isDisabled =
        connectionState == BleConnectionState.connecting && !isCurrent;

    return IgnorePointer(
      ignoring: isDisabled,
      child: Card(
        elevation: 2,
        color: deviceStatus == 'connected'
            ? Colors.blue.shade100
            : Colors.white,
        child: ListTile(
          title: Text(
            data.device.advName.isNotEmpty
                ? data.device.advName
                : 'Unknown Device',
          ),
          subtitle: Text(data.device.remoteId.str),
          trailing: trailing,
          onTap: isDisabled
              ? null
              : () async {
                  await bleController.connectDevice(data.device);
                  // Cambia a la pestaña de monitoreo
                  ref.read(pageIndexProvider.notifier).state = 1;
                },
        ),
      ),
    );
  }
}
