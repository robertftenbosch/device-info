import 'package:flutter/services.dart';
import '../models/app_info.dart';

class NativeChannel {
  static const _channel = MethodChannel('com.deviceinfo/native');

  static Future<List<AppPermissionInfo>> getAppsWithPermission(
      String permission) async {
    final List<dynamic> result = await _channel.invokeMethod(
      'getAppsWithPermission',
      {'permission': permission},
    );
    return result
        .map((e) => AppPermissionInfo.fromMap(e as Map<dynamic, dynamic>))
        .toList();
  }

  static Future<List<RunningAppInfo>> getRunningApps() async {
    final List<dynamic> result =
        await _channel.invokeMethod('getRunningApps');
    return result
        .map((e) => RunningAppInfo.fromMap(e as Map<dynamic, dynamic>))
        .toList();
  }

  static Future<List<RunningServiceInfo>> getRunningServices() async {
    final List<dynamic> result =
        await _channel.invokeMethod('getRunningServices');
    return result
        .map((e) => RunningServiceInfo.fromMap(e as Map<dynamic, dynamic>))
        .toList();
  }

  static Future<bool> isMicrophoneActive() async {
    return await _channel.invokeMethod('isMicrophoneActive') as bool;
  }

  static Future<bool> isCameraActive() async {
    return await _channel.invokeMethod('isCameraActive') as bool;
  }

  static Future<Map<String, int>> getStorageInfo() async {
    final Map<dynamic, dynamic> result =
        await _channel.invokeMethod('getStorageInfo');
    return result.map((k, v) => MapEntry(k as String, v as int));
  }

  static Future<bool> hasUsageStatsPermission() async {
    return await _channel.invokeMethod('hasUsageStatsPermission') as bool;
  }

  static Future<void> openUsageStatsSettings() async {
    await _channel.invokeMethod('openUsageStatsSettings');
  }
}
