package com.ligg.anime_flow

import android.net.TrafficStats
import android.os.SystemClock
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.math.max

/** Samples total interface traffic and reports download/upload bytes per second. */
class NetworkSpeedHandler : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "network_speed_monitor"
    }

    private var lastRxBytes: Long? = null
    private var lastTxBytes: Long? = null
    private var lastTimeMs: Long? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                reset()
                lastTimeMs = SystemClock.elapsedRealtime()
                lastRxBytes = readRxBytes()
                lastTxBytes = readTxBytes()
                result.success(null)
            }
            "stop" -> {
                reset()
                result.success(null)
            }
            "get" -> reportSpeed(result)
            else -> result.notImplemented()
        }
    }

    private fun reportSpeed(result: MethodChannel.Result) {
        val rxNow = readRxBytes()
        val txNow = readTxBytes()
        val now = SystemClock.elapsedRealtime()

        val lastTime = lastTimeMs
        val lastRx = lastRxBytes
        val lastTx = lastTxBytes

        // The first sample establishes a baseline without reporting a spike.
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
        // Some devices reset their counters; never report negative speeds.
        val safeRxDelta = if (rxDelta < 0) 0L else rxDelta
        val safeTxDelta = if (txDelta < 0) 0L else txDelta

        val dtSec = dtMs.toDouble() / 1000.0
        val downBps = (safeRxDelta.toDouble() / dtSec).toLong()
        val upBps = (safeTxDelta.toDouble() / dtSec).toLong()

        lastTimeMs = now
        lastRxBytes = rxNow
        lastTxBytes = txNow

        result.success(mapOf("download" to downBps, "upload" to upBps))
    }

    private fun reset() {
        lastRxBytes = null
        lastTxBytes = null
        lastTimeMs = null
    }

    private fun readRxBytes(): Long {
        val bytes = TrafficStats.getTotalRxBytes()
        return if (bytes >= 0) bytes else 0L
    }

    private fun readTxBytes(): Long {
        val bytes = TrafficStats.getTotalTxBytes()
        return if (bytes >= 0) bytes else 0L
    }
}
