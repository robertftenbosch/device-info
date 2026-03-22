import 'package:flutter/material.dart';
import '../models/app_info.dart';
import '../services/native_channel.dart';
import '../widgets/app_list_tile.dart';

class MicrophoneScreen extends StatefulWidget {
  const MicrophoneScreen({super.key});

  @override
  State<MicrophoneScreen> createState() => _MicrophoneScreenState();
}

class _MicrophoneScreenState extends State<MicrophoneScreen> {
  late Future<List<AppPermissionInfo>> _appsFuture;
  bool _showSystemApps = false;

  @override
  void initState() {
    super.initState();
    _appsFuture = NativeChannel.getAppsWithPermission(
        'android.permission.RECORD_AUDIO');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Microfoon Toegang'),
        actions: [
          FilterChip(
            label: const Text('Systeem'),
            selected: _showSystemApps,
            onSelected: (v) => setState(() => _showSystemApps = v),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<AppPermissionInfo>>(
        future: _appsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Fout: ${snapshot.error}'));
          }
          final apps = snapshot.data!
              .where((a) => _showSystemApps || !a.isSystemApp)
              .toList();

          if (apps.isEmpty) {
            return const Center(
              child: Text('Geen apps gevonden met microfoon toegang'),
            );
          }

          return ListView.builder(
            itemCount: apps.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    '${apps.length} apps met microfoon permissie',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                );
              }
              final app = apps[index - 1];
              return AppListTile(
                appName: app.appName,
                packageName: app.packageName,
                isSystemApp: app.isSystemApp,
              );
            },
          );
        },
      ),
    );
  }
}
