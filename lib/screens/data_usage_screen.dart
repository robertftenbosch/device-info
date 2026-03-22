import 'package:flutter/material.dart';
import '../services/native_channel.dart';


class DataUsageScreen extends StatefulWidget {
  const DataUsageScreen({super.key});

  @override
  State<DataUsageScreen> createState() => _DataUsageScreenState();
}

class _DataUsageScreenState extends State<DataUsageScreen> {
  List<Map<String, dynamic>> _apps = [];
  bool _loading = true;
  bool _showSystemApps = false;
  _SortMode _sortMode = _SortMode.upload;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final apps = await NativeChannel.getAppDataUsage();
      if (mounted) {
        setState(() {
          _apps = apps;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredApps {
    var apps = _apps.where((a) =>
        _showSystemApps || a['isSystemApp'] != true).toList();
    switch (_sortMode) {
      case _SortMode.upload:
        apps.sort((a, b) =>
            (b['txBytes'] as int).compareTo(a['txBytes'] as int));
      case _SortMode.download:
        apps.sort((a, b) =>
            (b['rxBytes'] as int).compareTo(a['rxBytes'] as int));
      case _SortMode.total:
        apps.sort((a, b) =>
            (b['totalBytes'] as int).compareTo(a['totalBytes'] as int));
    }
    return apps;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Data Verbruik')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final apps = _filteredApps;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Verbruik'),
        actions: [
          FilterChip(
            label: const Text('Systeem'),
            selected: _showSystemApps,
            onSelected: (v) => setState(() => _showSystemApps = v),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Sort controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('Sorteer op:', style: theme.textTheme.labelMedium),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Upload'),
                  selected: _sortMode == _SortMode.upload,
                  onSelected: (_) =>
                      setState(() => _sortMode = _SortMode.upload),
                ),
                const SizedBox(width: 4),
                ChoiceChip(
                  label: const Text('Download'),
                  selected: _sortMode == _SortMode.download,
                  onSelected: (_) =>
                      setState(() => _sortMode = _SortMode.download),
                ),
                const SizedBox(width: 4),
                ChoiceChip(
                  label: const Text('Totaal'),
                  selected: _sortMode == _SortMode.total,
                  onSelected: (_) =>
                      setState(() => _sortMode = _SortMode.total),
                ),
              ],
            ),
          ),
          // Info card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Data sinds laatste herstart. Apps met veel upload-verkeer '
                        'versturen mogelijk data naar hun servers.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // App list
          Expanded(
            child: apps.isEmpty
                ? const Center(child: Text('Geen data verbruik gevonden'))
                : ListView.builder(
                    itemCount: apps.length,
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      final tx = app['txBytes'] as int;
                      final rx = app['rxBytes'] as int;
                      final total = app['totalBytes'] as int;
                      final isHighUpload = tx > rx * 2 && tx > 1024 * 1024;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 3),
                        color: isHighUpload
                            ? theme.colorScheme.errorContainer
                                .withValues(alpha: 0.3)
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: app['isSystemApp'] == true
                                    ? theme.colorScheme.secondaryContainer
                                    : theme.colorScheme.primaryContainer,
                                child: Icon(
                                  app['isSystemApp'] == true
                                      ? Icons.android
                                      : Icons.apps,
                                  color: app['isSystemApp'] == true
                                      ? theme
                                          .colorScheme.onSecondaryContainer
                                      : theme
                                          .colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            app['appName'] as String,
                                            style: theme
                                                .textTheme.titleSmall
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w600),
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isHighUpload)
                                          Icon(Icons.warning_amber,
                                              size: 16,
                                              color:
                                                  theme.colorScheme.error),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.arrow_upward,
                                            size: 14,
                                            color: theme.colorScheme.error),
                                        Text(' ${_formatBytes(tx)}',
                                            style:
                                                theme.textTheme.bodySmall),
                                        const SizedBox(width: 12),
                                        Icon(Icons.arrow_downward,
                                            size: 14,
                                            color:
                                                theme.colorScheme.primary),
                                        Text(' ${_formatBytes(rx)}',
                                            style:
                                                theme.textTheme.bodySmall),
                                        const Spacer(),
                                        Text(
                                          _formatBytes(total),
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                  fontWeight:
                                                      FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // Upload/download ratio bar
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(2),
                                      child: LinearProgressIndicator(
                                        value: total > 0
                                            ? tx / total
                                            : 0,
                                        backgroundColor: theme.colorScheme
                                            .primary
                                            .withValues(alpha: 0.2),
                                        color: theme.colorScheme.error
                                            .withValues(alpha: 0.7),
                                        minHeight: 4,
                                      ),
                                    ),
                                  ],
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
      ),
    );
  }
}

enum _SortMode { upload, download, total }
