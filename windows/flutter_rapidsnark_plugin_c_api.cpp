#include "include/flutter_rapidsnark/flutter_rapidsnark_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_rapidsnark_plugin.h"

void FlutterRapidsnarkPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_rapidsnark::FlutterRapidsnarkPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
