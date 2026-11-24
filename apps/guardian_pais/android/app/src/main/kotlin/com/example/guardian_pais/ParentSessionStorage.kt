package com.example.guardian_pais

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.AtomicFile
import java.io.File
import java.io.FileNotFoundException
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

internal object ParentSessionStorage {
    private const val alias = "guardian_parent_session_v1"
    private const val nonceSize = 12
    private const val version: Byte = 1

    private fun file(context: Context) =
        AtomicFile(File(context.noBackupFilesDir, "guardian-parent-session"))

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

    fun read(context: Context): String? {
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
        return String(cipher.doFinal(bytes, 1 + nonceSize, bytes.size - 1 - nonceSize), Charsets.UTF_8)
    }

    fun save(context: Context, token: String) {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, checkNotNull(key(create = true)))
        check(cipher.iv.size == nonceSize)
        val bytes = byteArrayOf(version) + cipher.iv + cipher.doFinal(token.toByteArray(Charsets.UTF_8))
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

    fun clear(context: Context) = file(context).delete()
}
