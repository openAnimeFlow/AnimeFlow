import Cocoa
import FlutterMacOS

/// Keep scoped URLs alive while the downloader and native player use File paths.
final class DownloadDirectoryHandler: NSObject {
  private static let bookmarksKey = "anime_flow.downloadDirectoryBookmarks"
  private let channel: FlutterMethodChannel
  private weak var window: NSWindow?
  private var selectedURL: URL?
  private var selecting = false
  private var activeRoots: [String: URL] = [:]

  private var bookmarks: [String: Data] {
    get { UserDefaults.standard.dictionary(forKey: Self.bookmarksKey) as? [String: Data] ?? [:] }
    set { UserDefaults.standard.set(newValue, forKey: Self.bookmarksKey) }
  }

  init(messenger: FlutterBinaryMessenger, window: NSWindow) {
    channel = FlutterMethodChannel(name: "anime_flow/download_directory", binaryMessenger: messenger)
    self.window = window
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "window_closed", message: "Download window closed", details: nil))
        return
      }
      self.handle(call, result: result)
    }
    NotificationCenter.default.addObserver(
      self, selector: #selector(releaseAccess),
      name: NSApplication.willTerminateNotification, object: nil
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
    releaseAccess()
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any]
    switch call.method {
    case "selectDirectory":
      selectDirectory(title: arguments?["title"] as? String, result: result)
    case "persistAccess":
      guard let path = arguments?["path"] as? String,
            let url = selectedURL, url.standardizedFileURL.path == path else {
        result(FlutterError(code: "invalid_selection", message: "Select the download folder again", details: nil))
        return
      }
      do {
        let data = try url.bookmarkData(options: .withSecurityScope,
                                        includingResourceValuesForKeys: nil, relativeTo: nil)
        // Test restoration before committing either the bookmark or the setting.
        let scopedURL = try resolve(data)
        if activeRoots[path] == nil {
          guard scopedURL.startAccessingSecurityScopedResource() else {
            result(FlutterError(code: "access_denied", message: "Cannot retain folder access", details: nil))
            return
          }
          activeRoots[path] = scopedURL
        }
        var saved = bookmarks
        saved[path] = data
        bookmarks = saved
        selectedURL = nil
        result(nil)
      } catch {
        result(FlutterError(code: "bookmark_failed", message: error.localizedDescription, details: nil))
      }
    case "restoreBookmarks":
      var restored: [String: String] = [:]
      for root in bookmarks.keys {
        // One invalid grant must not prevent playback under other roots.
        if let url = restoreRoot(root) {
          restored[root] = url.standardizedFileURL.path
        }
      }
      result(restored)
    case "restoreAccess":
      guard let path = arguments?["path"] as? String, (path as NSString).isAbsolutePath else {
        result(nil)
        return
      }
      let requested = URL(fileURLWithPath: path).standardizedFileURL
      // Prefer the most specific grant and match path components, not prefixes.
      for root in bookmarks.keys.sorted(by: { $0.count > $1.count }) {
        let original = URL(fileURLWithPath: root).standardizedFileURL
        if contains(original, requested) {
          guard let resolved = restoreRoot(root) else {
            result(nil)
            return
          }
          let suffix = requested.pathComponents.dropFirst(original.pathComponents.count)
          result(suffix.reduce(resolved) { $0.appendingPathComponent($1) }.standardizedFileURL.path)
          return
        }
        if let resolved = activeRoots[root], contains(resolved.standardizedFileURL, requested) {
          result(requested.path)
          return
        }
      }
      // App-owned storage and Downloads already have access through entitlements.
      // Legacy paths without a bookmark can also be reselected in settings.
      var ancestor = requested
      while !FileManager.default.fileExists(atPath: ancestor.path), ancestor.path != "/" {
        ancestor.deleteLastPathComponent()
      }
      result(FileManager.default.isWritableFile(atPath: ancestor.path) ? requested.path : nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func selectDirectory(title: String?, result: @escaping FlutterResult) {
    guard !selecting, let window = window else {
      result(FlutterError(code: "picker_unavailable", message: "Directory picker unavailable", details: nil))
      return
    }
    selecting = true
    selectedURL = nil
    let panel = NSOpenPanel()
    panel.title = title ?? ""
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    panel.canCreateDirectories = true
    panel.beginSheetModal(for: window) { [weak self] response in
      guard let self = self else {
        result(nil)
        return
      }
      self.selecting = false
      guard response == .OK, let url = panel.url else {
        result(nil)
        return
      }
      self.selectedURL = url
      result(url.standardizedFileURL.path)
    }
  }

  private func resolve(_ data: Data) throws -> URL {
    var stale = false
    return try URL(resolvingBookmarkData: data, options: [.withSecurityScope, .withoutUI],
                   relativeTo: nil, bookmarkDataIsStale: &stale)
  }

  private func restoreRoot(_ root: String) -> URL? {
    if let url = activeRoots[root] { return url }
    guard let data = bookmarks[root] else { return nil }
    do {
      var stale = false
      let url = try URL(resolvingBookmarkData: data, options: [.withSecurityScope, .withoutUI],
                        relativeTo: nil, bookmarkDataIsStale: &stale)
      guard url.startAccessingSecurityScopedResource() else { return nil }
      activeRoots[root] = url
      if stale {
        // Keep the original key so paths from earlier sessions remain resolvable.
        if let refreshed = try? url.bookmarkData(options: .withSecurityScope,
                                                includingResourceValuesForKeys: nil, relativeTo: nil) {
          var saved = bookmarks
          saved[root] = refreshed
          bookmarks = saved
        }
      }
      return url
    } catch {
      return nil
    }
  }

  private func contains(_ root: URL, _ child: URL) -> Bool {
    child.pathComponents.starts(with: root.pathComponents)
  }

  @objc private func releaseAccess() {
    for url in activeRoots.values { url.stopAccessingSecurityScopedResource() }
    activeRoots.removeAll()
  }
}
