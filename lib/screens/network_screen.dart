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
    _tabController = TabController(length: 9, vsync: this);
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
            Tab(text: 'Verbindingen'),
            Tab(text: 'Poorten'),
            Tab(text: 'DNS'),
            Tab(text: 'ARP Tabel'),
            Tab(text: 'Firewall'),
            Tab(text: 'Bluetooth'),
            Tab(text: 'Interfaces'),
            Tab(text: 'DNS Cache'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _WifiTab(),
          _ConnectionsWithHostnamesTab(),
          _PortsTab(),
          _DnsTab(),
          _ArpTab(),
          _FirewallTab(),
          _BluetoothTab(),
          _InterfacesTab(),
          _DnsCacheTab(),
        ],
      ),
    );
  }
}

// ==================== WiFi ====================

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

// ==================== Connections with Reverse DNS ====================

class _ConnectionsWithHostnamesTab extends StatefulWidget {
  const _ConnectionsWithHostnamesTab();

  @override
  State<_ConnectionsWithHostnamesTab> createState() =>
      _ConnectionsWithHostnamesTabState();
}

class _ConnectionsWithHostnamesTabState
    extends State<_ConnectionsWithHostnamesTab>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = NativeChannel.getConnectionsWithHostnames();
  }

  void _refresh() {
    setState(() {
      _future = NativeChannel.getConnectionsWithHostnames();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('DNS lookups uitvoeren...'),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text('Fout: ${snapshot.error}'));
        }
        final conns = snapshot.data!;
        if (conns.isEmpty) {
          return const Center(child: Text('Geen actieve verbindingen'));
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Text('${conns.length} actieve verbindingen',
                      style: theme.textTheme.titleSmall),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refresh,
                    tooltip: 'Vernieuwen',
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: conns.length,
                itemBuilder: (context, index) {
                  final conn = conns[index];
                  final hostname = conn['hostname']?.toString() ?? '';
                  final remoteIp = conn['remoteIp']?.toString() ?? '';
                  final remotePort = conn['remotePort'] ?? 0;
                  final localPort = conn['localPort'] ?? 0;
                  final protocol = conn['protocol']?.toString().toUpperCase() ?? '';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.public,
                                  size: 20,
                                  color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  hostname.isNotEmpty
                                      ? hostname
                                      : remoteIp,
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(
                                          fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Chip(
                                label: Text(protocol),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          if (hostname.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 28),
                              child: Text(
                                remoteIp,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme
                                        .colorScheme.onSurfaceVariant),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(left: 28, top: 4),
                            child: Text(
                              'Remote :$remotePort  ←→  Lokaal :$localPort',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ==================== Ports ====================

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
        final listening =
            ports.where((p) => p['state'] == 'LISTEN').toList();
        final other =
            ports.where((p) => p['state'] != 'LISTEN').toList();

        return ListView(
          children: [
            if (listening.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Luisterende poorten (${listening.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.error),
                ),
              ),
              ...listening.map((port) => _buildPortTile(port, theme)),
            ],
            if (other.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Overige poorten (${other.length})',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              ...other.map((port) => _buildPortTile(port, theme)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPortTile(Map<String, dynamic> port, ThemeData theme) {
    final state = port['state'] as String? ?? '';
    final isListen = state == 'LISTEN';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isListen
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.primaryContainer,
        child: Text('${port['port']}',
            style: theme.textTheme.labelSmall),
      ),
      title: Text(
          'Poort ${port['port']} (${port['protocol']?.toString().toUpperCase() ?? ''})'),
      subtitle: Text(state),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (port['isIPv6'] == true)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Chip(
                label: const Text('IPv6'),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ),
          if (isListen)
            Icon(Icons.warning_amber,
                color: theme.colorScheme.error, size: 20),
        ],
      ),
    );
  }
}

// ==================== DNS Servers ====================

class _DnsTab extends StatefulWidget {
  const _DnsTab();

  @override
  State<_DnsTab> createState() => _DnsTabState();
}

class _DnsTabState extends State<_DnsTab>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = NativeChannel.getDnsServers();
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
        final servers = snapshot.data!;
        if (servers.isEmpty) {
          return const Center(child: Text('Geen DNS servers gevonden'));
        }
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.dns, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'DNS servers bepalen welke domeinnamen je device opzoekt. '
                          'Onbekende DNS servers kunnen je verkeer omleiden.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ...servers.map((s) => ListTile(
                  leading: const Icon(Icons.dns),
                  title: Text(s['address']?.toString() ?? ''),
                  subtitle: Text(s['source']?.toString() ?? ''),
                  trailing: _dnsProviderChip(
                      s['address']?.toString() ?? '', theme),
                )),
          ],
        );
      },
    );
  }

  Widget? _dnsProviderChip(String ip, ThemeData theme) {
    String? provider;
    if (ip.startsWith('8.8.8') || ip.startsWith('8.8.4')) {
      provider = 'Google';
    } else if (ip.startsWith('1.1.1') || ip.startsWith('1.0.0')) {
      provider = 'Cloudflare';
    } else if (ip.startsWith('9.9.9')) {
      provider = 'Quad9';
    } else if (ip.startsWith('208.67')) {
      provider = 'OpenDNS';
    }
    if (provider == null) return null;
    return Chip(
      label: Text(provider),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}

// ==================== ARP Table ====================

class _ArpTab extends StatefulWidget {
  const _ArpTab();

  @override
  State<_ArpTab> createState() => _ArpTabState();
}

class _ArpTabState extends State<_ArpTab>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = NativeChannel.getArpTable();
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
        final entries = snapshot.data!;
        if (entries.isEmpty) {
          return const Center(
              child: Text('Geen apparaten op het netwerk gevonden'));
        }
        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.devices,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${entries.length} apparaten gevonden op het lokale netwerk. '
                          'Dit zijn apparaten die recent via ARP zijn gedetecteerd.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ...entries.map((e) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.devices,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 20),
                  ),
                  title: Text(e['ip']?.toString() ?? ''),
                  subtitle: Text(
                    'MAC: ${e['mac'] ?? ''}\nInterface: ${e['interface'] ?? ''}',
                  ),
                  isThreeLine: true,
                )),
          ],
        );
      },
    );
  }
}

