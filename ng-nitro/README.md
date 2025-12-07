# 改造版ニトロシステム - インストールガイド

## 主な変更点

### 1. エフェクト削除
- ニトロ使用時の炎エフェクトを完全に削除
- サウンドエフェクトも削除
- よりシンプルなブーストシステムに変更

### 2. アイテムベースシステム
- コマンドによる取り付けを廃止
- アイテム使用による取り付けシステムに変更
- より現実的なロールプレイ体験を提供

### 3. Job制限システム
- ニトロキット取り付けはメカニック職のみ可能
- ニトロボトル装着は誰でも可能
- configで許可する職業を設定可能

## 必要なアイテム

### ニトロインストールキット (`nitrous_installkit`)
- **用途**: 車両にニトロシステムを取り付ける
- **使用条件**: メカニック職のみ
- **重量**: 500
- **使用方法**: 車両に乗った状態でアイテムを使用

### ニトロボトル (`nitrous3`)
- **用途**: ニトロタンクを補充する
- **使用条件**: 誰でも使用可能
- **重量**: 200
- **使用方法**: 車両に乗った状態でアイテムを使用

## インストール手順

### 1. ファイルの配置
```
ng-nitro/
├── fxmanifest.lua
├── shared/
│   └── config.lua (改造版)
├── client/
│   └── main.lua (改造版)
└── server/
    └── main.lua (改造版)
```

### 2. アイテムの追加
`qb-core/shared/items.lua` に以下のアイテムを追加：

```lua
['nitrous_installkit'] = {
    name = 'nitrous_installkit',
    label = 'ニトロインストールキット',
    weight = 500,
    type = 'item',
    image = 'nitrous_installkit.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = '車両にニトロシステムを取り付けるためのキット。メカニック専用。',
},

['nitrous3'] = {
    name = 'nitrous3',
    label = 'ニトロボトル',
    weight = 200,
    type = 'item',
    image = 'nitrous3.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'ニトロシステムに燃料を補給するためのボトル。車両に乗った状態で使用してください。',
},
```

### 3. アイテム画像の追加
- `qb-inventory/html/images/` フォルダに画像ファイルを追加
  - `nitrous_installkit.png`
  - `nitrous3.png`

### 4. 設定の調整
`shared/config.lua` で以下の設定を調整可能：

```lua
-- 許可する職業
Config.Permissions = {
    allowedJobs = {
        'mechanic',     -- メカニック
        'cardealer',    -- 車販売員
        -- 'tuner',     -- チューナー
        -- 'bennys',    -- ベニーズ
    }
}

-- ニトロ設定
Config.Nitro = {
    boostForce = 50.0,          -- ブースト力
    boostDuration = 3000,       -- 持続時間（ミリ秒）
    boostCooldown = 5000,       -- クールダウン（ミリ秒）
    maxTanks = 5,               -- 最大タンク数
    tankUsagePerBoost = 1,      -- 1回の使用で消費するタンク数
    tanksPerBottle = 1,         -- 1本のボトルで追加されるタンク数
}
```

## 使用方法

### 1. ニトロキットの取り付け
1. メカニック職のプレイヤーが `nitrous_installkit` を入手
2. 取り付けたい車両に乗車
3. インベントリから `nitrous_installkit` を使用
4. システムが自動的に取り付けられる

### 2. ニトロボトルの装着
1. 任意のプレイヤーが `nitrous3` を入手
2. ニトロキットが取り付けられた車両に乗車
3. インベントリから `nitrous3` を使用
4. タンクが補充される

### 3. ニトロの使用
1. ニトロキット装着済みの車両に運転席で乗車
2. 左シフトキーを押してニトロを発動
3. タンクが消費される

## 管理コマンド

### `/checknitro`
- 現在の車両のニトロ状態を確認
- 誰でも使用可能

### `/removenitro`
- 車両からニトロを削除（管理者専用）
- admin権限が必要

### `/debugnitro`
- デバッグ情報を表示
- コンソールにデータを出力

## トラブルシューティング

### アイテムが使用できない
- QBCoreのアイテムが正しく登録されているか確認
- サーバーを再起動してみる

### ニトロが発動しない
- 車両にニトロキットが取り付けられているか確認
- タンクが空でないか確認
- 運転席に座っているか確認

### Job制限が機能しない
- プレイヤーの職業が正しく設定されているか確認
- configの `allowedJobs` に職業名が含まれているか確認

## 依存関係

- **qb-core**: QBCore Framework
- **ox_lib**: UI通知用
- **oxmysql**: データベース接続用

## サポート

問題が発生した場合は、`Config.Debug = true` に設定してコンソールログを確認してください。