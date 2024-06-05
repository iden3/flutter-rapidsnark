import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_rapidsnark_method_channel.dart';

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

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
