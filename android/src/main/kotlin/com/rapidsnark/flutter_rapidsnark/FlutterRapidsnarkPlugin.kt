package com.rapidsnark.flutter_rapidsnark

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import io.iden3.rapidsnark.*

/** FlutterRapidsnarkPlugin */
class FlutterRapidsnarkPlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_rapidsnark")
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
    }

    private fun callGroth16Prove(call: MethodCall, result: Result) {
        try {
            val arguments: Map<String, Any> = call.arguments<Map<String, Any>>()!!

            val zkeyPath = arguments["zkeyPath"] as String
            val witnessBytes = arguments["witness"] as ByteArray

            val proofBufferSize = arguments["proofBufferSize"] as Int
            val publicBufferSize = arguments["publicBufferSize"] as Int
            val errorBufferSize = arguments["errorBufferSize"] as Int

            val proof = groth16Prove(
                zkeyPath,
                witnessBytes,
                proofBufferSize,
                publicBufferSize,
                errorBufferSize,
            )

            result.success(
                mapOf(
                    "proof" to proof.proof,
                    "publicSignals" to proof.publicSignals
                )
            )
        } catch (e: Exception) {
            result.error("groth16ProveWithZKeyFilePath", e.message, null)
        }
    }

    private fun callGroth16PublicBufferSize(call: MethodCall, result: Result) {
        try {
            val arguments: Map<String, Any> = call.arguments<Map<String, Any>>()!!

            val zkeyPath = arguments["zkeyPath"] as String

            val errorBufferSize = arguments["errorBufferSize"] as Int

            val publicSize = groth16PublicBufferSize(
                zkeyPath,
                errorBufferSize,
            )

            result.success(publicSize)
        } catch (e: Exception) {
            result.error("groth16PublicSizeForZkeyFile", e.message, null)
        }
    }

    private fun callGroth16Verify(call: MethodCall, result: Result) {
        try {
            val arguments: Map<String, Any> = call.arguments<Map<String, Any>>()!!

            val proof = arguments["proof"] as String
            val inputs = arguments["inputs"] as String
            val verificationKey = arguments["verificationKey"] as String

            val errorBufferSize = arguments["errorBufferSize"] as Int

            val isValid = groth16Verify(
                proof,
                inputs,
                verificationKey,
                errorBufferSize,
            )

            result.success(isValid)
        } catch (e: Exception) {
            result.error("groth16Verify", e.message, null)
        }
    }
}
