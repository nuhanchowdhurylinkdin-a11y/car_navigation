package com.nuhan.navtest

import com.nuhan.navtest.location.LocationPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var locationPlugin: LocationPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        locationPlugin = LocationPlugin(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        locationPlugin?.onRequestPermissionsResult(requestCode, grantResults)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        locationPlugin?.dispose()
        locationPlugin = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
