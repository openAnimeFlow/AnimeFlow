package com.ligg.anime_flow

import android.content.Intent
import android.os.Build
import android.os.Process
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterShellArgs
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val downloadStorageHandler by lazy { DownloadStorageHandler(this) }
    private val networkSpeedHandler by lazy { NetworkSpeedHandler() }

    override fun getFlutterShellArgs(): FlutterShellArgs {
        val args = super.getFlutterShellArgs()
        if (Build.SUPPORTED_ABIS.contains("armeabi-v7a") && !Process.is64Bit()) {
            args.add(FlutterShellArgs.ARG_DISABLE_IMPELLER)
        }
        return args
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DownloadStorageHandler.CHANNEL)
            .setMethodCallHandler(downloadStorageHandler)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NetworkSpeedHandler.CHANNEL)
            .setMethodCallHandler(networkSpeedHandler)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        downloadStorageHandler.onActivityResult(requestCode)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        downloadStorageHandler.onRequestPermissionsResult(requestCode)
    }
}
