import Flutter
import UIKit
import Darwin

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterPluginRegistrant {
  private let channelName = "network_speed_monitor"
  private var methodChannel: FlutterMethodChannel?

  private var lastRxBytes: UInt64?
  private var lastTxBytes: UInt64?
  private var lastTime: CFTimeInterval?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    pluginRegistrant = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func register(with registry: FlutterPluginRegistry) {
    // 注册原生插件
    GeneratedPluginRegistrant.register(with: registry)

    guard let registrar = registry.registrar(forPlugin: "network_speed_monitor") else {
      return
    }

    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    methodChannel = channel

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      switch call.method {
      case "start":
        self.reset()
        let now = CACurrentMediaTime()
        let bytes = self.currentRxTxBytes()
        self.lastTime = now
        self.lastRxBytes = bytes.rx
        self.lastTxBytes = bytes.tx
        result(nil)
      case "stop":
        self.reset()
        result(nil)
      case "get":
        let now = CACurrentMediaTime()
        let bytesNow = self.currentRxTxBytes()

        guard
          let lastTime = self.lastTime,
          let lastRx = self.lastRxBytes,
          let lastTx = self.lastTxBytes,
          now > lastTime
        else {
          self.lastTime = now
          self.lastRxBytes = bytesNow.rx
          self.lastTxBytes = bytesNow.tx
          result(["download": 0, "upload": 0])
          return
        }

        let dt = now - lastTime
        let rxDelta: UInt64 = (bytesNow.rx >= lastRx) ? (bytesNow.rx - lastRx) : 0
        let txDelta: UInt64 = (bytesNow.tx >= lastTx) ? (bytesNow.tx - lastTx) : 0

        let downBps = Double(rxDelta) / dt
        let upBps = Double(txDelta) / dt

        self.lastTime = now
        self.lastRxBytes = bytesNow.rx
        self.lastTxBytes = bytesNow.tx

        result([
          "download": Int64(downBps),
          "upload": Int64(upBps)
        ])
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func reset() {
    lastRxBytes = nil
    lastTxBytes = nil
    lastTime = nil
  }

  private func currentRxTxBytes() -> (rx: UInt64, tx: UInt64) {
    var rx: UInt64 = 0
    var tx: UInt64 = 0

    var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
    if getifaddrs(&ifaddr) != 0 {
      return (0, 0)
    }
    defer { freeifaddrs(ifaddr) }

    var ptr = ifaddr
    while let p = ptr?.pointee {
      let name = String(cString: p.ifa_name)

      // iOS 上 ifa_data 的网络统计只在 AF_LINK 下有效。
      // 仅统计活跃且非回环接口，避免拿到 0 或无效计数。
      let isUp = (p.ifa_flags & UInt32(IFF_UP)) != 0
      let isLoopback = (p.ifa_flags & UInt32(IFF_LOOPBACK)) != 0
      let family = p.ifa_addr?.pointee.sa_family
      let isRelevantInterface = name.hasPrefix("en") || name.hasPrefix("pdp_ip")

      if isUp,
         !isLoopback,
         family == UInt8(AF_LINK),
         isRelevantInterface,
         let data = p.ifa_data {
        let ifData = data.assumingMemoryBound(to: if_data64.self).pointee
        rx += ifData.ifi_ibytes
        tx += ifData.ifi_obytes
      }
      ptr = p.ifa_next
    }

    return (rx, tx)
  }
}
