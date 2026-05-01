# Audio 実装知見

## マイク（AudioQueue）

`AVAudioEngine` / `AVCaptureSession` は使わない。

- `AVAudioEngine.start()` を MainActor から呼ぶと AudioSession RootQueue で `_dispatch_assert_queue_fail` クラッシュ
- `AVCaptureSession` は音声のみでも CMIO カメラ拡張を列挙して `RebuildAudioConverter` エラーを出す

**現在の実装: `AudioQueueNewInput`**
- CMIO 非使用
- コールバックは AudioQueue 内部スレッドで動く
- 権限チェック: `AVCaptureDevice.authorizationStatus` → 未確定時のみ `requestAccess` を呼ぶ

## HALC overload（既知・許容済み）

Bluetooth 接続中にマイクキャプチャを行うと以下がコンソールに出る:
```
HALC_ProxyIOContext::IOWorkLoop: skipping cycle due to overload
```

- **原因**: Apple Silicon では BT 音声が Built-in 音声コントローラーを共有。別の音声ストリームを開くと BT SCO の 7.5ms タイミングが崩れる
- **検出不可**: CoreAudio の transport type では判別できない（Apple Silicon は BT デバイスも `'bltn'` = BuiltIn で返る）
- AVAudioEngine / AVCaptureSession / AudioQueue すべてで発生。API レベルの回避策なし
- **機能・音質への実害なし** → 許容。`AudioService.swift` の `startMicIfPermitted()` にコメントあり

## ScreenCaptureKit（スピーカー波形）

- 権限: System Settings → Privacy & Security → Screen Recording でON
- 開発中は Xcode リビルドのたびに TCC 権限が失効することがある
  ```bash
  tccutil reset ScreenCapture com.yourname.macsystemmonitor
  ```
- `SCShareableContent.current` 失敗時は3回リトライ（3秒間隔）後に諦める
