# ng-shoppingcart

FiveM用の乗れるショッピングカートスクリプト

## 📝 概要

プレイヤーがコマンドでショッピングカートをスポーンし、乗車・回収できるスクリプトです。

## ✨ 機能

- コマンドでショッピングカートをスポーン
- スポーンしたカートに乗車可能
- 降車後に回収(削除)可能
- 1人1台までの制限機能
- 速度制限設定
- 日本語対応UI

## 📋 必要な依存関係

- [qb-core](https://github.com/qbcore-framework/qb-core)
- [ox_lib](https://github.com/overextended/ox_lib)

## 📦 インストール方法

1. `ng-shoppingcart` フォルダを `resources` ディレクトリに配置
2. `server.cfg` に以下を追加:
```cfg
ensure ng-shoppingcart
```
3. サーバーを再起動

## 🎮 使用方法

### コマンド
- `/cart` - ショッピングカートをスポーン

### 操作方法
1. `/cart` コマンドでカートをスポーン
2. スポーンしたカートに近づいて乗車
3. 降車後、カートに近づいて `[E]` キーで回収

## ⚙️ 設定

`shared/config.lua` で以下の設定が可能です:

### 基本設定
- `Config.Command` - スポーンコマンド名 (デフォルト: 'cart')
- `Config.CartModel` - カートモデル (デフォルト: 'prop_rub_trolley01a')

### スポーン設定
- `Config.SpawnDistance` - スポーン距離 (デフォルト: 2.5m)
- `Config.MaxCartsPerPlayer` - 1人あたりの最大カート数 (デフォルト: 1)

### カート設定
- `Config.CartSpeed` - 最大速度 km/h (0 = 制限なし)

### インタラクション設定
- `Config.InteractDistance` - 相互作用距離 (デフォルト: 2.5m)
- `Config.InteractKey` - 回収キー (デフォルト: 38 = E)

### 表示設定
- `Config.DrawDistance` - 3Dテキスト表示距離 (デフォルト: 10.0m)
- `Config.TextFont` - フォント (0 = 日本語対応)
- `Config.TextScale` - テキストサイズ (デフォルト: 0.35)

## 🔧 カスタマイズ

### カートモデルの変更

`shared/config.lua` で別のカートモデルに変更可能:

```lua
Config.CartModel = 'prop_rub_trolley03a' -- 別のカートモデル
```

利用可能なモデル例:
- `prop_rub_trolley01a` (デフォルト)
- `prop_rub_trolley03a`
- `prop_cs_trolly_01`

### 速度制限の変更

```lua
Config.CartSpeed = 20.0 -- 20km/hに制限
Config.CartSpeed = 0 -- 制限なし
```

## 📄 ライセンス

このスクリプトは販売用です。
無断での再配布・改変・販売は禁止されています。

## 👤 作者情報

- **作者**: NCCGr
- **問い合わせ**: Discord - ayusak

## 🐛 バグ報告・サポート

問題が発生した場合は、Discordでお問い合わせください。

Discord: ayusak

## 📌 注意事項

- このスクリプトはエスクロー保護されています
- `shared/config.lua` のみ編集可能です
- サーバーのパフォーマンスに影響を与えないよう最適化されています

## 🔄 更新履歴

### Version 1.0.0
- 初回リリース
- 基本的なショッピングカート機能実装
- スポーン・回収システム実装
- 速度制限機能実装
