import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_rapidsnark/flutter_rapidsnark.dart';
import 'package:flutter_rapidsnark/flutter_rapidsnark_platform_interface.dart';
import 'package:flutter_rapidsnark/flutter_rapidsnark_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterRapidsnarkPlatform
    with MockPlatformInterfaceMixin
    implements FlutterRapidsnarkPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterRapidsnarkPlatform initialPlatform = FlutterRapidsnarkPlatform.instance;

  test('$MethodChannelFlutterRapidsnark is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterRapidsnark>());
  });

  test('getPlatformVersion', () async {
    FlutterRapidsnark flutterRapidsnarkPlugin = FlutterRapidsnark();
    MockFlutterRapidsnarkPlatform fakePlatform = MockFlutterRapidsnarkPlatform();
    FlutterRapidsnarkPlatform.instance = fakePlatform;

    expect(await flutterRapidsnarkPlugin.getPlatformVersion(), '42');
  });
}
