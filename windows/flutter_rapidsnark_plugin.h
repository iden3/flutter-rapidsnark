#ifndef FLUTTER_PLUGIN_FLUTTER_RAPIDSNARK_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_RAPIDSNARK_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace flutter_rapidsnark {

class FlutterRapidsnarkPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlutterRapidsnarkPlugin();

  virtual ~FlutterRapidsnarkPlugin();

  // Disallow copy and assign.
  FlutterRapidsnarkPlugin(const FlutterRapidsnarkPlugin&) = delete;
  FlutterRapidsnarkPlugin& operator=(const FlutterRapidsnarkPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace flutter_rapidsnark

#endif  // FLUTTER_PLUGIN_FLUTTER_RAPIDSNARK_PLUGIN_H_
