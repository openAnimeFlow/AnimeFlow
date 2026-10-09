import Flutter
import UIKit
import XCTest

@testable import Runner

final class DownloadDirectoryControllerTests: XCTestCase {
  private let bookmarksKey = "anime_flow.download_directory_bookmarks"

  private struct Fixture {
    let presenter: PresenterSpy
    let controller: DownloadDirectoryController
    let channel: FlutterMethodChannel
    let defaults: UserDefaults
    let directory: URL
  }

  @MainActor
  private func fixture(usePickerSpy: Bool = true) throws -> Fixture {
    let suite = "DownloadDirectoryControllerTests." + UUID().uuidString
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true).resolvingSymlinksInPath()
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    addTeardownBlock {
      defaults.removePersistentDomain(forName: suite)
      try FileManager.default.removeItem(at: directory)
    }
    let messenger = TestMessenger()
    let presenter = PresenterSpy()
    let makePicker: (() -> UIDocumentPickerViewController)? = usePickerSpy
      ? { PickerSpy(documentTypes: ["public.folder"], in: .open) } : nil
    let controller = DownloadDirectoryController(messenger: messenger, presenter: presenter,
                                                 defaults: defaults, makePicker: makePicker)
    return Fixture(presenter: presenter, controller: controller,
                   channel: FlutterMethodChannel(name: "anime_flow/download_storage",
                                                 binaryMessenger: messenger),
                   defaults: defaults, directory: directory)
  }

  @MainActor
  private func openPicker(_ fixture: Fixture,
                          result: @escaping FlutterResult = { _ in }) throws -> PickerSpy {
    let presented = expectation(description: "Folder picker presented")
    fixture.presenter.onPresent = { presented.fulfill() }
    fixture.channel.invokeMethod("selectDirectory", arguments: ["title": "Download location"],
                                 result: result)
    wait(for: [presented], timeout: 3)
    return try XCTUnwrap(fixture.presenter.lastPresented as? PickerSpy)
  }

  @MainActor
  func testDefaultPickerPresentsOnMainThreadWithDelegateAndOpenMode() throws {
    let fixture = try fixture(usePickerSpy: false)
    let presented = expectation(description: "Default picker presented")
    fixture.presenter.onPresent = {
      XCTAssertTrue(Thread.isMainThread)
      presented.fulfill()
    }
    fixture.channel.invokeMethod("selectDirectory", arguments: ["title": "Download location"])
    wait(for: [presented], timeout: 3)
    let picker = try XCTUnwrap(fixture.presenter.lastPresented as? UIDocumentPickerViewController)
    XCTAssertTrue(picker.delegate === fixture.controller)
    XCTAssertFalse(picker.allowsMultipleSelection)
    XCTAssertEqual(picker.documentPickerMode, .open)
    XCTAssertEqual(picker.title, "Download location")
    fixture.controller.documentPickerWasCancelled(picker)
  }

  @MainActor
  func testSelectionDismissesBeforeReplyAndPersistsWritableFolder() throws {
    let fixture = try fixture()
    let replied = expectation(description: "Selected folder returned")
    var picker: PickerSpy?
    var replyCount = 0
    picker = try openPicker(fixture) { value in
      XCTAssertTrue(Thread.isMainThread)
      XCTAssertEqual(picker?.dismissCalls, 1)
      let selected = value as? [String: Any]
      XCTAssertEqual(selected?["path"] as? String, fixture.directory.path)
      XCTAssertEqual((selected?["paths"] as? [String: String])?[fixture.directory.path],
                     fixture.directory.path)
      XCTAssertNotNil((fixture.defaults.dictionary(forKey: self.bookmarksKey)
                        as? [String: Data])?[fixture.directory.path])
      replyCount += 1
      replied.fulfill()
    }
    let activePicker = try XCTUnwrap(picker)
    fixture.controller.documentPicker(activePicker, didPickDocumentsAt: [fixture.directory])
    // Closing the picker must not wait for bookmark/provider work to finish.
    XCTAssertEqual(activePicker.dismissCalls, 1)
    fixture.controller.documentPickerWasCancelled(activePicker)
    fixture.controller.documentPicker(activePicker, didPickDocumentsAt: [fixture.directory])
    wait(for: [replied], timeout: 3)
    XCTAssertEqual(replyCount, 1)

    let writable = expectation(description: "Selected folder verified writable")
    fixture.channel.invokeMethod("verifyWritable", arguments: ["path": fixture.directory.path]) {
      XCTAssertNil($0)
      writable.fulfill()
    }
    wait(for: [writable], timeout: 3)
    XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: fixture.directory.path).isEmpty)
  }

  @MainActor
  func testAccessFailureDismissesReturnsErrorAndAllowsRetry() throws {
    let fixture = try fixture()
    let failed = expectation(description: "Access error returned")
    let picker = try openPicker(fixture) {
      XCTAssertTrue(Thread.isMainThread)
      XCTAssertEqual(($0 as? FlutterError)?.code, "directory_access_failed")
      failed.fulfill()
    }
    let ungranted = URL(fileURLWithPath: "/ungranted-provider/" + UUID().uuidString,
                       isDirectory: true)
    fixture.controller.documentPicker(picker, didPickDocumentsAt: [ungranted])
    XCTAssertEqual(picker.dismissCalls, 1)
    wait(for: [failed], timeout: 3)
    XCTAssertNil(fixture.defaults.dictionary(forKey: bookmarksKey))
    let retry = try openPicker(fixture)
    XCTAssertFalse(picker === retry)
    fixture.controller.documentPickerWasCancelled(retry)
  }

  @MainActor
  func testCancelReturnsOnceAndOldCallbackCannotCancelRetry() throws {
    let fixture = try fixture()
    var cancelled = 0
    let first = try openPicker(fixture) {
      XCTAssertNil($0)
      cancelled += 1
    }
    fixture.controller.documentPickerWasCancelled(first)
    fixture.controller.documentPickerWasCancelled(first)
    XCTAssertEqual(cancelled, 1)
    XCTAssertEqual(first.dismissCalls, 1)

    var retryReplies = 0
    let retry = try openPicker(fixture) { _ in retryReplies += 1 }
    fixture.controller.documentPickerWasCancelled(first)
    fixture.controller.documentPicker(first, didPickDocumentsAt: [fixture.directory])
    XCTAssertEqual(retryReplies, 0)
    XCTAssertEqual(retry.dismissCalls, 0)
    fixture.controller.documentPickerWasCancelled(retry)
    XCTAssertEqual(retryReplies, 1)
  }

  @MainActor
  func testInteractiveDismissalCompletesPendingRequest() throws {
    let fixture = try fixture()
    var replies = 0
    let picker = try openPicker(fixture) {
      XCTAssertNil($0)
      replies += 1
    }
    let presentation = UIPresentationController(presentedViewController: picker,
                                                presenting: fixture.presenter)
    fixture.controller.presentationControllerDidDismiss(presentation)
    fixture.controller.documentPickerWasCancelled(picker)
    XCTAssertEqual(replies, 1)
    XCTAssertEqual(picker.dismissCalls, 1)
  }

  @MainActor
  func testEmptySelectionDismissesAndReturnsCancellation() throws {
    let fixture = try fixture()
    var replies = 0
    let picker = try openPicker(fixture) {
      XCTAssertNil($0)
      replies += 1
    }
    fixture.controller.documentPicker(picker, didPickDocumentsAt: [])
    XCTAssertEqual(replies, 1)
    XCTAssertEqual(picker.dismissCalls, 1)
  }

  @MainActor
  func testConcurrentRequestDoesNotReplaceActivePicker() throws {
    let fixture = try fixture()
    var firstReplies = 0
    let picker = try openPicker(fixture) { _ in firstReplies += 1 }
    let rejected = expectation(description: "Duplicate request rejected")
    fixture.channel.invokeMethod("selectDirectory", arguments: nil) {
      XCTAssertEqual(($0 as? FlutterError)?.code, "request_in_progress")
      rejected.fulfill()
    }
    wait(for: [rejected], timeout: 3)
    XCTAssertEqual(fixture.presenter.presentCalls, 1)
    XCTAssertEqual(firstReplies, 0)
    fixture.controller.documentPickerWasCancelled(picker)
    XCTAssertEqual(firstReplies, 1)
  }

  @MainActor
  func testBusyPresenterReturnsErrorWithoutOpeningPicker() throws {
    let fixture = try fixture()
    fixture.presenter.blockingController = UIViewController()
    let rejected = expectation(description: "Unavailable presenter reported")
    fixture.channel.invokeMethod("selectDirectory", arguments: nil) {
      XCTAssertEqual(($0 as? FlutterError)?.code, "picker_unavailable")
      rejected.fulfill()
    }
    wait(for: [rejected], timeout: 3)
    XCTAssertEqual(fixture.presenter.presentCalls, 0)
    fixture.presenter.blockingController = nil
    let picker = try openPicker(fixture)
    fixture.controller.documentPickerWasCancelled(picker)
  }

  @MainActor
  func testCallbackFromOtherPickerLeavesRequestPending() throws {
    let fixture = try fixture()
    var replies = 0
    let active = try openPicker(fixture) { _ in replies += 1 }
    let other = PickerSpy(documentTypes: ["public.folder"], in: .open)
    fixture.controller.documentPicker(other, didPickDocumentsAt: [fixture.directory])
    fixture.controller.documentPickerWasCancelled(other)
    XCTAssertEqual(replies, 0)
    XCTAssertEqual(active.dismissCalls, 0)
    fixture.controller.documentPickerWasCancelled(active)
    XCTAssertEqual(replies, 1)
  }

  @MainActor
  func testRestoringBookmarksKeepsIntermediatePathAcrossMoves() throws {
    let fixture = try fixture()
    let original = fixture.directory.appendingPathComponent("A", isDirectory: true)
    let intermediate = fixture.directory.appendingPathComponent("B", isDirectory: true)
    let current = fixture.directory.appendingPathComponent("C", isDirectory: true)
    for url in [intermediate, current] {
      try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
    // A bookmark resolves at B after the first move. B must become a persisted
    // alias before downloads can record paths under B.
    let atB = try intermediate.bookmarkData(options: [], includingResourceValuesForKeys: nil,
                                          relativeTo: nil)
    fixture.defaults.set([original.path: atB], forKey: bookmarksKey)
    let first = DownloadDirectoryController.restoreBookmarks(in: fixture.defaults,
                                                             key: bookmarksKey, activate: { _ in })
    XCTAssertEqual(first[original.path]?.path, intermediate.path)
    XCTAssertEqual(first[intermediate.path]?.path, intermediate.path)
    let saved = try XCTUnwrap(fixture.defaults.dictionary(forKey: bookmarksKey) as? [String: Data])
    XCTAssertNotNil(saved[intermediate.path])

    // Model the second move by letting all saved bookmarks now resolve at C.
    let atC = try current.bookmarkData(options: [], includingResourceValuesForKeys: nil,
                                     relativeTo: nil)
    fixture.defaults.set(saved.mapValues { _ in atC }, forKey: bookmarksKey)
    let second = DownloadDirectoryController.restoreBookmarks(in: fixture.defaults,
                                                              key: bookmarksKey, activate: { _ in })
    for path in [original.path, intermediate.path, current.path] {
      XCTAssertEqual(second[path]?.path, current.path)
    }
  }

  @MainActor
  func testFailedBookmarkDoesNotDiscardOtherGrantsOrSavedData() throws {
    let fixture = try fixture()
    let valid = try fixture.directory.bookmarkData(options: [], includingResourceValuesForKeys: nil,
                                                  relativeTo: nil)
    let broken = Data([0, 1, 2])
    fixture.defaults.set([fixture.directory.path: valid, "/unavailable": broken], forKey: bookmarksKey)
    let restored = DownloadDirectoryController.restoreBookmarks(in: fixture.defaults,
                                                                key: bookmarksKey, activate: { _ in })
    XCTAssertEqual(restored[fixture.directory.path]?.path, fixture.directory.path)
    XCTAssertNil(restored["/unavailable"])
    XCTAssertEqual((fixture.defaults.dictionary(forKey: bookmarksKey) as? [String: Data])?["/unavailable"],
                   broken)
  }
}

