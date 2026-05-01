# Mac System Monitor 実装計画

## フェーズ構成

```
Phase 1: プロジェクト基盤
Phase 2: データ取得層 (Services)
Phase 3: UIコンポーネント (ウィジェット)
Phase 4: ウィンドウ制御 (透過・最前面)
Phase 5: 統合・仕上げ
```

---

## Phase 1: プロジェクト基盤

### 1-1. Xcodeプロジェクト作成
- App テンプレート、Bundle ID: `com.yourname.macsystemmonitor`
- macOS 15.0 Deployment Target
- Swift 6 Strict Concurrency 有効化

### 1-2. エンタイトルメント設定
ファイル: `MacSystemMonitor.entitlements`
```xml
com.apple.security.app-sandbox = true
com.apple.security.network.client = true
NSMotionUsageDescription = "加速度・ジャイロ・コンパスの表示に使用します"
```

### 1-3. Privacy Manifest
ファイル: `PrivacyInfo.xcprivacy`
- `NSPrivacyAccessedAPITypes` に Motion 追加

### 1-4. フォルダ構成
```
MacSystemMonitor/
├── App/
│   ├── MacSystemMonitorApp.swift   # @main
│   └── AppDelegate.swift           # NSWindow設定
├── Services/                       # データ取得層
│   ├── CPUService.swift
│   ├── MemoryService.swift
│   ├── StorageService.swift
│   ├── BatteryService.swift
│   ├── GPUService.swift
│   ├── NetworkService.swift
│   ├── DisplayService.swift
│   ├── MotionService.swift
│   └── ThermalService.swift
├── ViewModels/
│   └── SystemMonitorViewModel.swift  # 全Serviceをまとめる@Observable
├── Views/
│   ├── ContentView.swift
│   ├── TitleBarView.swift            # 透過スライダー
│   └── Widgets/
│       ├── CPUWidget.swift
│       ├── MemoryWidget.swift
│       ├── StorageWidget.swift
│       ├── BatteryWidget.swift
│       ├── GPUWidget.swift
│       ├── NetworkWidget.swift
│       ├── DisplayWidget.swift
│       ├── MotionWidget.swift        # Accel + Gyro + Compass
│       └── ThermalWidget.swift
└── Helpers/
    └── ByteFormatter.swift           # KB/MB/GB自動切換
```

---

## Phase 2: データ取得層 (Services)

各Serviceは `@Observable` クラス。メインスレッドで値更新、取得は `Task` + `actor` で非同期。

### 2-1. CPUService
```swift
// host_statistics64() → host_cpu_load_info
// user/sys/idle tick差分 → %計算
// history: [Double] 最大60件 (60秒分)
// Timer: 1秒
```

### 2-2. MemoryService
```swift
// host_statistics64() → vm_statistics64
// page_size * pages → GB変換
// used = active + wired + compressed
// Timer: 1秒
```

### 2-3. StorageService
```swift
// FileManager.default.mountedVolumeURLs()
// URLResourceKey: volumeAvailableCapacityForImportantUsageKey
//                 volumeTotalCapacityKey
//                 volumeNameKey
//                 volumeIsRemovableKey (外付け判定)
// Timer: 10秒
```

### 2-4. BatteryService
```swift
// IOPSCopyPowerSourcesInfo() → CFArray
// IOPSGetPowerSourceDescription() → CFDictionary
// キー: kIOPSCurrentCapacityKey, kIOPSMaxCapacityKey,
//       kIOPSCycleCountKey, kIOPSBatteryHealthKey,
//       kIOPSIsChargingKey, kIOPSPowerSourceStateKey
// Timer: 30秒
```

### 2-5. GPUService
```swift
// MTLCreateSystemDefaultDevice()
// name, maxBufferLength, registryID
// 起動時1回のみ
```

### 2-6. NetworkService
```swift
// getifaddrs() ループ → if_data.ifi_ibytes / ifi_obytes
// 前回値との差分 / 経過秒 → 速度
// en0/en1/utun等を列挙、lo0除外
// Timer: 1秒
```

### 2-7. DisplayService
```swift
// NSScreen.screens → localizedName, frame, visibleFrame
// NSScreen.main で主画面判定
// maximumFramesPerSecond でリフレッシュレート
// NotificationCenter: NSApplicationDidChangeScreenParametersNotification
```

### 2-8. MotionService
```swift
// CMMotionManager
// startAccelerometerUpdates(to:interval: 0.1) → CMAccelerometerData
// startGyroUpdates(to:interval: 0.1) → CMGyroData
// startMagnetometerUpdates(to:interval: 0.1) → CMMagnetometerData
// 方位角: atan2(y, x) → 度変換 → N/NE/E/SE/S/SW/W/NW
```

### 2-9. ThermalService
```swift
// ProcessInfo.processInfo.thermalState
// NotificationCenter: ProcessInfo.thermalStateDidChangeNotification
// .nominal / .fair / .serious / .critical → 色マッピング
```

---

## Phase 3: UIコンポーネント

### 3-1. 共通ウィジェット枠
`WidgetCard.swift`: 角丸背景 + タイトルラベルの共通コンテナ。全ウィジェットがこれを使う。