// ==================== Firewall (iptables) ====================

class _FirewallTab extends StatefulWidget {
  const _FirewallTab();

  @override
  State<_FirewallTab> createState() => _FirewallTabState();
}

class _FirewallTabState extends State<_FirewallTab>
    with AutomaticKeepAliveClientMixin {
  late Future<Map<String, dynamic>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = NativeChannel.getIptablesRules();
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
        final data = snapshot.data!;
        final hasAccess = data['hasAccess'] == true;
        final chains =
            (data['chains'] as List<dynamic>?)?.cast<Map<dynamic, dynamic>>() ??
                [];

        if (!hasAccess) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(
                    'Root Vereist',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Om iptables/firewall regels te bekijken is root-toegang nodig. '
                    '${data['error'] ?? ''}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        }

        if (chains.isEmpty) {
          return const Center(child: Text('Geen firewall regels gevonden'));
        }

        return ListView.builder(
          itemCount: chains.length,
          itemBuilder: (context, index) {
            final chain = chains[index];
            final chainName = chain['chain']?.toString() ?? '';
            final rules = (chain['rules'] as List<dynamic>?)
                    ?.map((r) => r.toString())
                    .toList() ??
                [];
            return ExpansionTile(
              leading:
                  const Icon(Icons.fireplace),
              title: Text(chainName),
              subtitle: Text('${rules.length} regels'),
              children: rules
                  .map((r) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 2),
                        child: Text(r,
                            style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace')),
                      ))
                  .toList(),
            );
          },
        );
      },
    );
  }
}

// ==================== Bluetooth ====================

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
            (bt['bondedDevices'] as List<dynamic>?)
                    ?.cast<Map<dynamic, dynamic>>() ??
                [];
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

// ==================== Interfaces ====================

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

// ==================== DNS Cache ====================

class _DnsCacheTab extends StatefulWidget {
  const _DnsCacheTab();

  @override
  State<_DnsCacheTab> createState() => _DnsCacheTabState();
}

class _DnsCacheTabState extends State<_DnsCacheTab>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = NativeChannel.getDnsCache();
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
        final entries = snapshot.data!;
        if (entries.isEmpty) {
          return const Center(
              child: Text('Geen DNS cache entries gevonden'));
        }
        return ListView.builder(
          itemCount: entries.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'DNS-gerelateerde systeem properties. '
                            'Volledige DNS query logging vereist root.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            final entry = entries[index - 1];
            return ListTile(
              leading: const Icon(Icons.dns_outlined),
              title: Text(
                entry['property']?.toString() ?? '',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontFamily: 'monospace'),
              ),
              subtitle: Text(entry['value']?.toString() ?? ''),
            );
          },
        );
      },
    );
  }
}
