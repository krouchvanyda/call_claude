package com.enterprise.erp.erp_mobile

import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    /** Matches IncomingCallNotifier.EXTRA_CALL_DATA in the erp_callkit plugin. */
    private val callDataExtra = "erp_call_data"

    /** Flutter ↔ native bridge for the "drop back to lock screen" handoff. */
    private val lockChannelName = "erp/lockscreen"

    /**
     * True while THIS activity is showing OVER a locked keyguard because a
     * call notification launched it (full-screen / body / Accept intent).
     * Drives the "return to the lock screen when the call ends" behaviour
     * so a call answered from the lock screen doesn't leave the app sitting
     * unlocked on the dashboard afterwards.
     */
    private var shownOverLockscreen = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, lockChannelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                // Called by the Dart call-end path. Returns true if it
                // actually dropped the app behind the keyguard.
                "returnToLockScreenIfShownOver" ->
                    result.success(returnToLockScreenIfNeeded())
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        maybeShowOverLockscreen(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        maybeShowOverLockscreen(intent)
    }

    /**
     * When MainActivity is launched by the native incoming-call
     * notification's full-screen / body / Accept intent (it carries the
     * `erp_call_data` bundle), turn the screen on and show OVER the
     * keyguard so the user actually sees the in-app incoming-call UI on a
     * locked device.
     *
     * We deliberately do NOT dismiss the keyguard: the call UI shows on top
     * of it, the device stays locked, and ending the call returns the user
     * to the lock screen (not the unlocked dashboard). `setShowWhenLocked`
     * already makes the Accept / Reject / in-call controls fully tappable
     * without unlocking, so a separate `requestDismissKeyguard` would only
     * bypass the lock — which is exactly what we're avoiding here.
     *
     * Only applied for call launches — a normal launcher start never
     * carries this extra, so the app keeps the standard lock behaviour.
     */
    private fun maybeShowOverLockscreen(intent: Intent?) {
        val isCall = intent?.hasExtra(callDataExtra) == true
        if (!isCall) return

        val km = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
        val locked = km?.isKeyguardLocked == true

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }
        // Remember we came up over a LOCKED device so the call-end handoff
        // knows to drop us back behind the keyguard.
        if (locked) shownOverLockscreen = true
    }

    /**
     * Called from Flutter the moment a call ends. If this activity was
     * launched over a locked keyguard for that call AND the device is still
     * locked (the user never authenticated during the call), send the app
     * behind the lock screen instead of leaving it on top of the keyguard.
     * If the user unlocked mid-call, we stay put — they chose to come in.
     */
    private fun returnToLockScreenIfNeeded(): Boolean {
        if (!shownOverLockscreen) return false
        shownOverLockscreen = false

        val km = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
        val stillLocked = km?.isKeyguardLocked == true
        if (!stillLocked) return false // user unlocked during the call — stay

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            // Stop showing over the keyguard, then drop behind it.
            setShowWhenLocked(false)
            setTurnScreenOn(false)
        }
        // Reveal the keyguard again by sending our task to the background.
        moveTaskToBack(true)
        return true
    }
}
