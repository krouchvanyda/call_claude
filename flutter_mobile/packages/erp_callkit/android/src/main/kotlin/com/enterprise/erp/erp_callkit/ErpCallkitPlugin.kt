package com.enterprise.erp.erp_callkit

import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Plugin entry point. Registered on EVERY FlutterEngine in the process —
 * including the firebase_messaging background isolate's engine (the
 * default `FlutterEngine(context)` constructor auto-runs
 * GeneratedPluginRegistrant). That is what lets [showIncomingCall] run
 * on a killed-app `call.ring` push, before any Activity exists.
 *
 * ActivityAware is used only on the MAIN engine: when MainActivity is
 * launched from a notification body/Accept tap, we stash the call data
 * in the process-wide [LaunchActionStore] so the Dart side can pull it
 * via `consumeLaunchAction`.
 */
class ErpCallkitPlugin :
    FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private lateinit var appContext: Context
    private var activityBinding: ActivityPluginBinding? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "erp_callkit")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "showIncomingCall" -> {
                val args = (call.arguments as? Map<*, *>) ?: emptyMap<String, Any?>()
                IncomingCallNotifier.show(appContext, args)
                result.success(null)
            }
            "dismiss" -> {
                val args = call.arguments as? Map<*, *>
                // Prefer callId (the dismiss key); fall back to callCid.
                val key = args?.get("callId")?.toString()?.takeIf { it.isNotEmpty() }
                    ?: args?.get("callCid")?.toString() ?: ""
                IncomingCallNotifier.dismiss(appContext, key)
                result.success(null)
            }
            "dismissAll" -> {
                IncomingCallNotifier.dismissAllCallNotifications(appContext)
                result.success(null)
            }
            "consumeLaunchAction" -> {
                result.success(LaunchActionStore.consume())
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // ── ActivityAware (main engine only) ────────────────────────────
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        captureIntent(binding.activity.intent)
        binding.addOnNewIntentListener { intent ->
            captureIntent(intent)
            false // don't consume — let other handlers see it too
        }
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding = null
    }

    override fun onDetachedFromActivity() {
        activityBinding = null
    }

    private fun captureIntent(intent: Intent?) {
        val data = intent?.getBundleExtra(IncomingCallNotifier.EXTRA_CALL_DATA) ?: return
        LaunchActionStore.put(data)
    }
}
