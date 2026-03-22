import 'package:flutter/services.dart';
import '../models/app_info.dart';

class NativeChannel {
  static const _channel = MethodChannel('com.deviceinfo/native');

  // ==================== EXISTING ====================

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

  // ==================== PERMISSIONS & PRIVACY ====================

  static Future<List<Map<String, dynamic>>> getOverlayApps() async {
    final List<dynamic> result =
        await _channel.invokeMethod('getOverlayApps');
    return result.cast<Map<dynamic, dynamic>>().map((e) =>
        e.map((k, v) => MapEntry(k.toString(), v))).toList();
  }

  static Future<List<Map<String, dynamic>>> getAccessibilityServices() async {
    final List<dynamic> result =
        await _channel.invokeMethod('getAccessibilityServices');
    return result.cast<Map<dynamic, dynamic>>().map((e) =>
        e.map((k, v) => MapEntry(k.toString(), v))).toList();
  }

  static Future<List<Map<String, dynamic>>> getDeviceAdmins() async {
    final List<dynamic> result =
        await _channel.invokeMethod('getDeviceAdmins');
    return result.cast<Map<dynamic, dynamic>>().map((e) =>
        e.map((k, v) => MapEntry(k.toString(), v))).toList();
  }

  // ==================== NETWORK ====================

  static Future<List<Map<String, dynamic>>> getOpenPorts() async {
    final List<dynamic> result =
        await _channel.invokeMethod('getOpenPorts');
    return result.cast<Map<dynamic, dynamic>>().map((e) =>
        e.map((k, v) => MapEntry(k.toString(), v))).toList();
  }

  static Future<List<Map<String, dynamic>>> getActiveConnections() async {
    final List<dynamic> result =
        await _channel.invokeMethod('getActiveConnections');
    return result.cast<Map<dynamic, dynamic>>().map((e) =>
        e.map((k, v) => MapEntry(k.toString(), v))).toList();
  }

  static Future<Map<String, dynamic>> getVpnStatus() async {
    final Map<dynamic, dynamic> result =
        await _channel.invokeMethod('getVpnStatus');
    return result.map((k, v) => MapEntry(k.toString(), v));
  }

  static Future<Map<String, dynamic>> getWifiDetails() async {
    final Map<dynamic, dynamic> result =
        await _channel.invokeMethod('getWifiDetails');
    return result.map((k, v) => MapEntry(k.toString(), v));
  }

  static Future<Map<String, dynamic>> getBluetoothDevices() async {
    final Map<dynamic, dynamic> result =
        await _channel.invokeMethod('getBluetoothDevices');
    return result.map((k, v) => MapEntry(k.toString(), v));
  }

  static Future<List<Map<String, dynamic>>> getNetworkInterfaces() async {
    final List<dynamic> result =
        await _channel.invokeMethod('getNetworkInterfaces');
    return result.cast<Map<dynamic, dynamic>>().map((e) =>
        e.map((k, v) => MapEntry(k.toString(), v))).toList();
  }

  // ==================== SECURITY ====================

  static Future<List<Map<String, dynamic>>> getSideloadedApps() async {
    final List<dynamic> result =
        await _channel.invokeMethod('getSideloadedApps');
    return result.cast<Map<dynamic, dynamic>>().map((e) =>
        e.map((k, v) => MapEntry(k.toString(), v))).toList();
  }

  static Future<Map<String, dynamic>> getRootStatus() async {
    final Map<dynamic, dynamic> result =
        await _channel.invokeMethod('getRootStatus');
    return result.map((k, v) => MapEntry(k.toString(), v));
  }

  static Future<Map<String, dynamic>> getDeveloperOptions() async {
    final Map<dynamic, dynamic> result =
        await _channel.invokeMethod('getDeveloperOptions');
    return result.map((k, v) => MapEntry(k.toString(), v));
  }

  static Future<Map<String, dynamic>> getEncryptionStatus() async {
    final Map<dynamic, dynamic> result =
        await _channel.invokeMethod('getEncryptionStatus');
    return result.map((k, v) => MapEntry(k.toString(), v));
  }

  static Future<Map<String, dynamic>> getSELinuxStatus() async {
    final Map<dynamic, dynamic> result =
        await _channel.invokeMethod('getSELinuxStatus');
    return result.map((k, v) => MapEntry(k.toString(), v));
  }

  // ==================== HARDWARE ====================

  static Future<List<Map<String, dynamic>>> getSensorList() async {
    final List<dynamic> result =
        await _channel.invokeMethod('getSensorList');
    return result.cast<Map<dynamic, dynamic>>().map((e) =>
        e.map((k, v) => MapEntry(k.toString(), v))).toList();
  }

  static Future<Map<String, dynamic>> getTemperatureInfo() async {
    final Map<dynamic, dynamic> result =
        await _channel.invokeMethod('getTemperatureInfo');
    return result.map((k, v) => MapEntry(k.toString(), v));
  }

  static Future<Map<String, dynamic>> getCpuInfo() async {
    final Map<dynamic, dynamic> result =
        await _channel.invokeMethod('getCpuInfo');
    return result.map((k, v) => MapEntry(k.toString(), v));
  }

  static Future<Map<String, int>> getRamInfo() async {
    final Map<dynamic, dynamic> result =
        await _channel.invokeMethod('getRamInfo');
    return result.map((k, v) => MapEntry(k as String, v as int));
  }
}
