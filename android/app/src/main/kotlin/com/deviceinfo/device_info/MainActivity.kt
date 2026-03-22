package com.deviceinfo.device_info

import android.app.ActivityManager
import android.app.AppOpsManager
import android.app.admin.DevicePolicyManager
import android.app.usage.UsageStatsManager
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorManager
import android.hardware.camera2.CameraManager
import android.media.AudioManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.File
import java.io.FileReader
import java.io.InputStreamReader
import java.net.NetworkInterface

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
                "getRunningApps" -> result.success(getRunningApps())
                "getRunningServices" -> result.success(getRunningServices())
                "isMicrophoneActive" -> result.success(isMicrophoneActive())
                "isCameraActive" -> result.success(isCameraActive())
                "getStorageInfo" -> result.success(getStorageInfo())
                "hasUsageStatsPermission" -> result.success(hasUsageStatsPermission())
                "openUsageStatsSettings" -> { openUsageStatsSettings(); result.success(true) }
                // New: Permissions & Privacy
                "getOverlayApps" -> result.success(getOverlayApps())
                "getAccessibilityServices" -> result.success(getAccessibilityServices())
                "getDeviceAdmins" -> result.success(getDeviceAdmins())
                // New: Network
                "getOpenPorts" -> result.success(getOpenPorts())
                "getActiveConnections" -> result.success(getActiveConnections())
                "getVpnStatus" -> result.success(getVpnStatus())
                "getWifiDetails" -> result.success(getWifiDetails())
                "getBluetoothDevices" -> result.success(getBluetoothDevices())
                "getNetworkInterfaces" -> result.success(getNetworkInterfaces())
                // New: Security
                "getSideloadedApps" -> result.success(getSideloadedApps())
                "getRootStatus" -> result.success(getRootStatus())
                "getDeveloperOptions" -> result.success(getDeveloperOptions())
                "getEncryptionStatus" -> result.success(getEncryptionStatus())
                "getSELinuxStatus" -> result.success(getSELinuxStatus())
                // New: Hardware
                "getSensorList" -> result.success(getSensorList())
                "getTemperatureInfo" -> result.success(getTemperatureInfo())
                "getCpuInfo" -> result.success(getCpuInfo())
                "getRamInfo" -> result.success(getRamInfo())
                else -> result.notImplemented()
            }
        }
    }

    // ==================== EXISTING METHODS ====================

    private fun getAppsWithPermission(permission: String): List<Map<String, Any>> {
        val pm = packageManager
        val apps = mutableListOf<Map<String, Any>>()
        val installedPackages = pm.getInstalledPackages(PackageManager.GET_PERMISSIONS)
        for (pkg in installedPackages) {
            val requestedPermissions = pkg.requestedPermissions ?: continue
            if (requestedPermissions.contains(permission)) {
                val appInfo = pkg.applicationInfo ?: continue
                val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                apps.add(mapOf(
                    "packageName" to pkg.packageName,
                    "appName" to pm.getApplicationLabel(appInfo).toString(),
                    "isSystemApp" to isSystemApp,
                    "isEnabled" to appInfo.enabled
                ))
            }
        }
        return apps.sortedBy { it["appName"] as String }
    }

    private fun getRunningApps(): List<Map<String, Any>> {
        val apps = mutableListOf<Map<String, Any>>()
        if (hasUsageStatsPermission()) {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val now = System.currentTimeMillis()
            val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, now - 86400000, now)
            val pm = packageManager
            for (stat in stats) {
                if (stat.totalTimeInForeground > 0) {
                    try {
                        val appInfo = pm.getApplicationInfo(stat.packageName, 0)
                        val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                        apps.add(mapOf(
                            "packageName" to stat.packageName,
                            "appName" to pm.getApplicationLabel(appInfo).toString(),
                            "isSystemApp" to isSystemApp,
                            "lastUsed" to stat.lastTimeUsed,
                            "totalForegroundTime" to stat.totalTimeInForeground
                        ))
                    } catch (_: PackageManager.NameNotFoundException) {}
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
                services.add(mapOf(
                    "packageName" to pkgName,
                    "serviceName" to service.service.className,
                    "appName" to pm.getApplicationLabel(appInfo).toString(),
                    "isSystemApp" to isSystemApp,
                    "pid" to service.pid,
                    "isForeground" to service.foreground
                ))
            } catch (_: PackageManager.NameNotFoundException) {}
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
                var isActive = false
                val callback = object : CameraManager.AvailabilityCallback() {
                    override fun onCameraUnavailable(cameraId: String) { isActive = true }
                }
                cameraManager.registerAvailabilityCallback(callback, null)
                cameraManager.unregisterAvailabilityCallback(callback)
                return isActive
            } catch (_: Exception) { return false }
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
        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        })
    }

    // ==================== PERMISSIONS & PRIVACY ====================

    private fun getOverlayApps(): List<Map<String, Any>> {
        val pm = packageManager
        val apps = mutableListOf<Map<String, Any>>()
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val installedPackages = pm.getInstalledPackages(PackageManager.GET_PERMISSIONS)
        for (pkg in installedPackages) {
            val perms = pkg.requestedPermissions ?: continue
            if (perms.contains("android.permission.SYSTEM_ALERT_WINDOW")) {
                val appInfo = pkg.applicationInfo ?: continue
                val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                var isGranted = false
                try {
                    val mode = appOps.checkOpNoThrow(
                        AppOpsManager.OPSTR_SYSTEM_ALERT_WINDOW,
                        appInfo.uid,
                        pkg.packageName
                    )
                    isGranted = mode == AppOpsManager.MODE_ALLOWED
                } catch (_: Exception) {}
                apps.add(mapOf(
                    "packageName" to pkg.packageName,
                    "appName" to pm.getApplicationLabel(appInfo).toString(),
                    "isSystemApp" to isSystemApp,
                    "isGranted" to isGranted
                ))
            }
        }
        return apps.sortedBy { it["appName"] as String }
    }

    private fun getAccessibilityServices(): List<Map<String, Any>> {
        val am = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        val services = mutableListOf<Map<String, Any>>()
        val enabledServices = am.getEnabledAccessibilityServiceList(
            android.accessibilityservice.AccessibilityServiceInfo.FEEDBACK_ALL_MASK
        )
        val pm = packageManager
        for (service in enabledServices) {
            val serviceInfo = service.resolveInfo.serviceInfo
            val pkgName = serviceInfo.packageName
            try {
                val appInfo = pm.getApplicationInfo(pkgName, 0)
                val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                services.add(mapOf(
                    "packageName" to pkgName,
                    "appName" to pm.getApplicationLabel(appInfo).toString(),
                    "serviceName" to (service.resolveInfo.serviceInfo.name ?: ""),
                    "description" to (service.description?.toString() ?: ""),
                    "isSystemApp" to isSystemApp
                ))
            } catch (_: PackageManager.NameNotFoundException) {}
        }
        return services
    }

    private fun getDeviceAdmins(): List<Map<String, Any>> {
        val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val admins = mutableListOf<Map<String, Any>>()
        val pm = packageManager
        val activeAdmins = dpm.activeAdmins ?: return admins
        for (admin in activeAdmins) {
            val pkgName = admin.packageName
            try {
                val appInfo = pm.getApplicationInfo(pkgName, 0)
                val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                admins.add(mapOf(
                    "packageName" to pkgName,
                    "appName" to pm.getApplicationLabel(appInfo).toString(),
                    "isSystemApp" to isSystemApp
                ))
            } catch (_: PackageManager.NameNotFoundException) {}
        }
        return admins
    }

    // ==================== NETWORK ====================

    private fun getOpenPorts(): List<Map<String, Any>> {
        val ports = mutableListOf<Map<String, Any>>()
        // Parse /proc/net/tcp and /proc/net/tcp6
        for (proto in listOf("tcp", "tcp6", "udp", "udp6")) {
            try {
                val file = File("/proc/net/$proto")
                if (!file.exists()) continue
                val reader = BufferedReader(FileReader(file))
                reader.readLine() // skip header
                var line = reader.readLine()
                while (line != null) {
                    val parts = line.trim().split("\\s+".toRegex())
                    if (parts.size >= 4) {
                        val localAddr = parts[1]
                        val state = parts[3]
                        val addrParts = localAddr.split(":")
                        if (addrParts.size == 2) {
                            val port = addrParts[1].toIntOrNull(16) ?: 0
                            val stateStr = when (state) {
                                "0A" -> "LISTEN"
                                "01" -> "ESTABLISHED"
                                "06" -> "TIME_WAIT"
                                "08" -> "CLOSE_WAIT"
                                else -> state
                            }
                            if (port > 0) {
                                ports.add(mapOf(
                                    "port" to port,
                                    "protocol" to proto.replace("6", ""),
                                    "state" to stateStr,
                                    "isIPv6" to proto.contains("6")
                                ))
                            }
                        }
                    }
                    line = reader.readLine()
                }
                reader.close()
            } catch (_: Exception) {}
        }
        return ports.distinctBy { "${it["port"]}:${it["protocol"]}:${it["state"]}" }
            .sortedBy { it["port"] as Int }
    }

    private fun getActiveConnections(): List<Map<String, Any>> {
        val connections = mutableListOf<Map<String, Any>>()
        for (proto in listOf("tcp", "tcp6")) {
            try {
                val file = File("/proc/net/$proto")
                if (!file.exists()) continue
                val reader = BufferedReader(FileReader(file))
                reader.readLine() // skip header
                var line = reader.readLine()
                while (line != null) {
                    val parts = line.trim().split("\\s+".toRegex())
                    if (parts.size >= 4) {
                        val state = parts[3]
                        if (state == "01") { // ESTABLISHED
                            val localAddr = parts[1]
                            val remoteAddr = parts[2]
                            val localParts = localAddr.split(":")
                            val remoteParts = remoteAddr.split(":")
                            if (localParts.size == 2 && remoteParts.size == 2) {
                                val localPort = localParts[1].toIntOrNull(16) ?: 0
                                val remotePort = remoteParts[1].toIntOrNull(16) ?: 0
                                val remoteIp = hexToIp(remoteParts[0])
                                connections.add(mapOf(
                                    "localPort" to localPort,
                                    "remoteIp" to remoteIp,
                                    "remotePort" to remotePort,
                                    "protocol" to proto.replace("6", "")
                                ))
                            }
                        }
                    }
                    line = reader.readLine()
                }
                reader.close()
            } catch (_: Exception) {}
        }
        return connections
    }

    private fun hexToIp(hex: String): String {
        if (hex.length == 8) {
            // IPv4 in little-endian hex
            val bytes = (0 until 8 step 2).map { hex.substring(it, it + 2).toInt(16) }
            return "${bytes[3]}.${bytes[2]}.${bytes[1]}.${bytes[0]}"
        }
        return hex // IPv6 - return raw for now
    }

    private fun getVpnStatus(): Map<String, Any> {
        val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val activeNetwork = cm.activeNetwork
        var isVpnActive = false
        var vpnName = ""
        if (activeNetwork != null) {
            val caps = cm.getNetworkCapabilities(activeNetwork)
            if (caps != null && caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) {
                isVpnActive = true
            }
        }
        // Check all networks for VPN
        for (network in cm.allNetworks) {
            val caps = cm.getNetworkCapabilities(network)
            if (caps != null && caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) {
                isVpnActive = true
                break
            }
        }
        return mapOf(
            "isActive" to isVpnActive,
            "vpnName" to vpnName
        )
    }

    @Suppress("DEPRECATION")
    private fun getWifiDetails(): Map<String, Any> {
        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        val info = wifiManager.connectionInfo
        val dhcp = wifiManager.dhcpInfo
        val result = mutableMapOf<String, Any>(
            "isEnabled" to wifiManager.isWifiEnabled,
            "ssid" to (info?.ssid?.replace("\"", "") ?: "Onbekend"),
            "bssid" to (info?.bssid ?: "Onbekend"),
            "rssi" to (info?.rssi ?: 0),
            "linkSpeed" to (info?.linkSpeedMbps ?: 0),
            "frequency" to (info?.frequency ?: 0),
            "ipAddress" to intToIp(info?.ipAddress ?: 0),
            "gateway" to intToIp(dhcp?.gateway ?: 0),
            "dns1" to intToIp(dhcp?.dns1 ?: 0),
            "dns2" to intToIp(dhcp?.dns2 ?: 0),
            "netmask" to intToIp(dhcp?.netmask ?: 0)
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            result["standard"] = when (info?.wifiStandard) {
                4 -> "WiFi 4 (802.11n)"
                5 -> "WiFi 5 (802.11ac)"
                6 -> "WiFi 6 (802.11ax)"
                7 -> "WiFi 7 (802.11be)"
                else -> "Onbekend"
            }
        }
        return result
    }

    private fun intToIp(ip: Int): String {
        return "${ip and 0xFF}.${(ip shr 8) and 0xFF}.${(ip shr 16) and 0xFF}.${(ip shr 24) and 0xFF}"
    }

    @Suppress("MissingPermission")
    private fun getBluetoothDevices(): Map<String, Any> {
        val result = mutableMapOf<String, Any>()
        try {
            val btManager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
            val adapter = btManager.adapter
            if (adapter != null) {
                result["isEnabled"] = adapter.isEnabled
                result["name"] = adapter.name ?: "Onbekend"
                val bondedDevices = mutableListOf<Map<String, String>>()
                for (device in adapter.bondedDevices) {
                    bondedDevices.add(mapOf(
                        "name" to (device.name ?: "Onbekend"),
                        "address" to device.address,
                        "type" to when (device.type) {
                            BluetoothAdapter.STATE_CONNECTED -> "Verbonden"
                            1 -> "Classic"
                            2 -> "BLE"
                            3 -> "Dual"
                            else -> "Onbekend"
                        }
                    ))
                }
                result["bondedDevices"] = bondedDevices
            } else {
                result["isEnabled"] = false
                result["name"] = "Niet beschikbaar"
                result["bondedDevices"] = emptyList<Map<String, String>>()
            }
        } catch (e: Exception) {
            result["isEnabled"] = false
            result["name"] = "Fout: ${e.message}"
            result["bondedDevices"] = emptyList<Map<String, String>>()
        }
        return result
    }

    private fun getNetworkInterfaces(): List<Map<String, Any>> {
        val interfaces = mutableListOf<Map<String, Any>>()
        try {
            val nets = NetworkInterface.getNetworkInterfaces()
            while (nets.hasMoreElements()) {
                val iface = nets.nextElement()
                if (!iface.isUp) continue
                val addrs = mutableListOf<String>()
                val inetAddrs = iface.inetAddresses
                while (inetAddrs.hasMoreElements()) {
                    addrs.add(inetAddrs.nextElement().hostAddress ?: "")
                }
                if (addrs.isNotEmpty()) {
                    interfaces.add(mapOf(
                        "name" to iface.name,
                        "displayName" to iface.displayName,
                        "addresses" to addrs,
                        "isLoopback" to iface.isLoopback,
                        "isVirtual" to iface.isVirtual
                    ))
                }
            }
        } catch (_: Exception) {}
        return interfaces
    }

    // ==================== SECURITY ====================

    private fun getSideloadedApps(): List<Map<String, Any>> {
        val pm = packageManager
        val apps = mutableListOf<Map<String, Any>>()
        val installedPackages = pm.getInstalledPackages(0)
        for (pkg in installedPackages) {
            val appInfo = pkg.applicationInfo ?: continue
            if ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0) continue
            val installer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                try { pm.getInstallSourceInfo(pkg.packageName).installingPackageName } catch (_: Exception) { null }
            } else {
                @Suppress("DEPRECATION")
                pm.getInstallerPackageName(pkg.packageName)
            }
            val isPlayStore = installer == "com.android.vending"
            val isPreinstalled = installer == null && (appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0
            if (!isPlayStore && !isPreinstalled) {
                apps.add(mapOf(
                    "packageName" to pkg.packageName,
                    "appName" to pm.getApplicationLabel(appInfo).toString(),
                    "installer" to (installer ?: "Onbekend"),
                    "isSystemApp" to false
                ))
            }
        }
        return apps.sortedBy { it["appName"] as String }
    }

    private fun getRootStatus(): Map<String, Any> {
        val indicators = mutableListOf<String>()
        // Check common su paths
        val suPaths = listOf("/system/bin/su", "/system/xbin/su", "/sbin/su",
            "/data/local/xbin/su", "/data/local/bin/su", "/system/sd/xbin/su",
            "/system/bin/failsafe/su", "/data/local/su")
        for (path in suPaths) {
            if (File(path).exists()) indicators.add("su binary: $path")
        }
        // Check Magisk
        if (File("/sbin/.magisk").exists() || File("/data/adb/magisk").exists()) {
            indicators.add("Magisk gedetecteerd")
        }
        // Check for SuperSU
        if (File("/system/app/Superuser.apk").exists()) {
            indicators.add("SuperSU gedetecteerd")
        }
        // Check build tags
        val buildTags = Build.TAGS ?: ""
        if (buildTags.contains("test-keys")) {
            indicators.add("Test-keys in build tags")
        }
        // Check bootloader
        val isBootloaderUnlocked = try {
            val process = Runtime.getRuntime().exec("getprop ro.boot.verifiedbootstate")
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            val state = reader.readLine() ?: ""
            reader.close()
            state == "orange"
        } catch (_: Exception) { false }
        if (isBootloaderUnlocked) indicators.add("Bootloader unlocked")

        return mapOf(
            "isRooted" to indicators.isNotEmpty(),
            "isBootloaderUnlocked" to isBootloaderUnlocked,
            "indicators" to indicators
        )
    }

    private fun getDeveloperOptions(): Map<String, Any> {
        val result = mutableMapOf<String, Any>()
        try {
            result["developerEnabled"] = Settings.Global.getInt(
                contentResolver, Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0) == 1
            result["usbDebugging"] = Settings.Global.getInt(
                contentResolver, Settings.Global.ADB_ENABLED, 0) == 1
            result["stayAwake"] = Settings.Global.getInt(
                contentResolver, Settings.Global.STAY_ON_WHILE_PLUGGED_IN, 0) != 0
            result["mockLocation"] = Settings.Secure.getString(
                contentResolver, "mock_location_app") ?: ""
        } catch (_: Exception) {}
        return result
    }

    private fun getEncryptionStatus(): Map<String, Any> {
        val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val status = dpm.storageEncryptionStatus
        val statusStr = when (status) {
            DevicePolicyManager.ENCRYPTION_STATUS_ACTIVE -> "Actief"
            DevicePolicyManager.ENCRYPTION_STATUS_ACTIVE_DEFAULT_KEY -> "Actief (standaard sleutel)"
            DevicePolicyManager.ENCRYPTION_STATUS_ACTIVE_PER_USER -> "Actief (per gebruiker)"
            DevicePolicyManager.ENCRYPTION_STATUS_INACTIVE -> "Inactief"
            DevicePolicyManager.ENCRYPTION_STATUS_UNSUPPORTED -> "Niet ondersteund"
            else -> "Onbekend"
        }
        return mapOf(
            "status" to statusStr,
            "statusCode" to status,
            "isEncrypted" to (status >= DevicePolicyManager.ENCRYPTION_STATUS_ACTIVE)
        )
    }

    private fun getSELinuxStatus(): Map<String, String> {
        return try {
            val process = Runtime.getRuntime().exec("getenforce")
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            val status = reader.readLine() ?: "Onbekend"
            reader.close()
            mapOf(
                "status" to status,
                "isEnforcing" to (status == "Enforcing").toString()
            )
        } catch (_: Exception) {
            mapOf("status" to "Onbekend", "isEnforcing" to "false")
        }
    }

    // ==================== HARDWARE ====================

    private fun getSensorList(): List<Map<String, Any>> {
        val sm = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val sensors = sm.getSensorList(Sensor.TYPE_ALL)
        return sensors.map { sensor ->
            mapOf(
                "name" to sensor.name,
                "type" to sensor.stringType,
                "vendor" to sensor.vendor,
                "version" to sensor.version,
                "power" to sensor.power,
                "maxRange" to sensor.maximumRange,
                "resolution" to sensor.resolution
            )
        }
    }

    private fun getTemperatureInfo(): Map<String, Any> {
        val result = mutableMapOf<String, Any>()
        // Battery temperature
        val bm = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        // Try to read thermal zones
        val thermalZones = mutableListOf<Map<String, String>>()
        try {
            val thermalDir = File("/sys/class/thermal/")
            if (thermalDir.exists()) {
                for (zone in thermalDir.listFiles() ?: emptyArray()) {
                    if (zone.name.startsWith("thermal_zone")) {
                        val typeFile = File(zone, "type")
                        val tempFile = File(zone, "temp")
                        if (typeFile.exists() && tempFile.exists()) {
                            val type = typeFile.readText().trim()
                            val temp = tempFile.readText().trim().toIntOrNull() ?: 0
                            val tempC = if (temp > 1000) temp / 1000.0 else temp.toDouble()
                            thermalZones.add(mapOf(
                                "zone" to zone.name,
                                "type" to type,
                                "temperature" to "%.1f".format(tempC)
                            ))
                        }
                    }
                }
            }
        } catch (_: Exception) {}
        result["thermalZones"] = thermalZones
        return result
    }

    private fun getCpuInfo(): Map<String, Any> {
        val result = mutableMapOf<String, Any>()
        // Number of cores
        result["cores"] = Runtime.getRuntime().availableProcessors()
        // CPU frequencies
        val frequencies = mutableListOf<Map<String, Any>>()
        try {
            val cpuDir = File("/sys/devices/system/cpu/")
            for (i in 0 until Runtime.getRuntime().availableProcessors()) {
                val cpuFreqDir = File(cpuDir, "cpu$i/cpufreq/")
                if (cpuFreqDir.exists()) {
                    val curFreq = File(cpuFreqDir, "scaling_cur_freq").let {
                        if (it.exists()) it.readText().trim().toLongOrNull() ?: 0 else 0
                    }
                    val maxFreq = File(cpuFreqDir, "cpuinfo_max_freq").let {
                        if (it.exists()) it.readText().trim().toLongOrNull() ?: 0 else 0
                    }
                    val minFreq = File(cpuFreqDir, "cpuinfo_min_freq").let {
                        if (it.exists()) it.readText().trim().toLongOrNull() ?: 0 else 0
                    }
                    frequencies.add(mapOf(
                        "core" to i,
                        "currentMHz" to curFreq / 1000,
                        "maxMHz" to maxFreq / 1000,
                        "minMHz" to minFreq / 1000
                    ))
                }
            }
        } catch (_: Exception) {}
        result["frequencies"] = frequencies
        // CPU architecture
        result["abis"] = Build.SUPPORTED_ABIS.toList()
        result["hardware"] = Build.HARDWARE
        // Try to read /proc/cpuinfo for chip name
        try {
            val reader = BufferedReader(FileReader("/proc/cpuinfo"))
            var line = reader.readLine()
            while (line != null) {
                if (line.startsWith("Hardware") || line.startsWith("model name")) {
                    result["chipName"] = line.split(":").getOrNull(1)?.trim() ?: ""
                    break
                }
                line = reader.readLine()
            }
            reader.close()
        } catch (_: Exception) {}
        return result
    }

    private fun getRamInfo(): Map<String, Long> {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memInfo = ActivityManager.MemoryInfo()
        am.getMemoryInfo(memInfo)
        return mapOf(
            "totalBytes" to memInfo.totalMem,
            "availableBytes" to memInfo.availMem,
            "usedBytes" to (memInfo.totalMem - memInfo.availMem),
            "threshold" to memInfo.threshold,
            "isLowMemory" to if (memInfo.lowMemory) 1L else 0L
        )
    }
}
