import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/native_channel.dart';

class DeviceInfoScreen extends StatefulWidget {
  const DeviceInfoScreen({super.key});

  @override
  State<DeviceInfoScreen> createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends State<DeviceInfoScreen> {
  Map<String, String> _deviceInfo = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final info = <String, String>{};

    // Device info
    final deviceInfo = DeviceInfoPlugin();
    final android = await deviceInfo.androidInfo;
    info['Model'] = '${android.manufacturer} ${android.model}';
    info['Merk'] = android.brand;
    info['Android Versie'] = android.version.release;
    info['SDK Versie'] = '${android.version.sdkInt}';
    info['Beveiligingspatch'] = android.version.securityPatch ?? 'Onbekend';
    info['Hardware'] = android.hardware;
    info['Product'] = android.product;
    info['Apparaat'] = android.device;
    info['Board'] = android.board;
    info['Bootloader'] = android.bootloader;
    info['Display'] = android.display;
    info['Vingerafdruk'] = android.fingerprint;
    info['Host'] = android.host;
    info['ID'] = android.id;
    info['Ondersteunde ABIs'] = android.supportedAbis.join(', ');
    info['Is Fysiek Apparaat'] = android.isPhysicalDevice ? 'Ja' : 'Nee (Emulator)';

    // Battery
    final battery = Battery();
    final level = await battery.batteryLevel;
    final state = await battery.batteryState;
    info['Batterij Niveau'] = '$level%';
    info['Batterij Status'] = _batteryStateToString(state);

    // Connectivity
    final connectivity = Connectivity();
    final connectResult = await connectivity.checkConnectivity();
    info['Netwerk'] = connectResult.map(_connectivityToString).join(', ');

    // Storage
    try {
      final storage = await NativeChannel.getStorageInfo();
      final totalGB = (storage['totalBytes']! / (1024 * 1024 * 1024)).toStringAsFixed(1);
      final usedGB = (storage['usedBytes']! / (1024 * 1024 * 1024)).toStringAsFixed(1);
      final availGB = (storage['availableBytes']! / (1024 * 1024 * 1024)).toStringAsFixed(1);
      info['Opslag Totaal'] = '$totalGB GB';
      info['Opslag Gebruikt'] = '$usedGB GB';
      info['Opslag Beschikbaar'] = '$availGB GB';
    } catch (_) {}

    if (mounted) {
      setState(() {
        _deviceInfo = info;
        _loading = false;
      });
    }
  }

  String _batteryStateToString(BatteryState state) {
    switch (state) {
      case BatteryState.charging:
        return 'Opladen';
      case BatteryState.discharging:
        return 'Ontladen';
      case BatteryState.full:
        return 'Vol';
      case BatteryState.connectedNotCharging:
        return 'Verbonden (niet opladen)';
      case BatteryState.unknown:
        return 'Onbekend';
    }
  }

  String _connectivityToString(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobiel';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.none:
        return 'Geen verbinding';
      case ConnectivityResult.other:
        return 'Overig';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apparaat Info'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _deviceInfo.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = _deviceInfo.entries.elementAt(index);
                return ListTile(
                  title: Text(entry.key),
                  subtitle: Text(
                    entry.value,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                );
              },
            ),
    );
  }
}
