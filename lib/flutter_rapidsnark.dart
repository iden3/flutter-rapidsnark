
import 'flutter_rapidsnark_platform_interface.dart';

class FlutterRapidsnark {
  Future<String?> getPlatformVersion() {
    return FlutterRapidsnarkPlatform.instance.getPlatformVersion();
  }
}
