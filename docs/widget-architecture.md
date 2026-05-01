# ウィジェット構造

## ファイル構成

```
Views/
  ContentView.swift          — WidgetID 列挙、ドラッグ&ドロップ順序管理
  Widgets/
    WidgetCard.swift         — 共通カードコンテナ（折りたたみ・サマリー）
    CPUWidget.swift
    MemoryWidget.swift
    ...
```

## WidgetCard

```swift
struct WidgetCard<Content: View, Summary: View>: View
```

2つの init:
```swift
// サマリーあり
WidgetCard(title: "CPU", collapsedSummary: {
    Text("85.3%")
}) {
    // 展開時コンテンツ
}

// サマリーなし（Summary = EmptyView）
WidgetCard(title: "Foo") {
    // 展開時コンテンツ
}
```

- collapsed 時、ヘッダー右端に `collapsedSummary` を表示
- `@AppStorage("widget_collapsed_\(title)")` で折りたたみ状態を永続化
- `withAnimation(.easeInOut(duration: 0.2))` でトグル

## 各ウィジェットの collapsed サマリー

| ウィジェット | サマリー内容 |
|---|---|
| CPU | 総使用率 `%` |
| RAM | `used / total GB` |
| Storage | メインボリューム使用率 `%` |
| Battery | `charge% · Charging/AC/Discharging` |
| GPU | Device 使用率 `%` |
| Network | `↑upload ↓download` |
| Wi-Fi | SSID or `Disconnected` |
| Audio | `mic名 · speaker名` |
| Bluetooth | `N connected` |
| USB | `N devices` |
| Displays | メインディスプレイ解像度 |
| Thermal | ラベル（色付き） |

## WidgetID と順序管理

- `WidgetID: String, CaseIterable` — 全ウィジェットのID
- 順序は `UserDefaults("widget_order")` にカンマ区切りで保存
- `WidgetID.decode(_:)` — 保存文字列を復元、未知IDは末尾に追加