private final class PresenterSpy: UIViewController {
  var lastPresented: UIViewController?
  var blockingController: UIViewController?
  var presentCalls = 0
  var onPresent: (() -> Void)?

  override var presentedViewController: UIViewController? { blockingController }

  override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool,
                        completion: (() -> Void)? = nil) {
    XCTAssertTrue(Thread.isMainThread)
    lastPresented = viewControllerToPresent
    presentCalls += 1
    completion?()
    onPresent?()
  }
}

private final class PickerSpy: UIDocumentPickerViewController {
  var dismissCalls = 0

  override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
    XCTAssertTrue(Thread.isMainThread)
    dismissCalls += 1
    completion?()
  }
}

/// Routes a real FlutterMethodChannel through its native handler, including
/// encoding and decoding results, without launching a Dart isolate.
private final class TestMessenger: NSObject, FlutterBinaryMessenger {
  private var handlers: [String: FlutterBinaryMessageHandler] = [:]

  func send(onChannel channel: String, message: Data?) {
    send(onChannel: channel, message: message, binaryReply: nil)
  }

  func send(onChannel channel: String, message: Data?, binaryReply callback: FlutterBinaryReply?) {
    guard let handler = handlers[channel] else { callback?(nil); return }
    handler(message, callback ?? { _ in })
  }

  func setMessageHandlerOnChannel(_ channel: String,
                                 binaryMessageHandler handler: FlutterBinaryMessageHandler?)
    -> FlutterBinaryMessengerConnection {
    handlers[channel] = handler
    return 1
  }

  func cleanUpConnection(_ connection: FlutterBinaryMessengerConnection) {
    handlers.removeAll()
  }
}
