import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muscle_monitoring/presentation/providers/page_index_provider.dart';

class CustomBottomNavigation extends ConsumerWidget {
  const CustomBottomNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(pageIndexProvider);
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (value) => ref.read(pageIndexProvider.notifier).state = value,
      elevation: 0,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.bluetooth), label: 'Scanner'),
        BottomNavigationBarItem(
          icon: Icon(Icons.monitor_heart),
          label: 'Monitoring',
        ),
      ],
    );
  }
}