```swift
struct WidgetCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content
}
```

### 3-2. 折れ線グラフ (CPUWidget用)
`LineChartView.swift`: `Canvas` APIで描画。SwiftChartsは使わない（サイズ過大）。
- データ: `[Double]` 0.0〜1.0正規化
- グリッド線: 25% / 50% / 75%

### 3-3. 積み上げ棒 (MemoryWidget用)
`StackedBarView.swift`: `GeometryReader` + `HStack` で比率描画。

### 3-4. 横棒グラフ (StorageWidget用)
`HorizontalBarView.swift`: 使用率に応じた色変化（50%未満緑、80%未満黄、以上赤）。

### 3-5. 円グラフ (BatteryWidget用)
`DonutChartView.swift`: `Canvas` + `Path` で弧描画。

### 3-6. 各ウィジェット実装
上記グラフ部品を使い各Widgetを実装。ViewModel経由でデータ参照。

---

## Phase 4: ウィンドウ制御

### 4-1. NSWindow設定 (AppDelegate)
```swift
window.level = .floating
window.isOpaque = false
window.backgroundColor = .clear
window.styleMask = [.resizable, .miniaturizable]
window.titlebarAppearsTransparent = true
window.titleVisibility = .hidden
window.minSize = NSSize(width: 600, height: 400)
// 最小化・フルスクリーンボタン非表示
window.standardWindowButton(.miniaturizeButton)?.isHidden = true
window.standardWindowButton(.zoomButton)?.isHidden = true
```

### 4-2. NSVisualEffectView ホスト
`VisualEffectBackground.swift`: `NSViewRepresentable` で `NSVisualEffectView` をSwiftUIに橋渡し。
- material: `.hudWindow`
- blendingMode: `.behindWindow`
- state: `.active`

### 4-3. 透過スライダー
`TitleBarView.swift` に `Slider(value: $opacity, in: 0.2...1.0)` 配置。
`opacity` 変化時に `NSApp.mainWindow?.alphaValue = opacity`。

### 4-4. カスタムドラッグ領域
TitleBarView に `.onDrag` 相当として `NSWindow.performDrag(with:)` を呼ぶ `NSViewRepresentable` を設置。

---

## Phase 5: 統合・仕上げ

### 5-1. SystemMonitorViewModel
全Serviceをまとめる単一の `@Observable` class。`ContentView` はこれだけを参照。

```swift
@Observable final class SystemMonitorViewModel {
    let cpu = CPUService()
    let memory = MemoryService()
    let storage = StorageService()
    let battery = BatteryService()
    let gpu = GPUService()
    let network = NetworkService()
    let display = DisplayService()
    let motion = MotionService()
    let thermal = ThermalService()
}
```

### 5-2. ContentView グリッド配置
`LazyVGrid` で spec.md のレイアウト通りに配置。
- 上段4列: CPU / RAM / Storage / Battery
- 中段2列: GPU / Network
- 横断1列: Displays
- 下段4列: Accel / Gyro / Compass / Thermal

### 5-3. パフォーマンス確認
- Instruments → CPU Profiler でアイドル時 < 1% 確認
- Memory Graph で < 50MB 確認
- 全Timerが `RunLoop.main` ではなく `DispatchQueue` or `Task` で動作確認

### 5-4. App Store提出準備
- App Icon 全サイズ生成
- スクリーンショット作成
- PrivacyInfo.xcprivacy 完備確認
- Hardened Runtime + Notarization

---

## 実装順序（推奨）

```
1. Phase 1 (基盤)          ← プロジェクト作成
2. Phase 4 (ウィンドウ)    ← 透過・最前面を最初に確認
3. Phase 2-1,2 (CPU/RAM)   ← コアデータ取得
4. Phase 3-1,2,3 (グラフ)  ← UI部品
5. Phase 2-3〜9 (残Services) ← 残データ取得
6. Phase 3-4〜6 (残Widget)  ← 残UI
7. Phase 5 (統合)           ← 結合・調整
```

Phase 4を早めに着手する理由: 透過ウィンドウはSwiftUI標準の `.windowStyle` と競合する場合があり、早期に動作確認しないと後で大きく作り直す可能性がある。

---

## リスク・注意点

- **CoreMotion on Mac**: Apple Silicon MacBook Airでは動作するが、シミュレータ不可。実機必須。
- **IOPSCopyPowerSourcesInfo**: `IOKit.framework` を明示リンク必要。
- **getifaddrs**: `Darwin` import + `ifaddrs` 構造体はSwiftから扱いにくい。`UnsafeMutablePointer` 操作が必要。
- **Swift 6 Strict Concurrency**: `@MainActor` と `actor` の境界を最初に設計しないと後で大量修正が発生する。ServiceはすべてMainActorで統一するか、内部でMainActorに投げる設計にする。
- **NSVisualEffectView + alphaValue**: `alphaValue` をウィンドウ全体に適用するとblur effectの見た目が変わる。alphaValueは `contentView` に適用する方が自然な場合がある。要検証。
