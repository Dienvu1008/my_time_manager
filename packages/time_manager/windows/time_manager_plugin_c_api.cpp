#include "include/time_manager/time_manager_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "time_manager_plugin.h"

void TimeManagerPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  time_manager::TimeManagerPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
