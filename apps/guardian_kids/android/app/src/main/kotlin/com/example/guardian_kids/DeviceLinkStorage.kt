package com.example.guardian_kids

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.AtomicFile
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileNotFoundException
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

internal object DeviceLinkStorage {
    private const val alias = "guardian_device_link_v1"
    private const val nonceSize = 12
    private const val version: Byte = 1

    private fun file(context: Context) =
        AtomicFile(File(context.noBackupFilesDir, "guardian-device-link"))

    private fun key(create: Boolean): SecretKey? {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        val existing = store.getKey(alias, null) as? SecretKey
        if (existing != null || !create) return existing
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(KeyGenParameterSpec.Builder(
            alias,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
        ).setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            .build())
        return generator.generateKey()
    }

    private fun readData(context: Context): JSONObject? {
        val bytes = try {
            file(context).readFully()
        } catch (_: FileNotFoundException) {
            return null
        }
        check(bytes.size > 1 + nonceSize + 16 && bytes[0] == version)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(
            Cipher.DECRYPT_MODE,
            checkNotNull(key(create = false)),
            GCMParameterSpec(128, bytes, 1, nonceSize),
        )
        return JSONObject(String(cipher.doFinal(bytes, 1 + nonceSize, bytes.size - 1 - nonceSize), Charsets.UTF_8))
    }

    fun read(context: Context): Map<String, String>? {
        val data = readData(context) ?: return null
        if (data.has("responsibleName")) save(context, data.getString("childId"), data.getString("deviceToken"))
        return mapOf(
            "childId" to data.getString("childId"),
            "deviceToken" to data.getString("deviceToken"),
        )
    }

    fun approvedSources(context: Context): Set<String>? {
        val sources = readData(context)?.optJSONArray("approvedSources") ?: return null
        return (0 until sources.length()).map(sources::getString).toSet()
    }

    fun save(context: Context, childId: String, token: String, sources: Set<String>? = null) {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, checkNotNull(key(create = true)))
        check(cipher.iv.size == nonceSize)
        val data = JSONObject()
            .put("childId", childId)
            .put("deviceToken", token)
        if (sources != null) data.put("approvedSources", JSONArray(sources.toList()))
        val bytes = byteArrayOf(version) + cipher.iv +
            cipher.doFinal(data.toString().toByteArray(Charsets.UTF_8))
        val target = file(context)
        val output = target.startWrite()
        try {
            output.write(bytes)
            target.finishWrite(output)
        } catch (error: Exception) {
            target.failWrite(output)
            throw error
        }
    }

    fun forgetApproval(context: Context) {
        val data = readData(context) ?: return
        if (data.has("approvedSources")) save(context, data.getString("childId"), data.getString("deviceToken"))
    }

    fun clear(context: Context) = file(context).delete()

    fun clearIfMatches(context: Context, token: String) {
        if (read(context)?.get("deviceToken") == token) file(context).delete()
    }
}
