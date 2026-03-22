import 'package:flutter/material.dart';
import '../services/native_channel.dart';

class HardwareScreen extends StatefulWidget {
  const HardwareScreen({super.key});

  @override
  State<HardwareScreen> createState() => _HardwareScreenState();
}

class _HardwareScreenState extends State<HardwareScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('Hardware'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'CPU'),
            Tab(text: 'RAM'),
            Tab(text: 'Temperatuur'),
            Tab(text: 'Sensoren'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CpuTab(),
          _RamTab(),
          _TemperatureTab(),
          _SensorsTab(),
        ],
      ),
    );
  }
}

class _CpuTab extends StatefulWidget {
  const _CpuTab();

  @override
  State<_CpuTab> createState() => _CpuTabState();
}

class _CpuTabState extends State<_CpuTab> with AutomaticKeepAliveClientMixin {
  late Future<Map<String, dynamic>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = NativeChannel.getCpuInfo();
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
        final cpu = snapshot.data!;
        final cores = cpu['cores'] as int? ?? 0;
        final abis = (cpu['abis'] as List<dynamic>?)?.join(', ') ?? '';
        final chipName = cpu['chipName']?.toString() ?? '';
        final hardware = cpu['hardware']?.toString() ?? '';
        final frequencies =
            (cpu['frequencies'] as List<dynamic>?)?.cast<Map<dynamic, dynamic>>() ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (chipName.isNotEmpty)
              ListTile(
                title: const Text('Chipset'),
                subtitle: Text(chipName),
                leading: const Icon(Icons.memory),
              ),
            ListTile(
              title: const Text('Hardware'),
              subtitle: Text(hardware),
              leading: const Icon(Icons.developer_board),
            ),
            ListTile(
              title: const Text('Kernen'),
              subtitle: Text('$cores'),
              leading: const Icon(Icons.grid_view),
            ),
            ListTile(
              title: const Text('Architectuur'),
              subtitle: Text(abis),
              leading: const Icon(Icons.architecture),
            ),
            if (frequencies.isNotEmpty) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('CPU Frequenties',
                    style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary)),
              ),
              ...frequencies.map((f) {
                final core = f['core'] ?? 0;
                final cur = f['currentMHz'] ?? 0;
                final max = f['maxMHz'] ?? 0;
                final min = f['minMHz'] ?? 0;
                final progress = max > 0 ? (cur as num) / (max as num) : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Core $core: $cur MHz ($min-$max MHz)',
                          style: theme.textTheme.bodySmall),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: progress.toDouble(),
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }
}

class _RamTab extends StatefulWidget {
  const _RamTab();

  @override
  State<_RamTab> createState() => _RamTabState();
}

class _RamTabState extends State<_RamTab> with AutomaticKeepAliveClientMixin {
  late Future<Map<String, int>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = NativeChannel.getRamInfo();
  }

  String _formatBytes(int bytes) {
    final gb = bytes / (1024 * 1024 * 1024);
    if (gb >= 1) return '${gb.toStringAsFixed(1)} GB';
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(0)} MB';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    return FutureBuilder<Map<String, int>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Fout: ${snapshot.error}'));
        }
        final ram = snapshot.data!;
        final total = ram['totalBytes'] ?? 0;
        final used = ram['usedBytes'] ?? 0;
        final available = ram['availableBytes'] ?? 0;
        final threshold = ram['threshold'] ?? 0;
        final isLow = (ram['isLowMemory'] ?? 0) == 1;
        final usagePercent = total > 0 ? used / total : 0.0;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: usagePercent,
                        strokeWidth: 12,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        color: isLow
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(usagePercent * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('gebruikt',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _RamInfoRow(label: 'Totaal', value: _formatBytes(total)),
              _RamInfoRow(label: 'Gebruikt', value: _formatBytes(used)),
              _RamInfoRow(
                  label: 'Beschikbaar', value: _formatBytes(available)),
              _RamInfoRow(
                  label: 'Drempelwaarde', value: _formatBytes(threshold)),
              if (isLow)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Card(
                    color: theme.colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.warning,
                              color: theme.colorScheme.onErrorContainer),
                          const SizedBox(width: 8),
                          Text('Geheugen is laag!',
                              style: TextStyle(
                                  color:
                                      theme.colorScheme.onErrorContainer)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RamInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _RamInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TemperatureTab extends StatefulWidget {
  const _TemperatureTab();

  @override
  State<_TemperatureTab> createState() => _TemperatureTabState();
}

class _TemperatureTabState extends State<_TemperatureTab>
    with AutomaticKeepAliveClientMixin {
  late Future<Map<String, dynamic>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = NativeChannel.getTemperatureInfo();
  }

  Color _tempColor(double temp) {
    if (temp < 40) return Colors.green;
    if (temp < 60) return Colors.orange;
    return Colors.red;
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
        final data = snapshot.data!;
        final zones = (data['thermalZones'] as List<dynamic>?)
                ?.cast<Map<dynamic, dynamic>>() ??
            [];
        if (zones.isEmpty) {
          return const Center(
              child: Text('Geen temperatuurdata beschikbaar'));
        }
        return ListView.builder(
          itemCount: zones.length,
          itemBuilder: (context, index) {
            final zone = zones[index];
            final temp =
                double.tryParse(zone['temperature']?.toString() ?? '0') ??
                    0;
            return ListTile(
              leading: Icon(Icons.thermostat, color: _tempColor(temp)),
              title: Text(zone['type']?.toString() ?? 'Onbekend'),
              subtitle: Text(zone['zone']?.toString() ?? ''),
              trailing: Text(
                '$temp\u00B0C',
                style: TextStyle(
                  color: _tempColor(temp),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SensorsTab extends StatefulWidget {
  const _SensorsTab();

  @override
  State<_SensorsTab> createState() => _SensorsTabState();
}

class _SensorsTabState extends State<_SensorsTab>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = NativeChannel.getSensorList();
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
        final sensors = snapshot.data!;
        return ListView.builder(
          itemCount: sensors.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('${sensors.length} sensoren beschikbaar',
                    style: theme.textTheme.titleSmall),
              );
            }
            final sensor = sensors[index - 1];
            return ExpansionTile(
              leading: const Icon(Icons.sensors),
              title: Text(sensor['name']?.toString() ?? ''),
              subtitle: Text(sensor['type']?.toString() ?? ''),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fabrikant: ${sensor['vendor'] ?? ''}'),
                      Text('Versie: ${sensor['version'] ?? ''}'),
                      Text(
                          'Verbruik: ${sensor['power'] ?? 0} mA'),
                      Text(
                          'Max bereik: ${sensor['maxRange'] ?? 0}'),
                      Text(
                          'Resolutie: ${sensor['resolution'] ?? 0}'),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
