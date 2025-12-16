package com.rapidsnark.flutter_rapidsnark

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.StandardMethodCodec
import io.iden3.rapidsnark.*
import java.util.concurrent.Executors
import android.os.Handler
import android.os.Looper

/** FlutterRapidsnarkPlugin */
class FlutterRapidsnarkPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel

    // Executor to allow multiple proving / verifying operations to run concurrently
    private val executor = Executors.newCachedThreadPool()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        val taskQueue = flutterPluginBinding.binaryMessenger.makeBackgroundTaskQueue()
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "com.rapidsnark.flutter_rapidsnark",
            StandardMethodCodec.INSTANCE,
            taskQueue
        )
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "groth16Prove" -> callGroth16Prove(call, result)
            "groth16PublicBufferSize" -> callGroth16PublicBufferSize(call, result)
            "groth16Verify" -> callGroth16Verify(call, result)
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        executor.shutdown()
    }

    // Helper to finish results safely on main thread
    private fun complete(result: Result, block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            block()
        } else {
            mainHandler.post { block() }
        }
    }

    private fun callGroth16Prove(call: MethodCall, result: Result) {
        try {
            val arguments: Map<String, Any> = call.arguments<Map<String, Any>>()!!

            val zkeyPath = arguments["zkeyPath"] as String
            val witnessBytes = arguments["witness"] as ByteArray

            val proofBufferSize = arguments["proofBufferSize"] as Int
            val publicBufferSize = arguments["publicBufferSize"] as Int?
            val errorBufferSize = arguments["errorBufferSize"] as Int

            // Dispatch heavy native call asynchronously to allow concurrency
            executor.execute {
                try {
                    val proof = groth16Prove(
                        zkeyPath,
                        witnessBytes,
                        proofBufferSize,
                        publicBufferSize,
                        errorBufferSize,
                    )
                    complete(result) {
                        result.success(
                            mapOf(
                                "proof" to proof.proof,
                                "publicSignals" to proof.publicSignals
                            )
                        )
                    }
                } catch (e: RapidsnarkProverError) {
                    complete(result) { result.error("groth16Prove", e.message, null) }
                } catch (e: Exception) {
                    complete(result) { result.error("groth16Prove", e.message, null) }
                }
            }
        } catch (e: Exception) {
            result.error("groth16Prove", "Failed to prove: ${e.message}", null)
            return
        }
    }

    private fun callGroth16PublicBufferSize(call: MethodCall, result: Result) {
        try {
            val arguments: Map<String, Any> = call.arguments<Map<String, Any>>()!!

            val zkeyPath = arguments["zkeyPath"] as String
            val errorBufferSize = arguments["errorBufferSize"] as Int

            executor.execute {
                try {
                    val publicSize = groth16PublicBufferSize(
                        zkeyPath,
                        errorBufferSize,
                    )
                    complete(result) { result.success(publicSize) }
                } catch (e: RapidsnarkProverError) {
                    complete(result) { result.error("groth16PublicBufferSize", e.message, null) }
                } catch (e: Exception) {
                    complete(result) { result.error("groth16PublicBufferSize", e.message, null) }
                }
            }
        } catch (e: Exception) {
            result.error(
                "groth16PublicBufferSize",
                "Failed to calculate public buffer size: ${e.message}",
                null
            )
            return
        }
    }

    private fun callGroth16Verify(call: MethodCall, result: Result) {
        try {
            val arguments: Map<String, Any> = call.arguments<Map<String, Any>>()!!

            val proof = arguments["proof"] as String
            val inputs = arguments["inputs"] as String
            val verificationKey = arguments["verificationKey"] as String

            val errorBufferSize = arguments["errorBufferSize"] as Int

            executor.execute {
                try {
                    val isValid = groth16Verify(
                        proof,
                        inputs,
                        verificationKey,
                        errorBufferSize,
                    )
                    complete(result) { result.success(isValid) }
                } catch (e: RapidsnarkVerifierError) {
                    complete(result) { result.error("groth16Verify", e.message, null) }
                } catch (e: Exception) {
                    complete(result) { result.error("groth16Verify", e.message, null) }
                }
            }
        } catch (e: Exception) {
            result.error("groth16Verify", "Invalid arguments type: ${e.message}", null)
            return
        }
    }
}
