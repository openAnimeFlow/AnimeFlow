import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var lastRxBytes: UInt64? = nil
  private var lastTxBytes: UInt64? = nil
  private var lastTime: TimeInterval? = nil

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as? FlutterViewController
    let channel = FlutterMethodChannel(
      name: "network_speed_monitor",
      binaryMessenger: controller!.engine.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "UNAVAILABLE", message: "AppDelegate destroyed", details: nil))
        return
      }
      switch call.method {
      case "start":
        self.reset()
        let now = ProcessInfo.processInfo.systemUptime
        let (rx, tx) = self.readBytes()
        self.lastTime = now
        self.lastRxBytes = rx
        self.lastTxBytes = tx
        result(nil)
      case "stop":
        self.reset()
        result(nil)
      case "get":
        let (rxNow, txNow) = self.readBytes()
        let now = ProcessInfo.processInfo.systemUptime

        if self.lastTime == nil || self.lastRxBytes == nil || self.lastTxBytes == nil {
          self.lastTime = now
          self.lastRxBytes = rxNow
          self.lastTxBytes = txNow
          result(["download": Int64(0), "upload": Int64(0)])
          return
        }

        let dt = now - self.lastTime!
        if dt <= 0 {
          result(["download": Int64(0), "upload": Int64(0)])
          return
        }

        let rxDelta = rxNow >= self.lastRxBytes! ? rxNow - self.lastRxBytes! : 0
        let txDelta = txNow >= self.lastTxBytes! ? txNow - self.lastTxBytes! : 0

        let downBps = Int64(Double(rxDelta) / dt)
        let upBps = Int64(Double(txDelta) / dt)

        self.lastTime = now
        self.lastRxBytes = rxNow
        self.lastTxBytes = txNow

        result(["download": downBps, "upload": upBps])
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func reset() {
    lastRxBytes = nil
    lastTxBytes = nil
    lastTime = nil
  }

  private func readBytes() -> (UInt64, UInt64) {
    var totalRx: UInt64 = 0
    var totalTx: UInt64 = 0
    var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddrPtr) == 0 else { return (0, 0) }
    guard let firstAddr = ifaddrPtr else { return (0, 0) }

    for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
      let addr = ptr.pointee
      let name = String(cString: addr.ifa_name)
      // Skip loopback
      if name == "lo" || name.hasPrefix("lo") { continue }
      guard let data = addr.ifa_data else { continue }
      // ifa_data points to if_data{} on Darwin
      let networkData = data.assumingMemoryBound(to: if_data.self)
      totalRx += UInt64(networkData.pointee.ifi_ibytes)
      totalTx += UInt64(networkData.pointee.ifi_obytes)
    }
    freeifaddrs(ifaddrPtr)
    return (totalRx, totalTx)
  }
}