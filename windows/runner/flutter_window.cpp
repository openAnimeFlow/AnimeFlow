#include "flutter_window.h"

#include <optional>
#include <chrono>
#include <cstdlib>
#include <utility>

#include "flutter/generated_plugin_registrant.h"

#include <iphlpapi.h>

namespace {
double NowSeconds() {
  using clock = std::chrono::steady_clock;
  auto now = clock::now().time_since_epoch();
  return std::chrono::duration_cast<std::chrono::duration<double>>(now).count();
}
}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  // Native MethodChannel: network_speed_monitor
  network_speed_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "network_speed_monitor",
      &flutter::StandardMethodCodec::GetInstance());

  network_speed_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "start") {
          ResetNetworkSpeedState();
          auto bytes = GetCurrentRxTxBytes();
          last_rx_bytes_ = bytes.first;
          last_tx_bytes_ = bytes.second;
          last_time_sec_ = NowSeconds();
          result->Success();
          return;
        }
        if (call.method_name() == "stop") {
          ResetNetworkSpeedState();
          result->Success();
          return;
        }
        if (call.method_name() == "get") {
          auto bytesNow = GetCurrentRxTxBytes();
          const auto nowSec = NowSeconds();

          if (!last_time_sec_.has_value() || !last_rx_bytes_.has_value() ||
              !last_tx_bytes_.has_value() || nowSec <= last_time_sec_.value()) {
            last_time_sec_ = nowSec;
            last_rx_bytes_ = bytesNow.first;
            last_tx_bytes_ = bytesNow.second;
            result->Success(flutter::EncodableValue(flutter::EncodableMap{
                {flutter::EncodableValue("download"), flutter::EncodableValue(int64_t(0))},
                {flutter::EncodableValue("upload"), flutter::EncodableValue(int64_t(0))},
            }));
            return;
          }

          const double dt = nowSec - last_time_sec_.value();
          const uint64_t rxDelta = (bytesNow.first >= last_rx_bytes_.value())
                                        ? (bytesNow.first - last_rx_bytes_.value())
                                        : 0;
          const uint64_t txDelta = (bytesNow.second >= last_tx_bytes_.value())
                                        ? (bytesNow.second - last_tx_bytes_.value())
                                        : 0;

          const auto downBps = static_cast<int64_t>(rxDelta / dt);
          const auto upBps = static_cast<int64_t>(txDelta / dt);

          // Update baselines
          last_time_sec_ = nowSec;
          last_rx_bytes_ = bytesNow.first;
          last_tx_bytes_ = bytesNow.second;

          flutter::EncodableMap data{
              {flutter::EncodableValue("download"), flutter::EncodableValue(downBps)},
              {flutter::EncodableValue("upload"), flutter::EncodableValue(upBps)},
          };
          result->Success(flutter::EncodableValue(std::move(data)));
          return;
        }

        result->NotImplemented();
      });

  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

void FlutterWindow::ResetNetworkSpeedState() {
  last_rx_bytes_ = std::nullopt;
  last_tx_bytes_ = std::nullopt;
  last_time_sec_ = std::nullopt;
}

std::pair<uint64_t, uint64_t> FlutterWindow::GetCurrentRxTxBytes() {
  uint64_t rx = 0;
  uint64_t tx = 0;

  // Use GetIfTable to retrieve per-interface octet counters.
  DWORD size = 0;
  if (GetIfTable(nullptr, &size, FALSE) != ERROR_INSUFFICIENT_BUFFER) {
    return {0, 0};
  }

  auto table = reinterpret_cast<PMIB_IFTABLE>(std::malloc(size));
  if (!table) {
    return {0, 0};
  }
  auto ret = GetIfTable(table, &size, FALSE);
  if (ret != NO_ERROR) {
    std::free(table);
    return {0, 0};
  }

  for (DWORD i = 0; i < table->dwNumEntries; i++) {
    rx += static_cast<uint64_t>(table->table[i].dwInOctets);
    tx += static_cast<uint64_t>(table->table[i].dwOutOctets);
  }

  std::free(table);
  return {rx, tx};
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
