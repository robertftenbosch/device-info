import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/native_channel.dart';
import '../widgets/status_card.dart';
import 'microphone_screen.dart';
import 'camera_screen.dart';
import 'processes_screen.dart';
import 'device_info_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _micAppCount = 0;
  int _camAppCount = 0;
  int _serviceCount = 0;
  bool _micActive = false;
  bool _camActive = false;
  String _deviceModel = '';
  String _androidVersion = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        NativeChannel.getAppsWithPermission('android.permission.RECORD_AUDIO'),
        NativeChannel.getAppsWithPermission('android.permission.CAMERA'),
        NativeChannel.getRunningServices(),
        NativeChannel.isMicrophoneActive(),
        NativeChannel.isCameraActive(),
        DeviceInfoPlugin().androidInfo,
      ]);

      if (mounted) {
        final androidInfo = results[5] as AndroidDeviceInfo;
        setState(() {
          _micAppCount = (results[0] as List).length;
          _camAppCount = (results[1] as List).length;
          _serviceCount = (results[2] as List).length;
          _micActive = results[3] as bool;
          _camActive = results[4] as bool;
          _deviceModel =
              '${androidInfo.manufacturer} ${androidInfo.model}';
          _androidVersion = 'Android ${androidInfo.version.release}';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Info'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                setState(() => _loading = true);
                await _loadData();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Beveiliging',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StatusCard(
                    title: 'Microfoon',
                    subtitle: _micActive
                        ? 'ACTIEF - $_micAppCount apps met toegang'
                        : '$_micAppCount apps met toegang',
                    icon: Icons.mic,
                    iconColor:
                        _micActive ? Colors.red : theme.colorScheme.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MicrophoneScreen()),
                    ),
                    trailing: _micActive
                        ? Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                  ),
                  StatusCard(
                    title: 'Camera',
                    subtitle: _camActive
                        ? 'ACTIEF - $_camAppCount apps met toegang'
                        : '$_camAppCount apps met toegang',
                    icon: Icons.videocam,
                    iconColor:
                        _camActive ? Colors.red : theme.colorScheme.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CameraScreen()),
                    ),
                    trailing: _camActive
                        ? Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Systeem',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StatusCard(
                    title: 'Processen',
                    subtitle: '$_serviceCount actieve services',
                    icon: Icons.memory,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProcessesScreen()),
                    ),
                  ),
                  StatusCard(
                    title: 'Apparaat',
                    subtitle: '$_deviceModel - $_androidVersion',
                    icon: Icons.phone_android,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DeviceInfoScreen()),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
