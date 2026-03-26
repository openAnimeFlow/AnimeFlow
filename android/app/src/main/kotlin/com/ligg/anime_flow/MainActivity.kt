package com.ligg.anime_flow

import android.net.TrafficStats
import android.os.SystemClock
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import kotlin.math.max

class MainActivity : FlutterActivity() {
    private val channelName = "network_speed_monitor"
    private lateinit var methodChannel: MethodChannel

    // Native 侧用于计算速率的基准值
    private var lastRxBytes: Long? = null
    private var lastTxBytes: Long? = null
    private var lastTimeMs: Long? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
