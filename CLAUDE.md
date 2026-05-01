# Peekr

macOSシステム監視デスクトップアプリ。開発中。

## ドキュメント

- `spec.md` — 仕様書（画面構成・ウィジェット仕様・API・エンタイトルメント）
- `PLAN.md` — 実装計画（フェーズ・ファイル構成・実装順序・リスク）

## 技術スタック

- Swift 6 + SwiftUI
- macOS 15.0+ / Apple Silicon必須
- 配布: 未定（現在サンドボックス無効）

## 現在の実装状況

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
- 温度センサー実値取得にはサンドボックス無効が必要

## 確定した設計決定

### 温度センサー
- サンドボックス無効の現状では℃値取得可能だが未実装（SMC必要）
- サンドボックス有効時は `ProcessInfo.thermalState` の4段階のみ

### ウィンドウ
- 常時最前面: `NSWindow.level = .floating`
- 透過: `NSWindow.isOpaque = false` + スライダーで20〜100%調整
- 背景: `NSVisualEffectView`（`.hudWindow`マテリアル）
- タイトルバー非表示（borderless）+ カスタムドラッグ領域

### データ
- 履歴なし（セッション内メモリのみ、永続化なし）

## 重要な実装上の知見

### マイク（AudioQueue）
- `AVAudioEngine.start()` を MainActor から呼ぶと AudioSession RootQueue で `_dispatch_assert_queue_fail` クラッシュ
- `AVCaptureSession` は音声のみでも CMIO カメラ拡張を列挙して `RebuildAudioConverter` エラーを出す
- **現在の実装: `AudioQueueNewInput`**（CMIO 非使用、コールバックは内部スレッド）
- 権限チェックは `AVCaptureDevice.authorizationStatus` → 未確定時のみ `requestAccess` を呼ぶ

### HALC overload（既知・許容済み）
Bluetooth 接続中にマイクキャプチャを行うと `HALC_ProxyIOContext::IOWorkLoop: skipping cycle due to overload` がコンソールに出る。
- 原因: Apple Silicon では BT 音声が Built-in 音声コントローラーを共有するため、別の音声ストリームを開くと BT SCO の 7.5ms タイミングが崩れる
- CoreAudio の transport type では検出不可（Apple Silicon は BT デバイスも `'bltn'` = BuiltIn で返る）
- AVAudioEngine / AVCaptureSession / AudioQueue すべてで発生。API レベルでの回避策なし
- **機能・音質への実害なし**と判断し許容。`AudioService.swift` の `startMicIfPermitted()` にコメントあり

### ScreenCaptureKit（スピーカー）
- 権限: System Settings → Privacy & Security → Screen Recording でON
- 開発中はXcodeリビルドのたびにTCC権限が失効することがある
  → `tccutil reset ScreenCapture com.yourname.macsystemmonitor` で再付与
- `SCShareableContent.current` 失敗時は3回リトライ（3秒間隔）後に諦める

### Swift 6 並行性
- オーディオコールバックスレッドから `Task { @MainActor ... }` を作ると abort
  → `OSAllocatedUnfairLock` でバッファ共有、タイマーでポーリング
- `nonisolated(unsafe)` は新しいSDKでは警告が出るが動作に影響なし

### Bluetooth（IOBluetooth）
- `NSBluetoothAlwaysUsageDescription` がInfo.plistに必要
- `IOBluetoothDevice.pairedDevices()` はMainActorで呼んで問題なし

### USB（IOKit）
- `IOUSBDevice` でデバイス列挙
- `idVendor` / `idProduct` で VID:PID取得（16進表示: `%04X:%04X`）

## ビルド

```
xcodebuild -project MacSystemMonitor.xcodeproj -scheme MacSystemMonitor -configuration Debug build
```
