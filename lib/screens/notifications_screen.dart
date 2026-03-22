import 'package:flutter/material.dart';
import '../services/native_channel.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _hasAccess = false;
  List<Map<String, dynamic>> _log = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final hasAccess = await NativeChannel.hasNotificationAccess();
    List<Map<String, dynamic>> log = [];
    if (hasAccess) {
      log = await NativeChannel.getNotificationLog();
    }
    if (mounted) {
      setState(() {
        _hasAccess = hasAccess;
        _log = log;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaties'),
        actions: [
          if (_hasAccess)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() => _loading = true);
                _loadData();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_hasAccess
              ? _buildPermissionRequest(theme)
              : _buildNotificationList(theme),
    );
  }

  Widget _buildPermissionRequest(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off,
                size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Notificatie Toegang Nodig',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Om te zien welke apps notificaties sturen, heeft Device Info toegang nodig tot notificaties. '
              'Dit is een speciale permissie die je in de instellingen moet geven.',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                await NativeChannel.openNotificationSettings();
              },
              icon: const Icon(Icons.settings),
              label: const Text('Open Instellingen'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() => _loading = true);
                _loadData();
              },
              child: const Text('Opnieuw controleren'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(ThemeData theme) {
    if (_log.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_active,
                size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            const Text('Nog geen notificaties ontvangen'),
            const SizedBox(height: 8),
            Text(
              'Notificaties worden gelogd zodra ze binnenkomen.\nHoud de app draaiende op de achtergrond.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    // Group by package
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final n in _log) {
      final pkg = n['packageName']?.toString() ?? '';
      grouped.putIfAbsent(pkg, () => []).add(n);
    }
    final sortedApps = grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${_log.length} notificaties van ${grouped.length} apps gelogd',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Summary per app
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Per app', style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary)),
        ),
        ...sortedApps.map((entry) {
          final appNotifs = entry.value;
          final pkg = entry.key;
          final lastNotif = appNotifs.first;
          final lastTime = DateTime.fromMillisecondsSinceEpoch(
              lastNotif['timestamp'] as int? ?? 0);
          final timeStr = _formatTime(lastTime);

          return ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text('${appNotifs.length}',
                  style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold)),
            ),
            title: Text(pkg.split('.').last),
            subtitle: Text('$pkg\nLaatste: $timeStr'),
            children: appNotifs.take(10).map((n) {
              final title = n['title']?.toString() ?? '';
              final text = n['text']?.toString() ?? '';
              final ts = DateTime.fromMillisecondsSinceEpoch(
                  n['timestamp'] as int? ?? 0);
              return ListTile(
                dense: true,
                title: Text(title.isNotEmpty ? title : '(geen titel)',
                    style: theme.textTheme.bodyMedium),
                subtitle: Text(text.isNotEmpty ? text : '(geen tekst)',
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: Text(_formatTime(ts),
                    style: theme.textTheme.labelSmall),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Zojuist';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}u';
    return '${diff.inDays}d';
  }
}
