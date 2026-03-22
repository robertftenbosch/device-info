import 'package:flutter/material.dart';
import '../services/native_channel.dart';
import '../widgets/app_list_tile.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  Map<String, dynamic> _rootStatus = {};
  Map<String, dynamic> _devOptions = {};
  Map<String, dynamic> _encryption = {};
  Map<String, dynamic> _selinux = {};
  List<Map<String, dynamic>> _sideloadedApps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        NativeChannel.getRootStatus(),
        NativeChannel.getDeveloperOptions(),
        NativeChannel.getEncryptionStatus(),
        NativeChannel.getSELinuxStatus(),
        NativeChannel.getSideloadedApps(),
      ]);
      if (mounted) {
        setState(() {
          _rootStatus = results[0] as Map<String, dynamic>;
          _devOptions = results[1] as Map<String, dynamic>;
          _encryption = results[2] as Map<String, dynamic>;
          _selinux = results[3] as Map<String, dynamic>;
          _sideloadedApps = (results[4] as List).cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Beveiliging')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isRooted = _rootStatus['isRooted'] == true;
    final isBootloaderUnlocked = _rootStatus['isBootloaderUnlocked'] == true;
    final indicators =
        (_rootStatus['indicators'] as List<dynamic>?)?.cast<String>() ?? [];
    final devEnabled = _devOptions['developerEnabled'] == true;
    final usbDebug = _devOptions['usbDebugging'] == true;
    final mockLocation = (_devOptions['mockLocation'] ?? '').toString();
    final isEncrypted = _encryption['isEncrypted'] == true;
    final encStatus = _encryption['status']?.toString() ?? 'Onbekend';
    final selinuxStatus = _selinux['status']?.toString() ?? 'Onbekend';
    final selinuxEnforcing = _selinux['isEnforcing'] == 'true';

    return Scaffold(
      appBar: AppBar(title: const Text('Beveiliging')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Root Status
          _SectionHeader(title: 'Root & Bootloader'),
          _StatusTile(
            icon: Icons.security,
            title: 'Root Status',
            value: isRooted ? 'GEROOT' : 'Niet geroot',
            isWarning: isRooted,
          ),
          _StatusTile(
            icon: Icons.lock_open,
            title: 'Bootloader',
            value: isBootloaderUnlocked ? 'UNLOCKED' : 'Vergrendeld',
            isWarning: isBootloaderUnlocked,
          ),
          if (indicators.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: Text('Indicatoren:',
                  style: theme.textTheme.labelMedium),
            ),
            ...indicators.map((i) => Padding(
                  padding: const EdgeInsets.only(left: 24, top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, size: 16,
                          color: theme.colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(child: Text(i, style: theme.textTheme.bodySmall)),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 16),

          // Encryption & SELinux
          _SectionHeader(title: 'Encryptie & SELinux'),
          _StatusTile(
            icon: Icons.enhanced_encryption,
            title: 'Opslag Encryptie',
            value: encStatus,
            isWarning: !isEncrypted,
          ),
          _StatusTile(
            icon: Icons.shield,
            title: 'SELinux',
            value: selinuxStatus,
            isWarning: !selinuxEnforcing,
          ),
          const SizedBox(height: 16),

          // Developer Options
          _SectionHeader(title: 'Ontwikkelaarsopties'),
          _StatusTile(
            icon: Icons.developer_mode,
            title: 'Ontwikkelaarsopties',
            value: devEnabled ? 'Ingeschakeld' : 'Uitgeschakeld',
            isWarning: devEnabled,
          ),
          _StatusTile(
            icon: Icons.usb,
            title: 'USB Debugging',
            value: usbDebug ? 'Ingeschakeld' : 'Uitgeschakeld',
            isWarning: usbDebug,
          ),
          if (mockLocation.isNotEmpty)
            _StatusTile(
              icon: Icons.location_off,
              title: 'Mock Locatie App',
              value: mockLocation,
              isWarning: true,
            ),
          const SizedBox(height: 16),

          // Sideloaded Apps
          _SectionHeader(
              title:
                  'Sideloaded Apps (${_sideloadedApps.length})'),
          if (_sideloadedApps.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Geen sideloaded apps gevonden'),
            )
          else
            ..._sideloadedApps.map((app) => AppListTile(
                  appName: app['appName'] as String,
                  packageName: app['packageName'] as String,
                  isSystemApp: false,
                  subtitle:
                      'Bron: ${app['installer'] ?? 'Onbekend'}',
                )),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isWarning;

  const _StatusTile({
    required this.icon,
    required this.title,
    required this.value,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon,
          color: isWarning
              ? theme.colorScheme.error
              : theme.colorScheme.primary),
      title: Text(title),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isWarning
              ? theme.colorScheme.errorContainer
              : theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: isWarning
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
