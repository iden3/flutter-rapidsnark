import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_rapidsnark/flutter_rapidsnark.dart';
import 'package:flutter_rapidsnark/flutter_rapidsnark_platform_interface.dart';
import 'package:flutter_rapidsnark/flutter_rapidsnark_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterRapidsnarkPlatform
    with MockPlatformInterfaceMixin
    implements FlutterRapidsnarkPlatform {
  @override
  Future<bool> groth16Verify({
    required String proof,
    required String inputs,
    required String verificationKey,
    int errorBufferSize = 256,
  }) =>
      Future.value(false);

  @override
  Future<ProveResult> groth16Prove({
    required String zkeyPath,
    required Uint8List witness,
    int proofBufferSize = 16384,
    int? publicBufferSize,
    int errorBufferSize = 16384,
  }) {
    // TODO: implement groth16Prove
    throw UnimplementedError();
  }

  @override
  Future<int> groth16PublicBufferSize({
    required String zkeyPath,
    int errorBufferSize = 256,
  }) {
    // TODO: implement groth16PublicBufferSize
    throw UnimplementedError();
  }
}

void main() {
  final FlutterRapidsnarkPlatform initialPlatform =
      FlutterRapidsnarkPlatform.instance;

  test('$MethodChannelFlutterRapidsnark is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterRapidsnark>());
  });

  test('getPlatformVersion', () async {
    Rapidsnark flutterRapidsnarkPlugin = Rapidsnark();
    MockFlutterRapidsnarkPlatform fakePlatform =
        MockFlutterRapidsnarkPlatform();
    FlutterRapidsnarkPlatform.instance = fakePlatform;

    expect(
      await flutterRapidsnarkPlugin.groth16Verify(
        proof: '',
        inputs: '',
        verificationKey: '',
      ),
      false,
    );
  });
}
