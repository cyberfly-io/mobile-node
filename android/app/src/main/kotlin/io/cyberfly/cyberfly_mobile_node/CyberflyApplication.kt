package io.cyberfly.cyberfly_mobile_node

import android.content.Context
import android.util.Log
import io.flutter.app.FlutterApplication

/**
 * Runs for every process start of this app, including the headless process
 * that flutter_background_service creates on BOOT_COMPLETED. Ensures the
 * Rust .so is loaded (so `JNI_OnLoad` captures the JavaVM) and that the
 * Android Context is handed to `ndk-context` before any FFI call.
 */
class CyberflyApplication : FlutterApplication() {

    override fun onCreate() {
        super.onCreate()
        try {
            System.loadLibrary("rust_lib_cyberfly_mobile_node")
        } catch (t: Throwable) {
            Log.e(TAG, "loadLibrary failed", t)
            return
        }
        try {
            nativeInitAndroidContext(applicationContext)
            initialized = true
        } catch (t: Throwable) {
            Log.e(TAG, "nativeInitAndroidContext failed", t)
        }
    }

    companion object {
        private const val TAG = "CyberflyApplication"
        @JvmStatic
        var initialized: Boolean = false
            private set
    }

    private external fun nativeInitAndroidContext(ctx: Context)
}
