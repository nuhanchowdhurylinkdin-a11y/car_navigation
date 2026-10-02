package com.nuhan.navtest.location

import android.annotation.SuppressLint
import android.content.Context
import android.location.Location
import android.location.LocationManager
import android.os.Handler
import android.os.Looper
import androidx.core.location.LocationManagerCompat
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
import io.flutter.plugin.common.MethodChannel

/** Wraps FusedLocationProviderClient for one-shot location requests. */
class LocationProvider(
    context: Context,
    private val permissions: PermissionManager,
) {
    private val appContext = context.applicationContext
    private val fusedClient = LocationServices.getFusedLocationProviderClient(appContext)
    private val handler = Handler(Looper.getMainLooper())
    private val activeRequests = mutableSetOf<CancellationTokenSource>()

    fun isServiceEnabled(): Boolean {
        val manager = appContext.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        return LocationManagerCompat.isLocationEnabled(manager)
    }

    @SuppressLint("MissingPermission") // checked via permissions.hasPermission()
    fun getCurrentLocation(timeoutMs: Long, result: MethodChannel.Result) {
        if (!permissions.hasPermission()) {
            val code = if (permissions.currentStatus() == PermissionManager.DENIED_FOREVER) {
                LocationErrors.PERMISSION_DENIED_FOREVER
            } else {
                LocationErrors.PERMISSION_DENIED
            }
            result.error(code, "Location permission not granted", null)
            return
        }
        if (!isServiceEnabled()) {
            result.error(LocationErrors.SERVICE_DISABLED, "Location services are turned off", null)
            return
        }

        val cts = CancellationTokenSource()
        activeRequests.add(cts)
        // The fix and the timeout race each other; only the first may reply,
        // otherwise Flutter throws "Reply already submitted".
        var replied = false

        fun finish(block: () -> Unit) {
            if (replied) return
            replied = true
            activeRequests.remove(cts)
            block()
        }

        val timeout = Runnable {
            finish {
                cts.cancel()
                result.error(LocationErrors.TIMEOUT, "No location fix within ${timeoutMs}ms", null)
            }
        }
        handler.postDelayed(timeout, timeoutMs)

        // Approximate-only permission cannot use high accuracy.
        val priority = if (permissions.hasFinePermission()) {
            Priority.PRIORITY_HIGH_ACCURACY
        } else {
            Priority.PRIORITY_BALANCED_POWER_ACCURACY
        }

        try {
            fusedClient.getCurrentLocation(priority, cts.token)
                .addOnSuccessListener { location ->
                    handler.removeCallbacks(timeout)
                    finish {
                        if (location == null) {
                            result.error(LocationErrors.UNAVAILABLE, "Location is unavailable", null)
                        } else {
                            result.success(location.toMap(isPrecise = permissions.hasFinePermission()))
                        }
                    }
                }
                .addOnFailureListener { e ->
                    handler.removeCallbacks(timeout)
                    finish { result.error(LocationErrors.UNAVAILABLE, e.message ?: "Location request failed", null) }
                }
        } catch (e: SecurityException) {
            handler.removeCallbacks(timeout)
            finish { result.error(LocationErrors.PERMISSION_DENIED, e.message, null) }
        }
    }

    /** Cancels in-flight requests and pending timeouts; no reply is sent after this. */
    fun dispose() {
        handler.removeCallbacksAndMessages(null)
        activeRequests.forEach { it.cancel() }
        activeRequests.clear()
    }
}

internal fun Location.toMap(isPrecise: Boolean): Map<String, Any> = mapOf(
    "lat" to latitude,
    "lng" to longitude,
    "accuracy" to accuracy.toDouble(),
    "bearing" to bearing.toDouble(),
    "speed" to speed.toDouble(),
    "timestamp" to time,
    "isPrecise" to isPrecise,
)
