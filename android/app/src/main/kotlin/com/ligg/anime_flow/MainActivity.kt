package com.ligg.anime_flow

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Process
import android.net.TrafficStats
import android.os.SystemClock
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterShellArgs
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import kotlin.math.max

class MainActivity : FlutterActivity() {
    private val channelName = "network_speed_monitor"
    private lateinit var methodChannel: MethodChannel
    private var storageAccessResult: MethodChannel.Result? = null
    private val storageAccessRequestCode = 48107

    override fun getFlutterShellArgs(): FlutterShellArgs {
        val args = super.getFlutterShellArgs()
        if (Build.SUPPORTED_ABIS.contains("armeabi-v7a") && !Process.is64Bit()) {
            args.add(FlutterShellArgs.ARG_DISABLE_IMPELLER)
        }
        return args
    }

    // Native 侧用于计算速率的基准值
    private var lastRxBytes: Long? = null
    private var lastTxBytes: Long? = null
    private var lastTimeMs: Long? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "anime_flow/download_storage")
            .setMethodCallHandler { call, result ->
                if (call.method == "requestAccess") {
                    requestDownloadStorageAccess(result)
                } else {
                    result.notImplemented()
                }
            }

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        methodChannel.setMethodCallHandler(object : MethodCallHandler {
            override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
                when (call.method) {
                    "start" -> {
                        // 重置基准（native 侧自行计算 delta/dt）
                        reset()
                        val now = SystemClock.elapsedRealtime()
                        lastTimeMs = now
                        lastRxBytes = readRxBytes()
                        lastTxBytes = readTxBytes()
                        result.success(null)
                    }
                    "stop" -> {
                        reset()
                        result.success(null)
                    }
                    "get" -> {
                        val rxNow = readRxBytes()
                        val txNow = readTxBytes()
                        val now = SystemClock.elapsedRealtime()

                        val lastTime = lastTimeMs
                        val lastRx = lastRxBytes
                        val lastTx = lastTxBytes

                        // 第一次/异常时返回 0，并把基准更新为当前值
                        if (lastTime == null || lastRx == null || lastTx == null) {
                            lastTimeMs = now
                            lastRxBytes = rxNow
                            lastTxBytes = txNow
                            result.success(mapOf("download" to 0, "upload" to 0))
                            return
                        }

                        val dtMs = max(0L, now - lastTime)
                        if (dtMs <= 0L) {
                            result.success(mapOf("download" to 0, "upload" to 0))
                            return
                        }

                        val rxDelta = rxNow - lastRx
                        val txDelta = txNow - lastTx
                        // TrafficStats 可能在某些设备上重置计数，保护一下负值
                        val safeRxDelta = if (rxDelta < 0) 0L else rxDelta
                        val safeTxDelta = if (txDelta < 0) 0L else txDelta

                        val dtSec = dtMs.toDouble() / 1000.0
                        val downBps = (safeRxDelta.toDouble() / dtSec).toLong()
                        val upBps = (safeTxDelta.toDouble() / dtSec).toLong()

                        // 更新基准
                        lastTimeMs = now
                        lastRxBytes = rxNow
                        lastTxBytes = txNow

                        result.success(mapOf("download" to downBps, "upload" to upBps))
                    }
                    else -> result.notImplemented()
                }
            }
        })
    }

    private fun hasDownloadStorageAccess(): Boolean {
        return when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.R -> Environment.isExternalStorageManager()
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M ->
                checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
            else -> true
        }
    }

    private fun requestDownloadStorageAccess(result: MethodChannel.Result) {
        if (storageAccessResult != null) {
            result.error("request_in_progress", "A storage access request is already active", null)
            return
        }
        if (hasDownloadStorageAccess()) {
            result.success(true)
            return
        }
        storageAccessResult = result
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                try {
                    startActivityForResult(
                        Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                            Uri.parse("package:$packageName")),
                        storageAccessRequestCode,
                    )
                } catch (_: ActivityNotFoundException) {
                    startActivityForResult(
                        Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION),
                        storageAccessRequestCode,
                    )
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                requestPermissions(arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE), storageAccessRequestCode)
            }
        } catch (error: Exception) {
            storageAccessResult = null
            result.error("storage_access_failed", error.message, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == storageAccessRequestCode) completeStorageAccessRequest()
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == storageAccessRequestCode) completeStorageAccessRequest()
    }

    private fun completeStorageAccessRequest() {
        val result = storageAccessResult
        storageAccessResult = null
        result?.success(hasDownloadStorageAccess())
    }

    private fun reset() {
        lastRxBytes = null
        lastTxBytes = null
        lastTimeMs = null
    }

    private fun readRxBytes(): Long {
        // Total bytes across interfaces; 用于计算 delta/dt 得到上下行速率
        val v = TrafficStats.getTotalRxBytes()
        return if (v >= 0) v else 0L
    }

    private fun readTxBytes(): Long {
        val v = TrafficStats.getTotalTxBytes()
        return if (v >= 0) v else 0L
    }
}
