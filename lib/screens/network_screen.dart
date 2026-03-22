import 'package:flutter/material.dart';
import '../services/native_channel.dart';

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen>
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
        title: const Text('Netwerk'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'WiFi'),
            Tab(text: 'Poorten'),
            Tab(text: 'Verbindingen'),
            Tab(text: 'Bluetooth'),
            Tab(text: 'Interfaces'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _WifiTab(),
          _PortsTab(),
          _ConnectionsTab(),
          _BluetoothTab(),
          _InterfacesTab(),
        ],
      ),
    );
  }
}

class _WifiTab extends StatefulWidget {
  const _WifiTab();

  @override
  State<_WifiTab> createState() => _WifiTabState();
}

class _WifiTabState extends State<_WifiTab>
    with AutomaticKeepAliveClientMixin {
  late Future<Map<String, dynamic>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = NativeChannel.getWifiDetails();
  }

  String _signalStrength(int rssi) {
    if (rssi >= -50) return 'Uitstekend';
    if (rssi >= -60) return 'Goed';
    if (rssi >= -70) return 'Redelijk';
    return 'Zwak';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Fout: ${snapshot.error}'));
        }
        final wifi = snapshot.data!;
        final rssi = wifi['rssi'] as int? ?? 0;
        final entries = <MapEntry<String, String>>[
          MapEntry('Status', wifi['isEnabled'] == true ? 'Ingeschakeld' : 'Uitgeschakeld'),
          MapEntry('SSID', wifi['ssid']?.toString() ?? 'Onbekend'),
          MapEntry('BSSID', wifi['bssid']?.toString() ?? 'Onbekend'),
          MapEntry('Signaalsterkte', '$rssi dBm (${_signalStrength(rssi)})'),
          MapEntry('Snelheid', '${wifi['linkSpeed'] ?? 0} Mbps'),
          MapEntry('Frequentie', '${wifi['frequency'] ?? 0} MHz'),
          if (wifi['standard'] != null) MapEntry('WiFi Standaard', wifi['standard'].toString()),
          MapEntry('IP-adres', wifi['ipAddress']?.toString() ?? ''),
          MapEntry('Gateway', wifi['gateway']?.toString() ?? ''),
          MapEntry('Subnetmasker', wifi['netmask']?.toString() ?? ''),
          MapEntry('DNS 1', wifi['dns1']?.toString() ?? ''),
          MapEntry('DNS 2', wifi['dns2']?.toString() ?? ''),
        ];
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final e = entries[index];
            return ListTile(
              title: Text(e.key),
              subtitle: Text(e.value),
            );
          },
        );
      },
    );
  }
}

class _PortsTab extends StatefulWidget {
  const _PortsTab();

  @override
  State<_PortsTab> createState() => _PortsTabState();
}

class _PortsTabState extends State<_PortsTab>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = NativeChannel.getOpenPorts();
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
        final ports = snapshot.data!;
        if (ports.isEmpty) {
          return const Center(child: Text('Geen open poorten gevonden'));
        }
        return ListView.builder(
          itemCount: ports.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('${ports.length} poorten gevonden',
                    style: theme.textTheme.titleSmall),
              );
            }
            final port = ports[index - 1];
            final state = port['state'] as String? ?? '';
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: state == 'LISTEN'
                    ? theme.colorScheme.errorContainer
                    : theme.colorScheme.primaryContainer,
                child: Text('${port['port']}',
                    style: theme.textTheme.labelSmall),
              ),
              title: Text(
                  'Poort ${port['port']} (${port['protocol']?.toString().toUpperCase() ?? ''})'),
              subtitle: Text(state),
              trailing: port['isIPv6'] == true
                  ? const Chip(
                      label: Text('IPv6'),
                      visualDensity: VisualDensity.compact,
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}

class _ConnectionsTab extends StatefulWidget {
  const _ConnectionsTab();

  @override
  State<_ConnectionsTab> createState() => _ConnectionsTabState();
}

class _ConnectionsTabState extends State<_ConnectionsTab>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = NativeChannel.getActiveConnections();
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
        final conns = snapshot.data!;
        if (conns.isEmpty) {
          return const Center(
              child: Text('Geen actieve verbindingen'));
        }
        return ListView.builder(
          itemCount: conns.length,
          itemBuilder: (context, index) {
            final conn = conns[index];
            return ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text('${conn['remoteIp']}:${conn['remotePort']}'),
              subtitle: Text(
                  'Lokale poort: ${conn['localPort']} (${conn['protocol']?.toString().toUpperCase() ?? ''})'),
            );
          },
        );
      },
    );
  }
}

class _BluetoothTab extends StatefulWidget {
  const _BluetoothTab();

  @override
  State<_BluetoothTab> createState() => _BluetoothTabState();
}

class _BluetoothTabState extends State<_BluetoothTab>
    with AutomaticKeepAliveClientMixin {
  late Future<Map<String, dynamic>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = NativeChannel.getBluetoothDevices();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Fout: ${snapshot.error}'));
        }
        final bt = snapshot.data!;
        final devices =
            (bt['bondedDevices'] as List<dynamic>?)?.cast<Map<dynamic, dynamic>>() ?? [];
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            ListTile(
              title: const Text('Bluetooth Status'),
              subtitle: Text(bt['isEnabled'] == true
                  ? 'Ingeschakeld'
                  : 'Uitgeschakeld'),
              leading: Icon(Icons.bluetooth,
                  color: bt['isEnabled'] == true
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant),
            ),
            ListTile(
              title: const Text('Apparaatnaam'),
              subtitle: Text(bt['name']?.toString() ?? 'Onbekend'),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Gekoppelde apparaten (${devices.length})',
                  style: theme.textTheme.titleSmall),
            ),
            if (devices.isEmpty)
              const ListTile(
                  title: Text('Geen gekoppelde apparaten')),
            ...devices.map((d) => ListTile(
                  leading: const Icon(Icons.bluetooth_connected),
                  title: Text(d['name']?.toString() ?? 'Onbekend'),
                  subtitle: Text(d['address']?.toString() ?? ''),
                  trailing: Chip(
                    label: Text(d['type']?.toString() ?? ''),
                    visualDensity: VisualDensity.compact,
                  ),
                )),
          ],
        );
      },
    );
  }
}

class _InterfacesTab extends StatefulWidget {
  const _InterfacesTab();

  @override
  State<_InterfacesTab> createState() => _InterfacesTabState();
}

class _InterfacesTabState extends State<_InterfacesTab>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = NativeChannel.getNetworkInterfaces();
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
        final ifaces = snapshot.data!;
        if (ifaces.isEmpty) {
          return const Center(child: Text('Geen netwerk interfaces'));
        }
        return ListView.builder(
          itemCount: ifaces.length,
          itemBuilder: (context, index) {
            final iface = ifaces[index];
            final addrs = (iface['addresses'] as List<dynamic>?)
                    ?.map((a) => a.toString())
                    .join('\n') ??
                '';
            return ExpansionTile(
              leading: Icon(
                iface['isLoopback'] == true
                    ? Icons.loop
                    : Icons.settings_ethernet,
              ),
              title: Text(iface['name']?.toString() ?? ''),
              subtitle: Text(iface['displayName']?.toString() ?? ''),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(addrs),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
