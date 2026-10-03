package com.nuhan.navtest.location

// Keep in sync with NativeLocationService.mapError on the Dart side.
object LocationErrors {
    const val PERMISSION_DENIED = "PERMISSION_DENIED"
    const val PERMISSION_DENIED_FOREVER = "PERMISSION_DENIED_FOREVER"
    const val SERVICE_DISABLED = "SERVICE_DISABLED"
    const val TIMEOUT = "TIMEOUT"
    const val UNAVAILABLE = "UNAVAILABLE"
    const val REQUEST_IN_PROGRESS = "REQUEST_IN_PROGRESS"
}
