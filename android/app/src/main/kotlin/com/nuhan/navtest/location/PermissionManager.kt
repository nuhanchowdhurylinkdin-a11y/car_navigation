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

/**
 * Checks and requests foreground location permission.
 *
 * Status strings returned to Dart: "granted", "denied", "deniedForever".
 */
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

    /** True if either precise (FINE) or approximate (COARSE) location is granted. */
    fun hasPermission(): Boolean = hasFinePermission() || isGranted(Manifest.permission.ACCESS_COARSE_LOCATION)

    fun hasFinePermission(): Boolean = isGranted(Manifest.permission.ACCESS_FINE_LOCATION)

    fun currentStatus(): String {
        if (hasPermission()) return GRANTED
        // Android has no direct "permanently denied" API. After the user has answered
        // the dialog at least once, a false rationale means the system will no longer
        // show the dialog ("Don't ask again" / denied twice).
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

    /** Called from MainActivity.onRequestPermissionsResult. Returns true if handled. */
    fun onRequestPermissionsResult(requestCode: Int, grantResults: IntArray): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val result = pendingResult ?: return true
        pendingResult = null

        if (grantResults.isEmpty()) {
            // Dialog was dismissed without an answer (e.g. rotation); not a real denial.
            result.success(if (hasPermission()) GRANTED else DENIED)
            return true
        }
        // Only mark as asked once the user actually answered the dialog.
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
