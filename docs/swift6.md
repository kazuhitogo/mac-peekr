# Swift 6 並行性パターン

## オーディオコールバックスレッドからの MainActor 呼び出し

オーディオコールバックスレッドから `Task { @MainActor ... }` を作ると abort する。

**解決策**: `OSAllocatedUnfairLock` でバッファ共有し、タイマーでポーリング。

```swift
// NG
audioCallback { samples in
    Task { @MainActor in self.micSamples = samples } // → abort
}

// OK
private let lock = OSAllocatedUnfairLock<[Float]>(initialState: [])

audioCallback { samples in
    lock.withLock { $0 = samples } // コールバックスレッドから安全に書く
}

// MainActor タイマーで読む
Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
    Task { @MainActor in
        self.micSamples = self.lock.withLock { $0 }
    }
}
```

## nonisolated(unsafe)

`nonisolated(unsafe) var timer: Timer?` は新しい SDK で警告が出るが動作に影響なし。
Service クラスで Timer を保持する際の標準パターンとして使用中。

## @Observable サービスクラスの基本構造

```swift
@Observable
@MainActor
final class FooService {
    private(set) var value: Double = 0
    private nonisolated(unsafe) var timer: Timer?

    init() {
        update()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.update() }
        }
        timer?.tolerance = 0.1
    }

    deinit { timer?.invalidate() }
}
```
