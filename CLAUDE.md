# Peekr

macOSシステム監視デスクトップアプリ。

## 技術スタック

- Swift 6 + SwiftUI
- macOS 15.0+ / Apple Silicon必須
- Xcode プロジェクト: `MacSystemMonitor.xcodeproj`（スキーム: `MacSystemMonitor`）

## 実装状況

全ウィジェット実装済み・動作確認済み:
- CPU / Memory / Storage / Battery / GPU / Network
- Wi-Fi（CoreWLAN）
- Audio（マイク波形 + スピーカー波形）
- Bluetooth（IOBluetooth）
- USB（IOKit、VID:PID表示）
- Display / Thermal（4段階）

## サンドボックス状態

**現在: サンドボックス無効**（entitlementsファイルが空）
- App Store提出にはサンドボックス有効が必須
- サンドボックス有効化するとSMC・一部IOKitが使えなくなる

## 設計決定

### ウィンドウ
- 常時最前面: `NSWindow.level = .floating`
- 透過: `NSWindow.isOpaque = false` + スライダーで20〜100%調整
- 背景: `NSVisualEffectView`（`.hudWindow`マテリアル）
- タイトルバー非表示（borderless）+ カスタムドラッグ領域

### データ
- 履歴なし（セッション内メモリのみ、永続化なし）

### 温度センサー
- サンドボックス無効なら℃取得可能だが未実装（SMC必要）
- サンドボックス有効時は `ProcessInfo.thermalState` の4段階のみ

### WidgetCard（折りたたみ）
- `WidgetCard<Content, Summary>` — collapsed時にヘッダー右端へ Summary を表示
- `init(title:collapsedSummary:content:)` と `init(title:content:)`（Summary=EmptyView）の2パターン
- 折りたたみ状態は `@AppStorage("widget_collapsed_\(title)")` で永続化
- 詳細: `docs/widget-architecture.md`

## ビルド

```bash
# Debug
xcodebuild -project MacSystemMonitor.xcodeproj -scheme MacSystemMonitor -configuration Debug build

# Release
xcodebuild -project MacSystemMonitor.xcodeproj -scheme MacSystemMonitor -configuration Release -derivedDataPath build build
```

## 配布

- Homebrew tap: `kazuhitogo/tap`（`homebrew-tap` リポジトリ）
- Cask: `Casks/peekr.rb`
- GitHub Releases: https://github.com/kazuhitogo/mac-peekr/releases
- リリース手順: `docs/release.md`

## docs/

詳細な実装知見は以下を参照（必要時のみ読む）:
- `docs/audio.md` — AudioQueue / HALC overload / ScreenCaptureKit
- `docs/swift6.md` — Swift 6 並行性パターン
- `docs/peripheral.md` — Bluetooth / USB
- `docs/widget-architecture.md` — ウィジェット構造・WidgetCard 設計
- `docs/release.md` — リリース・Cask 更新手順
