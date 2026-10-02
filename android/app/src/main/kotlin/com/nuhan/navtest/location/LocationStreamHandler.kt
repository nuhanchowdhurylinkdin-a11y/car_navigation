package com.nuhan.navtest.location

import android.annotation.SuppressLint
import android.content.Context
import android.os.Looper
import android.util.Log
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import io.flutter.plugin.common.EventChannel

/**
 * Continuous location updates over an EventChannel.
 * Updates run only between onListen and onCancel: when Dart cancels its
 * subscription, the native location request is removed immediately.
 */
class LocationStreamHandler(
    context: Context,
    private val permissions: PermissionManager,
    private val provider: LocationProvider,
) : EventChannel.StreamHandler {

    companion object {
        private const val TAG = "NavTestLocation"
        private const val INTERVAL_MS = 2_000L
        private const val MIN_INTERVAL_MS = 1_000L
    }

    private val fusedClient = LocationServices.getFusedLocationProviderClient(context.applicationContext)
    private var callback: LocationCallback? = null

    @SuppressLint("MissingPermission") // checked via permissions.hasPermission()
    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        stopUpdates()

        if (!permissions.hasPermission()) {
            val code = if (permissions.currentStatus() == PermissionManager.DENIED_FOREVER) {
                LocationErrors.PERMISSION_DENIED_FOREVER
            } else {
                LocationErrors.PERMISSION_DENIED
            }
            events.error(code, "Location permission not granted", null)
            return
        }
        if (!provider.isServiceEnabled()) {
            events.error(LocationErrors.SERVICE_DISABLED, "Location services are turned off", null)
            return
        }

        val isPrecise = permissions.hasFinePermission()
        val priority = if (isPrecise) Priority.PRIORITY_HIGH_ACCURACY else Priority.PRIORITY_BALANCED_POWER_ACCURACY
        val request = LocationRequest.Builder(priority, INTERVAL_MS)
            .setMinUpdateIntervalMillis(MIN_INTERVAL_MS)
            .build()

        val newCallback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                result.lastLocation?.let { events.success(it.toMap(isPrecise)) }
            }
        }
        callback = newCallback

        try {
            fusedClient.requestLocationUpdates(request, newCallback, Looper.getMainLooper())
            Log.d(TAG, "Location updates started")
        } catch (e: SecurityException) {
            callback = null
            events.error(LocationErrors.PERMISSION_DENIED, e.message, null)
        }
    }

    override fun onCancel(arguments: Any?) {
        stopUpdates()
    }

    fun stopUpdates() {
        val current = callback ?: return
        fusedClient.removeLocationUpdates(current)
        callback = null
        Log.d(TAG, "Location updates stopped")
    }
}
