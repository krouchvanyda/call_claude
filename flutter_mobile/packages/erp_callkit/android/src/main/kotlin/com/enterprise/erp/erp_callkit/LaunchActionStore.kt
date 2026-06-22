package com.enterprise.erp.erp_callkit

import android.os.Bundle

/**
 * Process-wide hand-off slot for a call notification tap.
 *
 * MainActivity is launched (from a killed/background state) by the
 * notification's body or Accept PendingIntent with the call data as a
 * Bundle extra. The plugin's ActivityAware hooks stash it here; the
 * Dart side drains it via `consumeLaunchAction` once the engine is up.
 *
 * Static so it is shared across both the main and background Flutter
 * isolates (same Android process, same JVM).
 */
object LaunchActionStore {
    private var pending: Bundle? = null

    @Synchronized
    fun put(data: Bundle) {
        pending = data
    }

    @Synchronized
    fun consume(): Map<String, Any?>? {
        val d = pending ?: return null
        pending = null
        val map = HashMap<String, Any?>()
        for (key in d.keySet()) {
            @Suppress("DEPRECATION")
            map[key] = d.get(key)
        }
        return map
    }
}
