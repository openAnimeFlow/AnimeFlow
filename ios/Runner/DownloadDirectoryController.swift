import Flutter
import Foundation
import UIKit

/// Retains folder grants for this process and persists bookmarks for the next
/// launch. External provider I/O runs on a serial queue through a coordinator.
final class DownloadDirectoryController: NSObject, UIDocumentPickerDelegate,
  UIAdaptivePresentationControllerDelegate {
  private let channel: FlutterMethodChannel
  private weak var presenter: UIViewController?
  private let queue = DispatchQueue(label: "anime_flow.download_storage")
  private let defaults = UserDefaults.standard
  private let bookmarksKey = "anime_flow.download_directory_bookmarks"
  private let stagingKey = "anime_flow.download_directory_staging"
  private let stagingRootKey = "anime_flow.download_directory_staging_root"
  private var roots: [String: URL] = [:]
  private var activeURLs: [String: URL] = [:]
  private var pickerResult: FlutterResult?
  private var readingCache: [String: URL] = [:]
  private var staging: [String: String] = [:]
  private var stageRoot: URL {
    FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("download-staging", isDirectory: true)
  }

  init(messenger: FlutterBinaryMessenger, presenter: UIViewController) {
    self.presenter = presenter
    channel = FlutterMethodChannel(name: "anime_flow/download_storage", binaryMessenger: messenger)
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      if call.method == "selectDirectory" {
        self.selectDirectory(call: call, result: result)
        return
      }
      let args = call.arguments as? [String: Any] ?? [:]
      self.queue.async {
        do {
          let value: Any?
          if call.method == "restoreAccess" {
            value = try self.restoreAccess()
          } else {
            guard let path = args["path"] as? String, !path.isEmpty else {
              throw self.failure("Missing directory path")
            }
            let url = self.resolve(path)
            switch call.method {
            case "verifyWritable":
              try self.verifyWritable(url)
              value = nil
            case "prepareDownloadDirectory":
              value = try self.prepareDownloadDirectory(url).path
            case "publishDownloadDirectory":
              value = try self.publishDownloadDirectory(url).path
            case "discardDownloadStaging":
              try self.discardStaging(url)
              value = nil
            case "prepareForReading":
              value = try self.prepareForReading(url).path
            case "writeTextFile":
              guard let text = args["contents"] as? String else {
                throw self.failure("Missing file contents")
              }
              try self.writeTextFile(url, text: text)
              value = nil
            case "deleteDirectory":
              try self.deleteDirectory(url)
              value = nil
            default:
              DispatchQueue.main.async { result(FlutterMethodNotImplemented) }
              return
            }
          }
          DispatchQueue.main.async { result(value) }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "directory_access_failed", message: error.localizedDescription,
                                details: nil))
          }
        }
      }
    }
  }

  deinit {
    for url in activeURLs.values { url.stopAccessingSecurityScopedResource() }
    channel.setMethodCallHandler(nil)
  }

  private func failure(_ message: String) -> NSError {
    NSError(domain: "AnimeFlow.DownloadDirectory", code: 1,
            userInfo: [NSLocalizedDescriptionKey: message])
  }

  private func contains(_ root: URL, _ url: URL) -> Bool {
    let base = root.standardizedFileURL.path
    let path = url.standardizedFileURL.path
    return path == base || path.hasPrefix(base + "/")
  }

  private func isSandbox(_ url: URL) -> Bool {
    contains(URL(fileURLWithPath: NSHomeDirectory()).resolvingSymlinksInPath(),
             url.resolvingSymlinksInPath())
  }

  private func activate(_ url: URL) throws {
    if activeURLs[url.path] != nil { return }
    if url.startAccessingSecurityScopedResource() {
      activeURLs[url.path] = url
    } else if !isSandbox(url) {
      throw failure("Folder access expired. Select the download folder again.")
    }
  }

  private func restoreAccess() throws -> [String: String] {
    let playbackCache = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("download-playback", isDirectory: true)
    try? FileManager.default.removeItem(at: playbackCache)
    roots.merge(Self.restoreBookmarks(in: defaults, key: bookmarksKey, activate: activate)) {
      _, restored in restored
    }
    staging = defaults.dictionary(forKey: stagingKey) as? [String: String] ?? [:]
    var paths = roots.mapValues { $0.path }
    var previousRoots = defaults.stringArray(forKey: stagingRootKey + ".aliases") ?? []
    if let previous = defaults.string(forKey: stagingRootKey), !previousRoots.contains(previous) {
      previousRoots.append(previous)
    }
    if !previousRoots.contains(stageRoot.path) { previousRoots.append(stageRoot.path) }
    for previous in previousRoots { paths[previous] = stageRoot.path }
    defaults.set(previousRoots, forKey: stagingRootKey + ".aliases")
    defaults.set(stageRoot.path, forKey: stagingRootKey)
    return paths
  }

  /// Every visited path remains a key in the existing bookmark dictionary.
  /// After A -> B -> C, both A and B therefore resolve to the current C URL.
  static func restoreBookmarks(in defaults: UserDefaults, key: String,
                               activate: (URL) throws -> Void) -> [String: URL] {
    let saved = defaults.dictionary(forKey: key) as? [String: Data] ?? [:]
    var bookmarks = saved
    var restored: [String: URL] = [:]
    for (original, data) in saved {
      do {
        var stale = false
        // Security-scoped document-picker bookmarks on iOS use empty options;
        // .withSecurityScope is a macOS-only bookmark creation option.
        let url = try URL(resolvingBookmarkData: data, options: [], relativeTo: nil,
                          bookmarkDataIsStale: &stale)
        try activate(url)
        let currentBookmark: Data
        if stale || original != url.path {
          currentBookmark = try url.bookmarkData(options: [],
            includingResourceValuesForKeys: nil, relativeTo: nil)
        } else {
          currentBookmark = data
        }
        // Persist the resolved path before exposing it to downloads. A later
        // launch can then restore records created under this intermediate path.
        bookmarks[original] = currentBookmark
        bookmarks[url.path] = currentBookmark
        restored[original] = url
        restored[url.path] = url
      } catch {
        // Keep failed bookmarks so a temporarily disconnected provider can
        // be restored later. Other granted folders must remain accessible.
        NSLog("AnimeFlow: could not restore folder %@: %@", original, error.localizedDescription)
      }
    }
    defaults.set(bookmarks, forKey: key)
    return restored
  }

  private func resolve(_ path: String) -> URL {
    for original in roots.keys.sorted(by: { $0.count > $1.count }) {
      let source = URL(fileURLWithPath: original)
      let url = URL(fileURLWithPath: path)
      if contains(source, url), let target = roots[original] {
        let suffix = String(url.path.dropFirst(source.path.count))
        return URL(fileURLWithPath: target.path + suffix).standardizedFileURL
      }
    }
    return URL(fileURLWithPath: path).standardizedFileURL
  }

  private func grantedRoot(_ url: URL) throws -> URL {
    guard let root = roots.values.filter({ contains($0, url) })
      .max(by: { $0.path.count < $1.path.count }) else {
      throw failure("Folder access is unavailable. Select the download folder again.")
    }
    return root
  }

  private func coordinateWrite<T>(_ url: URL, options: NSFileCoordinator.WritingOptions = [],
                                 action: @escaping (URL) throws -> T) throws -> T {
    var coordinationError: NSError?
    var outcome: Result<T, Error>?
    NSFileCoordinator().coordinate(writingItemAt: url, options: options,
                                  error: &coordinationError) { coordinated in
      outcome = Result { try action(coordinated) }
    }
    if let error = coordinationError { throw error }
    guard let value = outcome else { throw failure("File coordination did not complete") }
    return try value.get()
  }

  private func selectDirectory(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard pickerResult == nil else {
      result(FlutterError(code: "request_in_progress", message: "A folder picker is already active",
                          details: nil))
      return
    }
    guard let presenter = presenter, presenter.presentedViewController == nil else {
      result(FlutterError(code: "picker_unavailable", message: "Cannot present the folder picker",
                          details: nil))
      return
    }
    let picker = UIDocumentPickerViewController(documentTypes: ["public.folder"], in: .open)
    picker.allowsMultipleSelection = false
    picker.delegate = self
    picker.presentationController?.delegate = self
    picker.title = (call.arguments as? [String: Any])?["title"] as? String
    pickerResult = result
    presenter.present(picker, animated: true)
    picker.presentationController?.delegate = self
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let result = pickerResult else { return }
    pickerResult = nil
    guard let url = urls.first else { result(nil); return }
    queue.async {
      do {
        try self.activate(url)
        let bookmark = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil,
                                            relativeTo: nil)
        var bookmarks = self.defaults.dictionary(forKey: self.bookmarksKey) as? [String: Data] ?? [:]
        bookmarks[url.path] = bookmark
        self.defaults.set(bookmarks, forKey: self.bookmarksKey)
        self.roots[url.path] = url
        let paths = self.roots.mapValues { $0.path }
        DispatchQueue.main.async { result(["path": url.path, "paths": paths]) }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "directory_access_failed", message: error.localizedDescription,
                              details: nil))
        }
      }
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) { cancelPicker() }
  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) { cancelPicker() }
  private func cancelPicker() {
    let result = pickerResult
    pickerResult = nil
    result?(nil)
  }

  private func verifyWritable(_ url: URL) throws {
    _ = try grantedRoot(url)
    try coordinateWrite(url, options: .forMerging) { directory in
      let probe = directory.appendingPathComponent(".anime_flow_" + UUID().uuidString)
      try Data([0]).write(to: probe, options: .withoutOverwriting)
      try FileManager.default.removeItem(at: probe)
    }
  }

  private func stageID(_ url: URL) -> String? {
    guard contains(stageRoot, url), url.path != stageRoot.path else { return nil }
    return String(url.path.dropFirst(stageRoot.path.count + 1))
  }

  private func prepareDownloadDirectory(_ url: URL) throws -> URL {
    if let key = stageID(url), let destination = staging[key] {
      // A crash between publication and Hive persistence may leave a saved
      // staging path. Rebuild that source from the published copy if needed.
      if !FileManager.default.fileExists(atPath: url.path) {
        try copyForReading(resolve(destination), to: url)
      }
      return url
    }
    if isSandbox(url) { return url }
    _ = try grantedRoot(url)
    if let entry = staging.first(where: { resolve($0.value).path == url.path }) {
      return stageRoot.appendingPathComponent(entry.key, isDirectory: true)
    }
    let key = UUID().uuidString + "/" + url.deletingLastPathComponent().lastPathComponent
      + "/" + url.lastPathComponent
    staging[key] = url.path
    defaults.set(staging, forKey: stagingKey)
    return stageRoot.appendingPathComponent(key, isDirectory: true)
  }

  private func publishDownloadDirectory(_ url: URL) throws -> URL {
    guard let key = stageID(url), let destination = staging[key] else {
      if isSandbox(url) { return url }
      throw failure("Download staging directory is unavailable")
    }
    let target = resolve(destination)
    let root = try grantedRoot(target)
    let coordinatedTarget = try coordinateWrite(root, options: .forMerging) { coordinatedRoot in
      let suffix = String(target.path.dropFirst(root.path.count + 1))
      let destination = coordinatedRoot.appendingPathComponent(suffix, isDirectory: true)
      try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(),
                                             withIntermediateDirectories: true)
      return destination
    }
    return try coordinateWrite(coordinatedTarget, options: .forReplacing) { destination in
      try self.replaceDirectory(source: url, target: destination)
      self.invalidateReadingCache(target)
      return destination
    }
  }

  private func replaceDirectory(source: URL, target: URL) throws {
    let fm = FileManager.default
    let parent = target.deletingLastPathComponent()
    try fm.createDirectory(at: parent, withIntermediateDirectories: true)
    let temporary = parent.appendingPathComponent(".anime_flow_" + UUID().uuidString)
    let backup = parent.appendingPathComponent(".anime_flow_backup_" + UUID().uuidString)
    try fm.copyItem(at: source, to: temporary)
    defer { try? fm.removeItem(at: temporary) }
    let existed = fm.fileExists(atPath: target.path)
    if existed { try fm.moveItem(at: target, to: backup) }
    do {
      try fm.moveItem(at: temporary, to: target)
    } catch {
      if existed { try? fm.moveItem(at: backup, to: target) }
      throw error
    }
    if existed { try? fm.removeItem(at: backup) }
  }

  private func discardStaging(_ url: URL) throws {
    guard let key = stageID(url), staging[key] != nil else { return }
    if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
    staging.removeValue(forKey: key)
    defaults.set(staging, forKey: stagingKey)
  }

  private func copyForReading(_ source: URL, to destination: URL) throws {
    _ = try grantedRoot(source)
    var coordinationError: NSError?
    var copyError: Error?
    NSFileCoordinator().coordinate(readingItemAt: source, options: [],
                                  error: &coordinationError) { coordinated in
      do {
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(),
                                               withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: coordinated, to: destination)
      } catch { copyError = error }
    }
    if let error = coordinationError { throw error }
    if let error = copyError { throw error }
  }

  private func prepareForReading(_ url: URL) throws -> URL {
    if isSandbox(url) { return url }
    _ = try grantedRoot(url)
    // Materialize the whole episode, including HLS segments, keys and danmaku.
    let directory = url.deletingLastPathComponent()
    if let cache = readingCache[directory.path],
       FileManager.default.fileExists(atPath: cache.appendingPathComponent(url.lastPathComponent).path) {
      return cache.appendingPathComponent(url.lastPathComponent)
    }
    invalidateReadingCache(directory)
    let cache = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("download-playback/" + UUID().uuidString, isDirectory: true)
    try copyForReading(directory, to: cache)
    readingCache[directory.path] = cache
    return cache.appendingPathComponent(url.lastPathComponent)
  }

  private func invalidateReadingCache(_ directory: URL) {
    // A player may still be reading this snapshot (especially HLS segments).
    // Retire the lookup now; remove old snapshots at the next app launch.
    readingCache.removeValue(forKey: directory.path)
  }

  private func writeTextFile(_ url: URL, text: String) throws {
    if isSandbox(url) {
      try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                             withIntermediateDirectories: true)
      try Data(text.utf8).write(to: url, options: .atomic)
      return
    }
    _ = try grantedRoot(url)
    try coordinateWrite(url) { coordinated in
      try Data(text.utf8).write(to: coordinated, options: .atomic)
    }
    invalidateReadingCache(url.deletingLastPathComponent())
  }

  private func deleteDirectory(_ url: URL) throws {
    if let key = stageID(url), let destination = staging[key] {
      let target = resolve(destination)
      _ = try grantedRoot(target)
      try coordinateWrite(target, options: .forDeleting) { coordinated in
        if FileManager.default.fileExists(atPath: coordinated.path) {
          try FileManager.default.removeItem(at: coordinated)
        }
      }
      invalidateReadingCache(target)
      try discardStaging(url)
      return
    }
    if isSandbox(url) {
      if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
      return
    }
    _ = try grantedRoot(url)
    try coordinateWrite(url, options: .forDeleting) { coordinated in
      if FileManager.default.fileExists(atPath: coordinated.path) {
        try FileManager.default.removeItem(at: coordinated)
      }
    }
    invalidateReadingCache(url)
  }
}
