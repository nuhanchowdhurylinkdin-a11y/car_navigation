package com.nuhan.navtest.location

/**
 * Error codes sent to Dart via `result.error(code, ...)`.
 * The Dart side maps each code to a typed LocationException, so these
 * strings are part of the channel contract and must match exactly.
 */
object LocationErrors {
    const val PERMISSION_DENIED = "PERMISSION_DENIED"
    const val PERMISSION_DENIED_FOREVER = "PERMISSION_DENIED_FOREVER"
    const val SERVICE_DISABLED = "SERVICE_DISABLED"
    const val TIMEOUT = "TIMEOUT"
    const val UNAVAILABLE = "UNAVAILABLE"
    const val REQUEST_IN_PROGRESS = "REQUEST_IN_PROGRESS"
}
