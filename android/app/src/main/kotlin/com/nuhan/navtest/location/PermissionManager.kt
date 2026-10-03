package com.nuhan.navtest.location

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodChannel

class PermissionManager(private val activity: Activity) {
    companion object {
        const val REQUEST_CODE = 4821
        const val GRANTED = "granted"
        const val DENIED = "denied"
        const val DENIED_FOREVER = "deniedForever"

        private const val PREFS_NAME = "navtest_location"
        private const val KEY_ASKED = "location_permission_asked"

        private val PERMISSIONS = arrayOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        )
    }

    private val prefs = activity.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    private var pendingResult: MethodChannel.Result? = null

     fun hasPermission(): Boolean = hasFinePermission() || isGranted(Manifest.permission.ACCESS_COARSE_LOCATION)

    fun hasFinePermission(): Boolean = isGranted(Manifest.permission.ACCESS_FINE_LOCATION)

    fun currentStatus(): String {
        if (hasPermission()) return GRANTED
        // Android can't tell us "don't ask again" directly. If the user already answered
        // once and we're not allowed to show a rationale, the dialog won't appear anymore.
        val askedBefore = prefs.getBoolean(KEY_ASKED, false)
        val canShowDialog = ActivityCompat.shouldShowRequestPermissionRationale(
            activity, Manifest.permission.ACCESS_FINE_LOCATION,
        )
        return if (askedBefore && !canShowDialog) DENIED_FOREVER else DENIED
    }

    fun request(result: MethodChannel.Result) {
        if (hasPermission()) {
            result.success(GRANTED)
            return
        }
        if (pendingResult != null) {
            result.error(LocationErrors.REQUEST_IN_PROGRESS, "A permission request is already running", null)
            return
        }
        pendingResult = result
        ActivityCompat.requestPermissions(activity, PERMISSIONS, REQUEST_CODE)
    }

     fun onRequestPermissionsResult(requestCode: Int, grantResults: IntArray): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val result = pendingResult ?: return true
        pendingResult = null

        // Empty result = dialog was dismissed, not a real answer.
        if (grantResults.isEmpty()) {
            result.success(if (hasPermission()) GRANTED else DENIED)
            return true
        }
        prefs.edit().putBoolean(KEY_ASKED, true).apply()
        result.success(currentStatus())
        return true
    }

    fun openAppSettings(): Boolean = startSafely(
        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", activity.packageName, null)),
    )

    fun openLocationSettings(): Boolean = startSafely(Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS))

    fun dispose() {
        pendingResult = null
    }

    private fun isGranted(permission: String): Boolean =
        ContextCompat.checkSelfPermission(activity, permission) == PackageManager.PERMISSION_GRANTED

    private fun startSafely(intent: Intent): Boolean = try {
        activity.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (e: Exception) {
        false
    }
}
