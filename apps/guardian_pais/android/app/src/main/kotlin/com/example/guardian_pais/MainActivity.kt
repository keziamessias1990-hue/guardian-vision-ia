package com.example.guardian_pais

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "guardian/parent_session")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "load" -> result.success(ParentSessionStorage.read(this))
                        "save" -> {
                            ParentSessionStorage.save(this, requireNotNull(call.argument<String>("token")))
                            result.success(null)
                        }
                        "clear" -> {
                            ParentSessionStorage.clear(this)
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (_: Exception) {
                    result.error("parent_session_storage", "Falha ao acessar a sessão no Android.", null)
                }
            }
    }
}
