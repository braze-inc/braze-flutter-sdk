import XCTest
import BrazeKit

final class BrazeFlutterPluginTests: XCTestCase {

  override class func setUp() {
    super.setUp()
  }

  // MARK: - decodeHexToken tests

  func testDecodeHexToken_validHex_returnsCorrectBytes() {
    let hex = "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f"
    guard let data = decodeHexToken(hex) else {
      XCTFail("Expected Data, got nil for valid hex string")
      return
    }
    XCTAssertEqual(data.count, 32)
    let expectedBytes: [UInt8] = Array(0x00...0x1f)
    XCTAssertEqual([UInt8](data), expectedBytes)
  }

  func testDecodeHexToken_highByteValues_decodesCorrectly() {
    // 64-char hex token containing byte values ≥ 0x80, confirming no byte-size limitation.
    let hex = "808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9f"
    guard let data = decodeHexToken(hex) else {
      XCTFail("Expected Data, got nil for high-byte hex string")
      return
    }
    let expectedBytes: [UInt8] = Array(0x80...0x9f)
    XCTAssertEqual([UInt8](data), expectedBytes,
      "Hex decoding must be correct for byte values ≥ 0x80")
  }

  func testDecodeHexToken_uppercaseHex_returnsCorrectBytes() {
    // 64-char uppercase hex token.
    let hex = "DEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF"
    guard let data = decodeHexToken(hex) else {
      XCTFail("Expected Data, got nil for uppercase hex string")
      return
    }
    let expectedBytes: [UInt8] = Array(repeating: [0xde, 0xad, 0xbe, 0xef], count: 8).flatMap { $0 }
    XCTAssertEqual([UInt8](data), expectedBytes)
  }

  func testDecodeHexToken_shortHex_returnsFewerBytes() {
    // Any even-length hex string is accepted; length is not enforced.
    let data = decodeHexToken("000102030405060708090a0b0c0d0e0f")
    XCTAssertEqual(data?.count, 16)
  }

  func testDecodeHexToken_emptyString_returnsEmptyData() {
    let data = decodeHexToken("")
    XCTAssertNotNil(data)
    XCTAssertEqual(data?.count, 0)
  }

  func testDecodeHexToken_oddLength_returnsNil() {
    XCTAssertNil(decodeHexToken("abc"), "Odd-length hex string should return nil")
  }

  func testDecodeHexToken_invalidCharacters_returnsNil() {
    XCTAssertNil(decodeHexToken(String(repeating: "z", count: 64)),
      "Non-hex characters should return nil")
  }

  // MARK: - BrazeFlutterClient Tests

  func testCreateSubscriptions() {
    let braze = Braze.init(configuration: .init())
    let brazeClient = BrazeFlutterClient(braze: braze)
    var bannerSubscription: Braze.Cancellable? = nil
    var contentCardsSubscription: Braze.Cancellable? = nil
    var featureFlagsSubscription: Braze.Cancellable? = nil
    var notificationSubscription: Braze.Cancellable? = nil
    
    XCTAssertNil(bannerSubscription)
    XCTAssertNil(contentCardsSubscription)
    XCTAssertNil(featureFlagsSubscription)
    XCTAssertNil(notificationSubscription)

    bannerSubscription = brazeClient.createBannersSubscription({ _ in })
    contentCardsSubscription = brazeClient.createContentCardsSubscription({ _ in })
    featureFlagsSubscription = brazeClient.createFeatureFlagsSubscription({ _ in })
    notificationSubscription = brazeClient.createPushNotificationSubscription({ _ in })
    
    XCTAssertNotNil(bannerSubscription)
    XCTAssertNotNil(contentCardsSubscription)
    XCTAssertNotNil(featureFlagsSubscription)
    XCTAssertNotNil(notificationSubscription)
  }
  
  func testRemoveSubscription() {
    let braze = Braze.init(configuration: .init())
    let brazeClient = BrazeFlutterClient(braze: braze)
    var subscription: Braze.Cancellable? = braze.notifications.subscribeToUpdates({ _ in })
    XCTAssertNotNil(subscription)
    brazeClient.removeSubscription(&subscription)
    XCTAssertNil(subscription)
  }

  // MARK: - Configuration closure tests

  func testConfigurationClosureAppliesSettings() {
    let configuration = Braze.Configuration(apiKey: "test-key", endpoint: "test-endpoint")
    let configBlock: (Braze.Configuration) -> Void = { config in
      config.sessionTimeout = 42
    }
    configBlock(configuration)
    XCTAssertEqual(configuration.sessionTimeout, 42)
  }

  func testPostInitializationClosureReceivesBrazeInstance() {
    var receivedBraze: Braze?
    let postInitBlock: (Braze) -> Void = { braze in
      receivedBraze = braze
    }
    let braze = Braze(configuration: .init(apiKey: "test-key", endpoint: "test-endpoint"))
    postInitBlock(braze)
    XCTAssertTrue(receivedBraze === braze)
  }

  // MARK: - Logging Tests

  // Native maps Braze.Configuration.Logger.Level to a Dart BrazeLogLevel case name
  // (string). Numeric level values are owned by the Dart enum and looked up via
  // the levelValues map provided to native via setLogLevel.
  private func levelName(for level: Braze.Configuration.Logger.Level) -> String? {
    switch level {
    case .debug: return "debug"
    case .info: return "info"
    case .error: return "error"
    case .disabled: return nil
    @unknown default: return nil
    }
  }

  func testLevelName_debugLevel_mapsToDebugCaseName() {
    XCTAssertEqual(levelName(for: .debug), "debug")
  }

  func testLevelName_infoLevel_mapsToInfoCaseName() {
    XCTAssertEqual(levelName(for: .info), "info")
  }

  func testLevelName_errorLevel_mapsToErrorCaseName() {
    XCTAssertEqual(levelName(for: .error), "error")
  }

  func testLevelName_disabledLevel_isNil() {
    XCTAssertNil(levelName(for: .disabled))
  }

  func testLoggerPrint_belowMinimumDartLevel_isFiltered() {
    let dartLevelValues = ["debug": 500, "info": 800, "error": 1000]
    let minimumDartLevel = dartLevelValues["info"]!  // threshold = INFO

    let dartLevel = levelName(for: .debug).flatMap { dartLevelValues[$0] }
    let shouldForward = (dartLevel ?? Int.min) >= minimumDartLevel

    XCTAssertFalse(shouldForward, "Debug should be filtered when threshold is INFO")
  }

  func testLoggerPrint_atMinimumDartLevel_isForwarded() {
    let dartLevelValues = ["debug": 500, "info": 800, "error": 1000]
    let minimumDartLevel = dartLevelValues["info"]!  // threshold = INFO

    let dartLevel = levelName(for: .info).flatMap { dartLevelValues[$0] }
    let shouldForward = (dartLevel ?? Int.min) >= minimumDartLevel

    XCTAssertTrue(shouldForward, "Info should be forwarded when threshold is INFO")
  }
}
