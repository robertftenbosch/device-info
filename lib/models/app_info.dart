class AppPermissionInfo {
  final String packageName;
  final String appName;
  final bool isSystemApp;
  final bool isEnabled;

  AppPermissionInfo({
    required this.packageName,
    required this.appName,
    required this.isSystemApp,
    required this.isEnabled,
  });

  factory AppPermissionInfo.fromMap(Map<dynamic, dynamic> map) {
    return AppPermissionInfo(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      isSystemApp: map['isSystemApp'] as bool,
      isEnabled: map['isEnabled'] as bool,
    );
  }
}

class RunningAppInfo {
  final String packageName;
  final String appName;
  final bool isSystemApp;
  final int lastUsed;
  final int totalForegroundTime;

  RunningAppInfo({
    required this.packageName,
    required this.appName,
    required this.isSystemApp,
    required this.lastUsed,
    required this.totalForegroundTime,
  });

  factory RunningAppInfo.fromMap(Map<dynamic, dynamic> map) {
    return RunningAppInfo(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      isSystemApp: map['isSystemApp'] as bool,
      lastUsed: map['lastUsed'] as int,
      totalForegroundTime: map['totalForegroundTime'] as int,
    );
  }

  String get lastUsedFormatted {
    final date = DateTime.fromMillisecondsSinceEpoch(lastUsed);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Zojuist';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min geleden';
    if (diff.inHours < 24) return '${diff.inHours} uur geleden';
    return '${diff.inDays} dagen geleden';
  }

  String get foregroundTimeFormatted {
    final minutes = totalForegroundTime ~/ 60000;
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}u ${remainingMinutes}m';
  }
}

class RunningServiceInfo {
  final String packageName;
  final String serviceName;
  final String appName;
  final bool isSystemApp;
  final int pid;
  final bool isForeground;

  RunningServiceInfo({
    required this.packageName,
    required this.serviceName,
    required this.appName,
    required this.isSystemApp,
    required this.pid,
    required this.isForeground,
  });

  factory RunningServiceInfo.fromMap(Map<dynamic, dynamic> map) {
    return RunningServiceInfo(
      packageName: map['packageName'] as String,
      serviceName: map['serviceName'] as String,
      appName: map['appName'] as String,
      isSystemApp: map['isSystemApp'] as bool,
      pid: map['pid'] as int,
      isForeground: map['isForeground'] as bool,
    );
  }

  String get shortServiceName {
    final parts = serviceName.split('.');
    return parts.last;
  }
}
