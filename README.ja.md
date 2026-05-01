# Peekr

Mac のシステムリソースをリアルタイム監視する、軽量な常時最前面フローティングウィジェット。各ウィジェットは折りたたみ・並べ替えに対応 — 必要なものだけ、好きな場所に。

[English](README.md)

<img src="images/image.png" alt="Peekr スクリーンショット" width="320">

## 機能

- **CPU** — 使用率・コア別負荷
- **Memory** — 使用量・圧縮・スワップ
- **Storage** — 空き容量・使用率
- **Battery** — 残量・充電状態・サイクル数
- **GPU** — 使用率
- **Network** — 送受信速度
- **Wi-Fi** — SSID・信号強度・チャンネル
- **Audio** — マイク波形・スピーカー波形・デバイス名
- **Bluetooth** — ペアリング済みデバイス・接続/切断操作
- **USB** — 接続デバイス一覧・VID:PID 表示
- **Display** — 解像度・リフレッシュレート・輝度
- **Thermal** — 温度状態（4 段階）

### その他
- 常時最前面フローティングウィンドウ
- 透明度スライダー (20〜100%)
- ウィジェット折りたたみ（折りたたみ時にヘッダーへサマリー表示、状態は再起動後も保持）
- ドラッグ＆ドロップでウィジェット順序変更（保持）
- メニューバーアイコンでウィンドウ表示/非表示

## 動作環境

- macOS 15.0 以降
- Apple Silicon (M1 以降)

## インストール

### Homebrew（推奨）

```bash
brew tap kazuhitogo/tap
brew install --cask peekr
```

### 手動

1. [Releases](https://github.com/kazuhitogo/mac-peekr/releases) から `Peekr.zip` をダウンロード
2. 解凍して `Peekr.app` を `/Applications` に移動
3. **初回起動時**: `Peekr.app` を右クリック → 開く → 開く（Gatekeeper 回避）

またはターミナルで:

```bash
xattr -cr /Applications/Peekr.app
```

### 権限

初回起動時に以下の権限を求める:

- **マイク** — マイク波形表示
- **画面収録** — スピーカー波形取得 (ScreenCaptureKit)

## ソースからビルド

```bash
git clone https://github.com/kazuhitogo/mac-peekr.git
cd mac-peekr
xcodebuild -project MacSystemMonitor.xcodeproj \
           -scheme MacSystemMonitor \
           -configuration Release \
           -derivedDataPath build build
```

## ライセンス

[Apache License 2.0](LICENSE)
