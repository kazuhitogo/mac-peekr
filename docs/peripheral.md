# Peripheral 実装知見

## Bluetooth（IOBluetooth）

- `NSBluetoothAlwaysUsageDescription` が Info.plist に必要
- `IOBluetoothDevice.pairedDevices()` は MainActor で呼んで問題なし
- 接続/切断: `IOBluetoothDevice.openConnection()` / `closeConnection()`

## USB（IOKit）

- `IOUSBDevice` でデバイス列挙
- `idVendor` / `idProduct` で VID:PID 取得
- 表示フォーマット: `String(format: "%04X:%04X", vid, pid)`
