import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/native_channel.dart';
import '../widgets/status_card.dart';
import 'microphone_screen.dart';
import 'camera_screen.dart';
import 'processes_screen.dart';
import 'device_info_screen.dart';
import 'permissions_screen.dart';
import 'network_screen.dart';
import 'security_screen.dart';
import 'hardware_screen.dart';

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
  int _locationAppCount = 0;
  int _overlayAppCount = 0;
  int _accessibilityCount = 0;
  int _sideloadedCount = 0;
  bool _isRooted = false;
  bool _vpnActive = false;
  int _openPortCount = 0;
  int _connectionCount = 0;
  int _arpDeviceCount = 0;
  int _sensorCount = 0;
  String _ramUsage = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        NativeChannel.getAppsWithPermission('android.permission.RECORD_AUDIO'),  // 0
        NativeChannel.getAppsWithPermission('android.permission.CAMERA'),        // 1
        NativeChannel.getRunningServices(),                                       // 2
        NativeChannel.isMicrophoneActive(),                                       // 3
        NativeChannel.isCameraActive(),                                           // 4
        DeviceInfoPlugin().androidInfo,                                           // 5
        NativeChannel.getAppsWithPermission('android.permission.ACCESS_FINE_LOCATION'), // 6
        NativeChannel.getOverlayApps(),                                           // 7
        NativeChannel.getAccessibilityServices(),                                 // 8
        NativeChannel.getSideloadedApps(),                                        // 9
        NativeChannel.getRootStatus(),                                            // 10
        NativeChannel.getVpnStatus(),                                             // 11
        NativeChannel.getOpenPorts(),                                             // 12
        NativeChannel.getActiveConnections(),                                     // 13
        NativeChannel.getSensorList(),                                            // 14
        NativeChannel.getRamInfo(),                                               // 15
        NativeChannel.getArpTable(),                                              // 16
      ]);

      if (mounted) {
        final androidInfo = results[5] as AndroidDeviceInfo;
        final vpn = results[11] as Map<String, dynamic>;
        final root = results[10] as Map<String, dynamic>;
        final ram = results[15] as Map<String, int>;
        final totalRam = ram['totalBytes'] ?? 1;
        final usedRam = ram['usedBytes'] ?? 0;
        final pct = (usedRam / totalRam * 100).toStringAsFixed(0);

        setState(() {
          _micAppCount = (results[0] as List).length;
          _camAppCount = (results[1] as List).length;
          _serviceCount = (results[2] as List).length;
          _micActive = results[3] as bool;
          _camActive = results[4] as bool;
          _deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
          _androidVersion = 'Android ${androidInfo.version.release}';
          _locationAppCount = (results[6] as List).length;
          _overlayAppCount = (results[7] as List).length;
          _accessibilityCount = (results[8] as List).length;
          _sideloadedCount = (results[9] as List).length;
          _isRooted = root['isRooted'] == true;
          _vpnActive = vpn['isActive'] == true;
          _openPortCount = (results[12] as List).length;
          _connectionCount = (results[13] as List).length;
          _sensorCount = (results[14] as List).length;
          _ramUsage = '$pct% gebruikt';
          _arpDeviceCount = (results[16] as List).length;
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
                  // Privacy
                  _sectionTitle(theme, 'Privacy'),
                  StatusCard(
                    title: 'Microfoon',
                    subtitle: _micActive
                        ? 'ACTIEF - $_micAppCount apps met toegang'
                        : '$_micAppCount apps met toegang',
                    icon: Icons.mic,
                    iconColor: _micActive ? Colors.red : null,
                    onTap: () => _push(const MicrophoneScreen()),
                    trailing: _micActive ? _activeDot() : null,
                  ),
                  StatusCard(
                    title: 'Camera',
                    subtitle: _camActive
                        ? 'ACTIEF - $_camAppCount apps met toegang'
                        : '$_camAppCount apps met toegang',
                    icon: Icons.videocam,
                    iconColor: _camActive ? Colors.red : null,
                    onTap: () => _push(const CameraScreen()),
                    trailing: _camActive ? _activeDot() : null,
                  ),
                  StatusCard(
                    title: 'Permissies',
                    subtitle:
                        '$_locationAppCount locatie - $_overlayAppCount overlay - $_accessibilityCount a11y',
                    icon: Icons.shield,
                    onTap: () => _push(const PermissionsScreen()),
                  ),
                  const SizedBox(height: 16),

                  // Netwerk
                  _sectionTitle(theme, 'Netwerk'),
                  StatusCard(
                    title: 'Netwerk & WiFi',
                    subtitle:
                        '$_connectionCount verbindingen - $_openPortCount poorten - $_arpDeviceCount apparaten',
                    icon: Icons.wifi,
                    iconColor: _vpnActive ? Colors.green : null,
                    onTap: () => _push(const NetworkScreen()),
                    trailing: _vpnActive
                        ? Chip(
                            label: const Text('VPN'),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            backgroundColor: Colors.green.shade100,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Beveiliging
                  _sectionTitle(theme, 'Beveiliging'),
                  StatusCard(
                    title: 'Beveiliging',
                    subtitle: _isRooted
                        ? 'WAARSCHUWING: Device is geroot - $_sideloadedCount sideloaded'
                        : '$_sideloadedCount sideloaded apps',
                    icon: Icons.security,
                    iconColor: _isRooted ? Colors.red : Colors.green,
                    onTap: () => _push(const SecurityScreen()),
                    trailing: _isRooted ? _activeDot() : null,
                  ),
                  const SizedBox(height: 16),

                  // Systeem
                  _sectionTitle(theme, 'Systeem'),
                  StatusCard(
                    title: 'Processen',
                    subtitle: '$_serviceCount actieve services',
                    icon: Icons.memory,
                    onTap: () => _push(const ProcessesScreen()),
                  ),
                  StatusCard(
                    title: 'Hardware',
                    subtitle: '$_sensorCount sensoren - RAM: $_ramUsage',
                    icon: Icons.developer_board,
                    onTap: () => _push(const HardwareScreen()),
                  ),
                  StatusCard(
                    title: 'Apparaat',
                    subtitle: '$_deviceModel - $_androidVersion',
                    icon: Icons.phone_android,
                    onTap: () => _push(const DeviceInfoScreen()),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _activeDot() {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(right: 8),
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}
