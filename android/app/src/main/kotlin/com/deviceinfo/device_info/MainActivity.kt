package com.deviceinfo.device_info

import android.app.ActivityManager
import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.hardware.camera2.CameraManager
import android.media.AudioManager
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.deviceinfo/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAppsWithPermission" -> {
                    val permission = call.argument<String>("permission")
                    if (permission != null) {
                        result.success(getAppsWithPermission(permission))
                    } else {
                        result.error("INVALID_ARGUMENT", "Permission is required", null)
                    }
                }
                "getRunningApps" -> {
                    result.success(getRunningApps())
                }
                "getRunningServices" -> {
                    result.success(getRunningServices())
                }
                "isMicrophoneActive" -> {
                    result.success(isMicrophoneActive())
                }
                "isCameraActive" -> {
                    result.success(isCameraActive())
                }
                "getStorageInfo" -> {
                    result.success(getStorageInfo())
                }
                "hasUsageStatsPermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "openUsageStatsSettings" -> {
                    openUsageStatsSettings()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getAppsWithPermission(permission: String): List<Map<String, Any>> {
        val pm = packageManager
        val apps = mutableListOf<Map<String, Any>>()

        val installedPackages = pm.getInstalledPackages(PackageManager.GET_PERMISSIONS)
        for (pkg in installedPackages) {
            val requestedPermissions = pkg.requestedPermissions ?: continue
            if (requestedPermissions.contains(permission)) {
                val appInfo = pkg.applicationInfo ?: continue
                val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                apps.add(
                    mapOf(
                        "packageName" to pkg.packageName,
                        "appName" to pm.getApplicationLabel(appInfo).toString(),
                        "isSystemApp" to isSystemApp,
                        "isEnabled" to appInfo.enabled
                    )
                )
            }
        }
        return apps.sortedBy { it["appName"] as String }
    }

    private fun getRunningApps(): List<Map<String, Any>> {
        val apps = mutableListOf<Map<String, Any>>()

        if (hasUsageStatsPermission()) {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val now = System.currentTimeMillis()
            val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, now - 1000 * 60 * 60 * 24, now)

            val pm = packageManager
            for (stat in stats) {
                if (stat.totalTimeInForeground > 0) {
                    try {
                        val appInfo = pm.getApplicationInfo(stat.packageName, 0)
                        val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                        apps.add(
                            mapOf(
                                "packageName" to stat.packageName,
                                "appName" to pm.getApplicationLabel(appInfo).toString(),
                                "isSystemApp" to isSystemApp,
                                "lastUsed" to stat.lastTimeUsed,
                                "totalForegroundTime" to stat.totalTimeInForeground
                            )
                        )
                    } catch (e: PackageManager.NameNotFoundException) {
                        // App was uninstalled
                    }
                }
            }
        }

        return apps.sortedByDescending { it["lastUsed"] as Long }
    }

    private fun getRunningServices(): List<Map<String, Any>> {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val services = mutableListOf<Map<String, Any>>()
        val pm = packageManager

        @Suppress("DEPRECATION")
        val runningServices = am.getRunningServices(200)
        for (service in runningServices) {
            val pkgName = service.service.packageName
            try {
                val appInfo = pm.getApplicationInfo(pkgName, 0)
                val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                services.add(
                    mapOf(
                        "packageName" to pkgName,
                        "serviceName" to service.service.className,
                        "appName" to pm.getApplicationLabel(appInfo).toString(),
                        "isSystemApp" to isSystemApp,
                        "pid" to service.pid,
                        "isForeground" to service.foreground
                    )
                )
            } catch (e: PackageManager.NameNotFoundException) {
                // skip
            }
        }

        return services.distinctBy { it["serviceName"] }.sortedBy { it["appName"] as String }
    }

    private fun isMicrophoneActive(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            return audioManager.mode != AudioManager.MODE_NORMAL
        }
        return false
    }

    private fun isCameraActive(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            try {
                val cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
                // We can't directly check if the camera is in use without a callback,
                // but we register a transient check
                var isActive = false
                val callback = object : CameraManager.AvailabilityCallback() {
                    override fun onCameraUnavailable(cameraId: String) {
                        isActive = true
                    }
                }
                cameraManager.registerAvailabilityCallback(callback, null)
                cameraManager.unregisterAvailabilityCallback(callback)
                return isActive
            } catch (e: Exception) {
                return false
            }
        }
        return false
    }

    private fun getStorageInfo(): Map<String, Long> {
        val stat = StatFs(Environment.getDataDirectory().path)
        val totalBytes = stat.blockSizeLong * stat.blockCountLong
        val availableBytes = stat.blockSizeLong * stat.availableBlocksLong
        return mapOf(
            "totalBytes" to totalBytes,
            "availableBytes" to availableBytes,
            "usedBytes" to (totalBytes - availableBytes)
        )
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun openUsageStatsSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }
}
