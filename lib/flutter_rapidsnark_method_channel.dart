import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_rapidsnark_platform_interface.dart';

const _defaultProofBufferSize = 1024;
const _defaultErrorBufferSize = 256;

/// An implementation of [FlutterRapidsnarkPlatform] that uses method channels.
class MethodChannelFlutterRapidsnark extends FlutterRapidsnarkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_rapidsnark');

  @override
  Future<({String proof, String publicSignals})> groth16Prove({
    required Uint8List zkey,
    required Uint8List witness,
    int proofBufferSize = _defaultProofBufferSize,
    int? publicBufferSize,
    int errorBufferSize = _defaultErrorBufferSize,
  }) async {
    final actualPublicBufferSize = publicBufferSize ??
        await groth16PublicSizeForZkeyBuf(
            zkey: zkey, errorBufferSize: errorBufferSize);

    final result = (await methodChannel.invokeMapMethod<String, dynamic>(
      'groth16Prove',
      {
        "zkey": zkey,
        "witness": witness,
        "proofBufferSize": proofBufferSize,
        "publicBufferSize": actualPublicBufferSize,
        "errorBufferSize": errorBufferSize,
      },
    ))!;

    return (
      proof: result['proof'] as String,
      publicSignals: result['publicSignals'] as String,
    );
  }

  @override
  Future<({String proof, String publicSignals})> groth16ProveWithZKeyFilePath({
    required String zkeyPath,
    required Uint8List witness,
    int proofBufferSize = _defaultProofBufferSize,
    int? publicBufferSize,
    int errorBufferSize = _defaultErrorBufferSize,
  }) async {
    final actualPublicBufferSize = publicBufferSize ??
        await groth16PublicSizeForZkeyFile(
            zkeyPath: zkeyPath, errorBufferSize: errorBufferSize);

    final result = (await methodChannel.invokeMapMethod<String, dynamic>(
      'groth16ProveWithZKeyFilePath',
      {
        "zkeyPath": zkeyPath,
        "witness": witness,
        "proofBufferSize": proofBufferSize,
        "publicBufferSize": actualPublicBufferSize,
        "errorBufferSize": errorBufferSize,
      },
    ))!;

    return (
      proof: result['proof'] as String,
      publicSignals: result['publicSignals'] as String,
    );
  }

  @override
  Future<int> groth16PublicSizeForZkeyBuf({
    required Uint8List zkey,
    int errorBufferSize = _defaultErrorBufferSize,
  }) async {
    final result = await methodChannel.invokeMethod<int>(
      'groth16PublicSizeForZkeyBuf',
      {
        "zkey": zkey,
        "errorBufferSize": errorBufferSize,
      },
    );

    return result!;
  }

  @override
  Future<int> groth16PublicSizeForZkeyFile({
    required String zkeyPath,
    int errorBufferSize = _defaultErrorBufferSize,
  }) async {
    final result = await methodChannel.invokeMethod<int>(
      'groth16PublicSizeForZkeyFile',
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
