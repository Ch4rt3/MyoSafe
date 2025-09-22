import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:muscle_monitoring/presentation/providers/ble_provider.dart';

class DeviceCard extends ConsumerWidget {
  final ScanResult data;
  final BleNotifier bleController;

  const DeviceCard({
    super.key,
    required this.data,
    required this.bleController,
  });

  @override
  Widget build(BuildContext context, ref) {
    final bleNotifier = ref.watch(bleProvider.notifier);
    final connectionState = bleNotifier.connectionState;

    // Verificar si este es el dispositivo actual
    final isCurrentDevice =
        bleNotifier.currentDevice?.remoteId == data.device.remoteId;
    final isConnecting =
        connectionState == BleConnectionState.connecting && isCurrentDevice;
    final isConnected =
        connectionState == BleConnectionState.connected && isCurrentDevice;
    final isDisabled =
        (connectionState == BleConnectionState.connecting ||
            connectionState == BleConnectionState.connected) &&
        !isCurrentDevice;

    Color cardColor = Colors.white;
    if (isConnecting || isConnected) {
      cardColor = Theme.of(context).primaryColor;
    }
    Widget? trailingWidget;
    if (isConnecting) {
      trailingWidget = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (isConnected) {
      trailingWidget = Icon(
        Icons.check_circle,
        color: Theme.of(context).primaryColor,
      );
    } else {
      trailingWidget = Text(data.rssi.toString());
    }

    return IgnorePointer(
      ignoring: isDisabled,
      child: Card(
        elevation: 2,
        color: cardColor,
        child: ListTile(
          title: Text(
            data.device.advName,
            style: TextStyle(color: isDisabled ? Colors.grey : null),
          ),
          subtitle: Text(
            data.device.remoteId.str,
            style: TextStyle(color: isDisabled ? Colors.grey : null),
          ),
          trailing: trailingWidget,
          onTap: isDisabled
              ? null
              : () async {
                  await bleController.connectDevice(data.device);
                  if (context.mounted) {
                    context.push('/device/${data.device.remoteId.str}');
                  }
                },
        ),
      ),
    );
  }
}
