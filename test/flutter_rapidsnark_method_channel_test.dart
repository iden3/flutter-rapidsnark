import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_rapidsnark/flutter_rapidsnark_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelFlutterRapidsnark platform = MethodChannelFlutterRapidsnark();
  const MethodChannel channel = MethodChannel('com.rapidsnark.flutter_rapidsnark');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'groth16Verify') {
          return false;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('groth16Verify', () async {
    expect(
      await platform.groth16Verify(proof: '', inputs: '', verificationKey: ''),
      false,
    );
  });
}
