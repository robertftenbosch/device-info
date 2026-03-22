import 'package:flutter/material.dart';
import '../models/app_info.dart';
import '../services/native_channel.dart';
import '../widgets/app_list_tile.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissies & Privacy'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Locatie'),
            Tab(text: 'Contacten'),
            Tab(text: 'Overlay'),
            Tab(text: 'Toegankelijkheid'),
            Tab(text: 'Device Admin'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PermissionListTab(
            permission: 'android.permission.ACCESS_FINE_LOCATION',
            emptyText: 'Geen apps met locatie toegang',
          ),
          _PermissionListTab(
            permission: 'android.permission.READ_CONTACTS',
            emptyText: 'Geen apps met contacten toegang',
          ),
          const _OverlayTab(),
          const _AccessibilityTab(),
          const _DeviceAdminTab(),
        ],
      ),
    );
  }
}

class _PermissionListTab extends StatefulWidget {
  final String permission;
  final String emptyText;

  const _PermissionListTab({
    required this.permission,
    required this.emptyText,
  });

  @override
  State<_PermissionListTab> createState() => _PermissionListTabState();
}

class _PermissionListTabState extends State<_PermissionListTab>
    with AutomaticKeepAliveClientMixin {
  late Future<List<AppPermissionInfo>> _future;
  bool _showSystem = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = NativeChannel.getAppsWithPermission(widget.permission);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: FilterChip(
            label: const Text('Toon systeem-apps'),
            selected: _showSystem,
            onSelected: (v) => setState(() => _showSystem = v),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<AppPermissionInfo>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Fout: ${snapshot.error}'));
              }
              final apps = snapshot.data!
                  .where((a) => _showSystem || !a.isSystemApp)
                  .toList();
              if (apps.isEmpty) {
                return Center(child: Text(widget.emptyText));
              }
              return ListView.builder(
                itemCount: apps.length,
                itemBuilder: (context, index) {
                  final app = apps[index];
                  return AppListTile(
                    appName: app.appName,
                    packageName: app.packageName,
                    isSystemApp: app.isSystemApp,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OverlayTab extends StatefulWidget {
  const _OverlayTab();

  @override
  State<_OverlayTab> createState() => _OverlayTabState();
}

class _OverlayTabState extends State<_OverlayTab>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = NativeChannel.getOverlayApps();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Fout: ${snapshot.error}'));
        }
        final apps = snapshot.data!;
        if (apps.isEmpty) {
          return const Center(child: Text('Geen apps met overlay permissie'));
        }
        return ListView.builder(
          itemCount: apps.length,
          itemBuilder: (context, index) {
            final app = apps[index];
            return AppListTile(
              appName: app['appName'] as String,
              packageName: app['packageName'] as String,
              isSystemApp: app['isSystemApp'] as bool,
              trailing: app['isGranted'] == true
                  ? const Chip(
                      label: Text('Actief'),
                      backgroundColor: Color(0xFFFFCDD2),
                    )
                  : const Chip(label: Text('Gevraagd')),
            );
          },
        );
      },
    );
  }
}

class _AccessibilityTab extends StatefulWidget {
  const _AccessibilityTab();

  @override
  State<_AccessibilityTab> createState() => _AccessibilityTabState();
}

class _AccessibilityTabState extends State<_AccessibilityTab>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = NativeChannel.getAccessibilityServices();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Fout: ${snapshot.error}'));
        }
        final services = snapshot.data!;
        if (services.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 48,
                    color: theme.colorScheme.primary),
                const SizedBox(height: 8),
                const Text('Geen actieve toegankelijkheidsservices'),
              ],
            ),
          );
        }
        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.warning,
                          color: theme.colorScheme.onErrorContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Toegankelijkheidsservices kunnen alles op je scherm lezen en bedienen.',
                          style: TextStyle(
                              color: theme.colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ...services.map((s) => AppListTile(
                  appName: s['appName'] as String,
                  packageName: s['packageName'] as String,
                  isSystemApp: s['isSystemApp'] as bool,
                )),
          ],
        );
      },
    );
  }
}

class _DeviceAdminTab extends StatefulWidget {
  const _DeviceAdminTab();

  @override
  State<_DeviceAdminTab> createState() => _DeviceAdminTabState();
}

class _DeviceAdminTabState extends State<_DeviceAdminTab>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = NativeChannel.getDeviceAdmins();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Fout: ${snapshot.error}'));
        }
        final admins = snapshot.data!;
        if (admins.isEmpty) {
          return const Center(child: Text('Geen device administrators'));
        }
        return ListView.builder(
          itemCount: admins.length,
          itemBuilder: (context, index) {
            final admin = admins[index];
            return AppListTile(
              appName: admin['appName'] as String,
              packageName: admin['packageName'] as String,
              isSystemApp: admin['isSystemApp'] as bool,
              trailing: const Icon(Icons.admin_panel_settings),
            );
          },
        );
      },
    );
  }
}
