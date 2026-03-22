import 'package:flutter/material.dart';
import '../models/app_info.dart';
import '../services/native_channel.dart';
import '../widgets/app_list_tile.dart';

class ProcessesScreen extends StatefulWidget {
  const ProcessesScreen({super.key});

  @override
  State<ProcessesScreen> createState() => _ProcessesScreenState();
}

class _ProcessesScreenState extends State<ProcessesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showSystemApps = false;
  bool _hasUsagePermission = false;

  late Future<List<RunningServiceInfo>> _servicesFuture;
  Future<List<RunningAppInfo>>? _appsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _servicesFuture = NativeChannel.getRunningServices();
    _checkPermissionAndLoad();
  }

  Future<void> _checkPermissionAndLoad() async {
    _hasUsagePermission = await NativeChannel.hasUsageStatsPermission();
    if (_hasUsagePermission) {
      _appsFuture = NativeChannel.getRunningApps();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processen'),
        actions: [
          FilterChip(
            label: const Text('Systeem'),
            selected: _showSystemApps,
            onSelected: (v) => setState(() => _showSystemApps = v),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Services'),
            Tab(text: 'Recente Apps'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildServicesTab(),
          _buildRecentAppsTab(theme),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    return FutureBuilder<List<RunningServiceInfo>>(
      future: _servicesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Fout: ${snapshot.error}'));
        }
        final services = snapshot.data!
            .where((s) => _showSystemApps || !s.isSystemApp)
            .toList();

        if (services.isEmpty) {
          return const Center(child: Text('Geen services gevonden'));
        }

        return ListView.builder(
          itemCount: services.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '${services.length} actieve services',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              );
            }
            final service = services[index - 1];
            return AppListTile(
              appName: service.appName,
              packageName: service.packageName,
              isSystemApp: service.isSystemApp,
              subtitle: 'PID: ${service.pid} - ${service.shortServiceName}',
              trailing: service.isForeground
                  ? Chip(
                      label: const Text('Voorgrond'),
                      labelStyle: Theme.of(context).textTheme.labelSmall,
                      backgroundColor:
                          Theme.of(context).colorScheme.tertiaryContainer,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildRecentAppsTab(ThemeData theme) {
    if (!_hasUsagePermission) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline,
                  size: 64, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'Gebruiksstatistieken Permissie Nodig',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Om recente app-activiteit te bekijken, heeft de app toegang nodig tot gebruiksstatistieken.',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  await NativeChannel.openUsageStatsSettings();
                },
                icon: const Icon(Icons.settings),
                label: const Text('Open Instellingen'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _checkPermissionAndLoad,
                child: const Text('Opnieuw controleren'),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<List<RunningAppInfo>>(
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
          return const Center(child: Text('Geen recente apps gevonden'));
        }

        return ListView.builder(
          itemCount: apps.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '${apps.length} recent gebruikte apps (24u)',
                  style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                ),
              );
            }
            final app = apps[index - 1];
            return AppListTile(
              appName: app.appName,
              packageName: app.packageName,
              isSystemApp: app.isSystemApp,
              subtitle:
                  '${app.lastUsedFormatted} - ${app.foregroundTimeFormatted} actief',
            );
          },
        );
      },
    );
  }
}
