import 'package:flutter/material.dart';

class AppListTile extends StatelessWidget {
  final String appName;
  final String packageName;
  final bool isSystemApp;
  final String? subtitle;
  final Widget? trailing;

  const AppListTile({
    super.key,
    required this.appName,
    required this.packageName,
    required this.isSystemApp,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isSystemApp
            ? theme.colorScheme.secondaryContainer
            : theme.colorScheme.primaryContainer,
        child: Icon(
          isSystemApp ? Icons.android : Icons.apps,
          color: isSystemApp
              ? theme.colorScheme.onSecondaryContainer
              : theme.colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(appName),
      subtitle: Text(
        subtitle ?? packageName,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing ??
          (isSystemApp
              ? Chip(
                  label: const Text('Systeem'),
                  labelStyle: theme.textTheme.labelSmall,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                )
              : null),
    );
  }
}
