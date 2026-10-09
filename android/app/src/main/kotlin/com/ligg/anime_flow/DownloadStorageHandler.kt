package com.ligg.anime_flow

import android.Manifest
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/** Storage access for direct filesystem downloads and offline playback. */
class DownloadStorageHandler(private val activity: Activity) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "anime_flow/download_storage"
        private const val STORAGE_ACCESS_REQUEST_CODE = 48107
    }

    private var storageAccessResult: MethodChannel.Result? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestAccess" -> requestStorageAccess(result)
            "hasDirectoryAccess" -> {
                val path = call.argument<String>("path")
                result.success(path != null && hasDirectoryAccess(path))
            }
            else -> result.notImplemented()
        }
    }

    fun onActivityResult(requestCode: Int) {
        if (requestCode == STORAGE_ACCESS_REQUEST_CODE) completeStorageAccessRequest()
    }

    fun onRequestPermissionsResult(requestCode: Int) {
        if (requestCode == STORAGE_ACCESS_REQUEST_CODE) completeStorageAccessRequest()
    }

    private fun hasStorageAccess(): Boolean {
        return when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.R -> Environment.isExternalStorageManager()
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M ->
                activity.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
            else -> true
        }
    }

    // Background checks never open the storage permission UI. App-owned storage
    // remains usable when shared-storage permission is denied or revoked.
    private fun hasDirectoryAccess(path: String): Boolean {
        return try {
            val directory = File(path)
            if (!directory.isAbsolute) return false
            val canonicalPath = directory.canonicalPath
            val privateRoots = listOfNotNull(activity.filesDir.parentFile, *activity.getExternalFilesDirs(null))
            privateRoots.any { root ->
                val rootPath = root.canonicalPath
                canonicalPath == rootPath || canonicalPath.startsWith(rootPath + File.separator)
            } || hasStorageAccess()
        } catch (_: Exception) {
            false
        }
    }

    private fun requestStorageAccess(result: MethodChannel.Result) {
        if (storageAccessResult != null) {
            result.error("request_in_progress", "A storage access request is already active", null)
            return
        }
        if (hasStorageAccess()) {
            result.success(true)
            return
        }
        storageAccessResult = result
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                try {
                    activity.startActivityForResult(
                        Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                            Uri.parse("package:${activity.packageName}")),
                        STORAGE_ACCESS_REQUEST_CODE,
                    )
                } catch (_: ActivityNotFoundException) {
                    activity.startActivityForResult(
                        Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION),
                        STORAGE_ACCESS_REQUEST_CODE,
                    )
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                activity.requestPermissions(arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE), STORAGE_ACCESS_REQUEST_CODE)
            }
        } catch (error: Exception) {
            storageAccessResult = null
            result.error("storage_access_failed", error.message, null)
        }
    }

    private fun completeStorageAccessRequest() {
        val result = storageAccessResult
        storageAccessResult = null
        result?.success(hasStorageAccess())
    }
}
