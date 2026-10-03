package com.nuhan.navtest.location

import android.app.Activity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class LocationPlugin(activity: Activity, messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {
    companion object {
        const val METHOD_CHANNEL = "com.nuhan.navtest/location"
        const val EVENT_CHANNEL = "com.nuhan.navtest/location_stream"
        private const val DEFAULT_TIMEOUT_MS = 15_000L
    }

    private val methodChannel = MethodChannel(messenger, METHOD_CHANNEL)
    private val eventChannel = EventChannel(messenger, EVENT_CHANNEL)
    private val permissions = PermissionManager(activity)
    private val provider = LocationProvider(activity, permissions)
    private val streamHandler = LocationStreamHandler(activity, permissions, provider)

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(streamHandler)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkPermission" -> result.success(permissions.currentStatus())
            "requestPermission" -> permissions.request(result)
            "isLocationServiceEnabled" -> result.success(provider.isServiceEnabled())
            "getCurrentLocation" -> {
                val timeoutMs = (call.argument<Any>("timeoutMs") as? Number)?.toLong() ?: DEFAULT_TIMEOUT_MS
                provider.getCurrentLocation(timeoutMs, result)
            }
            "openAppSettings" -> result.success(permissions.openAppSettings())
            "openLocationSettings" -> result.success(permissions.openLocationSettings())
            else -> result.notImplemented()
        }
    }

    fun onRequestPermissionsResult(requestCode: Int, grantResults: IntArray): Boolean =
        permissions.onRequestPermissionsResult(requestCode, grantResults)

    fun dispose() {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        streamHandler.stopUpdates()
        provider.dispose()
        permissions.dispose()
    }
}
