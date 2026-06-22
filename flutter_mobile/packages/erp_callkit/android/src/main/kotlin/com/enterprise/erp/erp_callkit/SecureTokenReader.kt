package com.enterprise.erp.erp_callkit

import android.content.Context
import android.content.SharedPreferences
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Log
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import org.json.JSONObject

/**
 * Reads (and refreshes) the auth tokens that the Flutter app persisted
 * via `flutter_secure_storage` — WITHOUT copying them anywhere less
 * secure. We open the exact same `EncryptedSharedPreferences` file the
 * plugin writes, using the same master key, so the bytes never leave
 * the Android Keystore-backed store.
 *
 * Format pinned to `flutter_secure_storage` 9.2.x with
 * `AndroidOptions(encryptedSharedPreferences: true)`:
 *   - prefs file:  "FlutterSecureStorage"
 *   - master key:  MasterKey.DEFAULT_MASTER_KEY_ALIAS (AES256-GCM)
 *   - schemes:     AES256_SIV (keys) / AES256_GCM (values)
 *   - stored key:  <ELEMENT_PREFERENCES_KEY_PREFIX> + "_" + "auth.tokens.v1"
 *   - value JSON:  { accessToken, refreshToken, accessExpiresAt? }
 */
object SecureTokenReader {
    private const val TAG = "ErpSecureToken"
    private const val PREFS_NAME = "FlutterSecureStorage"

    // flutter_secure_storage's fixed key prefix (base64-ish marker) +
    // the app's TokenStorage key "auth.tokens.v1".
    private const val KEY_PREFIX = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIHNlY3VyZSBzdG9yYWdlCg"
    private const val STORED_KEY = KEY_PREFIX + "_" + "auth.tokens.v1"

    data class Tokens(val access: String, val refresh: String)

    private fun prefs(context: Context): SharedPreferences {
        // Re-create the SAME master key (by alias) flutter_secure_storage
        // made. If it already exists in the keystore, the Builder just
        // retrieves it — the spec only matters at first creation.
        val spec = KeyGenParameterSpec.Builder(
            MasterKey.DEFAULT_MASTER_KEY_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setKeySize(256)
            .build()
        val masterKey = MasterKey.Builder(context)
            .setKeyGenParameterSpec(spec)
            .build()
        return EncryptedSharedPreferences.create(
            context,
            PREFS_NAME,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
    }

    fun read(context: Context): Tokens? {
        return try {
            val raw = prefs(context).getString(STORED_KEY, null)
            if (raw.isNullOrEmpty()) {
                Log.w(TAG, "no token blob at $STORED_KEY")
                return null
            }
            val json = JSONObject(raw)
            val a = json.optString("accessToken", "")
            val r = json.optString("refreshToken", "")
            if (a.isEmpty() || r.isEmpty()) null else Tokens(a, r)
        } catch (e: Exception) {
            Log.e(TAG, "read failed: ${e.message}", e)
            null
        }
    }

    /** Persist refreshed tokens back so the app stays in sync. */
    fun writeRefreshed(context: Context, access: String, refresh: String, expiresAt: String?) {
        try {
            val obj = JSONObject()
                .put("accessToken", access)
                .put("refreshToken", refresh)
            if (!expiresAt.isNullOrEmpty()) obj.put("accessExpiresAt", expiresAt)
            // commit (sync) — we're on a short-lived background thread and
            // want the write durable before the process may be reaped.
            prefs(context).edit().putString(STORED_KEY, obj.toString()).commit()
            Log.i(TAG, "refreshed tokens written back to secure storage")
        } catch (e: Exception) {
            Log.e(TAG, "writeRefreshed failed: ${e.message}", e)
        }
    }
}
