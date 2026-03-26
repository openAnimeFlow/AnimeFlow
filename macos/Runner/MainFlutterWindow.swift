import Cocoa
import FlutterMacOS
import Darwin

class MainFlutterWindow: NSWindow {
  private let channelName = "network_speed_monitor"
  private var methodChannel: FlutterMethodChannel?

  private var lastRxBytes: UInt64?
  private var lastTxBytes: UInt64?
  private var lastTime: CFTimeInterval?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Register native MethodChannel (start/get/stop).
    let registrar = flutterViewController.registrar(forPlugin: "network_speed_monitor")
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger
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

    super.awakeFromNib()
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
      if name != "lo0",
         (p.ifa_flags & UInt32(IFF_UP)) != 0,
         let data = p.ifa_data {
        let ifData = data.assumingMemoryBound(to: if_data.self).pointee
        rx += UInt64(ifData.ifi_ibytes)
        tx += UInt64(ifData.ifi_obytes)
      }
      ptr = p.ifa_next
    }
    return (rx, tx)
  }
}
