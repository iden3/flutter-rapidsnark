import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_rapidsnark_method_channel.dart';
import 'model.dart';

abstract class FlutterRapidsnarkPlatform extends PlatformInterface {
  /// Constructs a FlutterRapidsnarkPlatform.
  FlutterRapidsnarkPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterRapidsnarkPlatform _instance = MethodChannelFlutterRapidsnark();

  /// The default instance of [FlutterRapidsnarkPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterRapidsnark].
  static FlutterRapidsnarkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterRapidsnarkPlatform] when
  /// they register themselves.
  static set instance(FlutterRapidsnarkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<ProveResult> groth16Prove({
    required String zkeyPath,
    required Uint8List witness,
    int proofBufferSize,
    int? publicBufferSize,
    int errorBufferSize,
  });

  Future<bool> groth16Verify({
    required String proof,
    required String inputs,
    required String verificationKey,
    int errorBufferSize,
  });

  Future<int> groth16PublicBufferSize({
    required String zkeyPath,
    int errorBufferSize,
  });
}
