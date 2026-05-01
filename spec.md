# Mac System Monitor 仕様書

## 概要

| 項目 | 値 |
|---|---|
| アプリ名 | Mac System Monitor |
| 対象OS | macOS 15.0+ (Apple Silicon必須) |
| スタック | Swift 6 + SwiftUI + Combine |
| 配布 | App Store (サンドボックス有効) |

---

## 画面構成

メインウィンドウ1枚。グリッドレイアウト。

```
┌─────────────────────────────────────────────────┐
│  Mac System Monitor         [透過スライダー] [⤢] │
├──────────┬──────────┬──────────┬────────────────┤
│   CPU    │   RAM    │ Storage  │    Battery     │
│  折れ線  │  積み上げ │   棒    │   円+数値      │
├──────────┴──────────┼──────────┴────────────────┤
│       GPU           │        Network             │
│  チップ名/コア数    │   ↑↓ 速度 + 累積          │
├─────────────────────┴───────────────────────────┤
│              Displays                            │
│  [内蔵 2560×1664] [PHL 4K×2]                   │
├──────────┬──────────┬──────────┬────────────────┤
│  Accel   │   Gyro   │ Compass  │    Thermal     │
│  X/Y/Z   │  X/Y/Z   │   方位°  │   4段階状態   │
└──────────┴──────────┴──────────┴────────────────┘
```

---

## ウィンドウ

- **常時最前面**: `NSWindow.level = .floating`
- **透過**: `NSWindow.isOpaque = false` + `backgroundColor = .clear`
- **透過度**: ツールバーのスライダーで 20〜100% 調整
- **背景**: `NSVisualEffectView` (`.hudWindow` マテリアル) でデスクトップに馴染む半透明
- **タイトルバー**: 非表示 (`NSWindow.styleMask = .borderless` + カスタムドラッグ領域)
- **リサイズ**: 可、最小 600×400
- **最小化/フルスクリーン**: 無効

---

## ウィジェット仕様

### CPU
- **取得API**: `host_statistics64()` → `host_cpu_load_info`
- **表示**:
  - 折れ線グラフ（直近60秒分、セッション内メモリのみ）
  - user / sys / idle %（数値）
  - チップ名・コア数: `sysctlbyname("machdep.cpu.brand_string")`
- **更新**: 1秒

### RAM
- **取得API**: `host_statistics64()` → `vm_statistics64`
- **表示**:
  - 積み上げ棒: Used / Wired / Compressed / Free
  - 単位: GB（小数1桁）
  - スワップ in/out 累積値
- **更新**: 1秒

### Storage
- **取得API**: `URL.resourceValues(forKeys:)` → `volumeAvailableCapacityForImportantUsageKey` / `volumeTotalCapacityKey`
- **表示**:
  - マウント済みボリューム自動列挙
  - 各ボリューム: 横棒グラフ + 使用/空き GB
  - 内蔵SSD・外付け区別表示
- **更新**: 10秒

### Battery
- **取得API**: `IOPSCopyPowerSourcesInfo()` / `IOPSGetPowerSourceDescription()`
- **表示**:
  - 残量% (円グラフ)
  - 充電中 / 放電中 / AC接続
  - サイクル数
  - 最大容量%
  - 状態 (Normal / Service Recommended 等)
- **更新**: 30秒

### GPU
- **取得API**: `MTLCreateSystemDefaultDevice()` → `MTLDevice`
- **表示**:
  - チップ名
  - コア数 (`registryID` 経由)
  - Metal世代
  - 推奨最大バッファサイズ
- **更新**: 起動時1回のみ（静的情報）

### Network
- **取得API**: `getifaddrs()` → `ifi_data` (if_data) でバイトカウンタ差分計算
- **表示**:
  - インターフェース別 (en0/en1 等)
  - ↑送信 / ↓受信 瞬間速度 (KB/s or MB/s 自動切換)
  - セッション累積転送量
- **更新**: 1秒

### Displays
- **取得API**: `NSScreen.screens`
- **表示**:
  - 接続枚数
  - 各ディスプレイ: 名前・解像度・リフレッシュレート・主画面フラグ
- **更新**: イベント駆動 (`NSApplicationDidChangeScreenParametersNotification`)

### Accel / Gyro / Compass
- **取得API**: `CoreMotion.CMMotionManager`
- **表示**:
  - 加速度: X / Y / Z (g単位)
  - ジャイロ: X / Y / Z (rad/s)
  - コンパス: 方位角° + 方向ラベル (N/NE/E...)
- **更新**: 0.1秒 (10Hz)
- **エンタイトルメント**: `NSMotionUsageDescription` 必須

### Thermal (温度状態)
- **取得API**: `ProcessInfo.processInfo.thermalState` (公開API、サンドボックスOK)
- **表示**:
  - 4段階インジケーター: Nominal(緑) / Fair(黄) / Serious(橙) / Critical(赤)
  - 状態変化通知: `ProcessInfo.thermalStateDidChangeNotification`
- **更新**: イベント駆動
- **備考**: 実温度(°C)はApp Storeサンドボックス制約で取得不可

---

## 更新間隔まとめ

| ウィジェット | 間隔 |
|---|---|
| CPU / RAM / Network | 1秒 |
| Storage | 10秒 |
| Battery | 30秒 |
| Motion sensors | 0.1秒 |
| GPU | 起動時1回 |
| Displays / Thermal | イベント駆動 |

---

## データ永続化

**なし**。全データはセッション内メモリのみ。グラフ履歴もアプリ終了で破棄。

---

## エンタイトルメント

```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
<key>NSMotionUsageDescription</key>
<string>加速度・ジャイロ・コンパスの表示に使用します</string>
```

---

## 非機能要件

- アイドル時CPU使用率 < 1%
- メモリ使用量 < 50MB
- ダークモード自動対応
- Hardened Runtime有効
- Privacy Manifest (PrivacyInfo.xcprivacy) 必須

---

## 対象外

- メニューバー常駐（スコープ外）
- 温度実数値（サンドボックス制約）
- データ履歴・エクスポート
- プロセス一覧
