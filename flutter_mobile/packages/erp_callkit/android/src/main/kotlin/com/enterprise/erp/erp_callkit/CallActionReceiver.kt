package com.enterprise.erp.erp_callkit

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Receives the **Reject** tap from [IncomingCallNotifier]'s notification.
 *
 * This is the whole point of the package: the Reject `PendingIntent`
 * targets THIS class explicitly, so Android delivers it even when the
 * app process is dead. We then reject the call over plain HTTP from a
 * background thread — no Flutter engine, no Dart, the app never opens.
 *
 * The caller (A) gets the `declined` signal through the backend's normal
 * fan-out and ends the call immediately.
 */
class CallActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val appContext = context.applicationContext

        // Ring-timeout backstop (AlarmManager). The caller ended an
        // unanswered call but no cancel signal reached this device, or
        // nobody answered before the ring window elapsed — just clear the
        // stuck heads-up. No network, no app launch.
        if (intent.action == IncomingCallNotifier.ACTION_TIMEOUT) {
            val notifId = intent.getIntExtra(IncomingCallNotifier.EXTRA_NOTIF_ID, -1)
            Log.i(TAG, "ring timeout fired — dismissing notifId=$notifId")
            IncomingCallNotifier.dismissById(appContext, notifId)
            return
        }

        if (intent.action != IncomingCallNotifier.ACTION_REJECT) return

        val data = intent.getBundleExtra(IncomingCallNotifier.EXTRA_CALL_DATA)
        val notifId = intent.getIntExtra(IncomingCallNotifier.EXTRA_NOTIF_ID, -1)

        // Stop the ring the instant the user taps, regardless of network.
        IncomingCallNotifier.dismissById(appContext, notifId)

        val callId = data?.getString("callId") ?: ""
        val baseUrl = data?.getString("baseUrl") ?: ""
        Log.i(TAG, "Reject tapped (killed-app path) · callId=$callId baseUrl=$baseUrl")

        if (callId.isEmpty() || baseUrl.isEmpty()) {
            Log.w(TAG, "missing callId/baseUrl — cannot reject")
            return
        }

        // goAsync keeps the receiver (and process) alive past onReceive
        // so the network call on the worker thread can finish.
        val pending = goAsync()
        Thread {
            try {
                val ok = BackendCallClient.rejectCall(appContext, baseUrl, callId, "declined")
                Log.i(TAG, "reject finished · ok=$ok · callId=$callId")
            } catch (e: Exception) {
                Log.e(TAG, "reject threw: ${e.message}", e)
            } finally {
                pending.finish()
            }
        }.start()
    }

    companion object {
        private const val TAG = "ErpCallReject"
    }
}
