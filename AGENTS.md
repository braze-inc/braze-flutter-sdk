# Method-channel replies

Dart `invokeMethod` is a Future. If native returns without `result.success` / `result.error` / `result.notImplemented` (Android) or `result(...)` / `FlutterError` (iOS), any `await` hangs forever.

## Must reply on every path

This includes missing args, null cache, SDK disabled, and early `return` / `guard else` exits.

### Android

```kotlin
// BAD — Dart await never completes
if (placementId == null) {
    brazelog(W) { "Unexpected null placementId." }
    return
}

// GOOD — invalid args still complete the Future
if (placementId == null) {
    brazelog(W) { "Unexpected null placementId." }
    result.error("INVALID_ARGUMENT", "getBanner - Invalid placementId", null)
    return
}
```

```kotlin
// BAD — null cache drops the reply
if (contentCards != null) {
    result.success(contentCards.map { it.forJsonPut().toString() })
}

// GOOD — always reply; empty list if there is nothing to return
val contentCards = getCachedContentCards() ?: emptyList()
result.success(contentCards.map { it.forJsonPut().toString() })
```

### iOS

```swift
// BAD — Dart await never completes
guard let placementId = callArguments["placementId"] as? String else {
  print("Unexpected null placementId in `getBanner`.")
  return
}

// GOOD — invalid args still complete the Future
guard let placementId = callArguments["placementId"] as? String else {
  print("Unexpected null placementId in `getBanner`.")
  completion(.failure(BrazeFlutterClientError(
    code: "INVALID_ARGUMENT",
    message: "getBanner - Invalid placementId"
  )))
  return
}
```

```swift
// BAD — optional client / cache miss never calls result
brazeClient?.getBanner(callArguments: args) { outcome in
  if case .success(let value) = outcome { result(value) }
}

// GOOD — every outcome replies, including failure
brazeClient?.getBanner(callArguments: args) { outcome in
  switch outcome {
  case .success(let value):
    result(value)
  case .failure(let error):
    result(FlutterError(code: error.code, message: error.message, details: nil))
  }
}

// GOOD — list getters always reply with an array
result(brazeClient?.getCachedContentCards() ?? [])
```

If `brazeClient` is nil, still call `result(...)` (empty list, `NSNull()`, or `FlutterError`). Do not rely on optional chaining around a completion that is the only place `result` is invoked.

## What to return

- Missing **required** args: `result.error` / `FlutterError` (`INVALID_ARGUMENT`).
- Null or empty cache for list getters (`getCachedContentCards`, `getAllFeatureFlags`): empty list, matching the other platform.
- Lookup misses (`getBanner`, `getFeatureFlagByID`): `result.success(null)` / `nil`, not a dropped reply.
- `else`: `result.notImplemented()` / `FlutterMethodNotImplemented`.

Do not treat `verifyNoInteractions(mockMethodChannelResult)` as expected behavior for these handlers.

Void Dart wrappers still create a Future. Prefer completing `result` there too, but **getters and any `await invokeMethod`** must never drop the reply.
