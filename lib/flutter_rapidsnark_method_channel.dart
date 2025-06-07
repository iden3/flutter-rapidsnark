import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_rapidsnark_platform_interface.dart';
import 'model.dart';

const _defaultProofBufferSize = 1024;
const _defaultErrorBufferSize = 256;

/// An implementation of [FlutterRapidsnarkPlatform] that uses method channels.
class MethodChannelFlutterRapidsnark extends FlutterRapidsnarkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('com.rapidsnark.flutter_rapidsnark');

  @override
  Future<ProveResult> groth16Prove({
    required String zkeyPath,
    required Uint8List witness,
    int proofBufferSize = _defaultProofBufferSize,
    int? publicBufferSize,
    int errorBufferSize = _defaultErrorBufferSize,
  }) async {
    final result = (await methodChannel.invokeMapMethod<String, dynamic>(
      'groth16Prove',
      {
        "zkeyPath": zkeyPath,
        "witness": witness,
        "proofBufferSize": proofBufferSize,
        "publicBufferSize": publicBufferSize,
        "errorBufferSize": errorBufferSize,
      },
    ))!;

    return ProveResult(
      proof: result['proof'] as String,
      publicSignals: result['publicSignals'] as String,
    );
  }

  @override
  Future<int> groth16PublicBufferSize({
    required String zkeyPath,
    int errorBufferSize = _defaultErrorBufferSize,
  }) async {
    final result = await methodChannel.invokeMethod<int>(
      'groth16PublicBufferSize',
      {
        "zkeyPath": zkeyPath,
        "errorBufferSize": errorBufferSize,
      },
    );

    return result!;
  }

  @override
  Future<bool> groth16Verify({
    required String proof,
    required String inputs,
    required String verificationKey,
    int errorBufferSize = _defaultErrorBufferSize,
  }) async {
    final result = await methodChannel.invokeMethod<bool>(
      'groth16Verify',
      {
        "proof": proof,
        "inputs": inputs,
        "verificationKey": verificationKey,
        "errorBufferSize": errorBufferSize,
      },
    );

    return result!;
  }
}
