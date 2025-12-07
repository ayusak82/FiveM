# NG-ItemCreator - 統合アイテム管理システム

## 概要
FiveMサーバー向けの高機能アイテム作成・管理システムです。QB-CoreとOX-Inventoryの両方に対応し、直感的なUIでアイテムの追加・削除・カスタマイズが可能です。

## 主な機能

### ✨ 新機能
- **統合アイテムタイプ**: 1つの入力画面で全ての効果（満腹度・水分・ストレス）を設定可能
- **アニメーション選択**: Config設定から選択可能な8種類のアニメーション
- **プロップ選択**: Config設定から選択可能な15種類のプロップ
- **カスタム使用時間**: アイテム使用時間を個別に設定可能
- **権限管理**: ジョブとグレードによる詳細な権限管理
- **管理者メニュー削除**: よりシンプルなUI

### 🎮 基本機能
- QB-CoreとOX-Inventoryの両システムに自動対応
- ジョブ別のアイテム管理（プレフィックス自動付与）
- アイテムの追加・削除
- 自動バックアップ機能
- リアルタイムでのアイテム適用（再起動不要）

## ファイル構成

```
ng-itemcreator/
├── fxmanifest.lua
├── README.md
├── shared/
│   └── config.lua        # 設定ファイル
├── client/
│   └── main.lua          # クライアント処理
├── server/
│   └── main.lua          # サーバー処理
└── install/
    ├── qb/
    │   └── itemcreator.lua    # QB-Core用エクスポート
    └── ox/
        └── itemcreator.lua    # OX-Inventory用エクスポート
```

## インストール手順

### ステップ1: QB-Coreファイルの配置
1. `install/qb/itemcreator.lua` を `qb-core/server/itemcreator.lua` にコピー
2. qb-coreリソースを再起動

**注意**: QB-Coreはアイテムの基本情報のみを保存します。アニメーションやプロップの詳細情報はOX-Inventoryに保存されます。

### ステップ2: OX-Inventoryファイルの配置
1. `install/ox/itemcreator.lua` を `ox_inventory/server/itemcreator.lua` にコピー
2. ox_inventoryリソースを再起動

**注意**: OX-Inventoryにはアニメーション、プロップ、ステータス効果などの完全なアイテム情報が保存されます。

### ステップ3: メインリソースの配置
1. `ng-itemcreator` フォルダをサーバーの `resources` フォルダに配置
2. `server.cfg` に `ensure ng-itemcreator` を追加
3. ng-itemcreatorリソースを起動

## 設定ガイド

### Config.Limits - 入力値の制限設定

各パラメータの最小値・最大値・ステップ・デフォルト値を設定できます。

```lua
Config.Limits = {
    weight = {
        min = 1,           -- 最小重量
        max = 10000,       -- 最大重量
        step = 5,          -- スライダーのステップ
        default = 100      -- デフォルト値
    },
    hunger = {
        min = -100,        -- 満腹度の最小値
        max = 100,         -- 満腹度の最大値
        step = 1,
        default = 0
    },
    thirst = {
        min = -100,        -- 水分の最小値
        max = 100,         -- 水分の最大値
        step = 1,
        default = 0
    },
    stress = {
        min = -100,        -- ストレスの最小値
        max = 100,         -- ストレスの最大値
        step = 1,
        default = 0
    },
    usetime = {
        min = 0,           -- 使用時間の最小値（秒）
        max = 60,          -- 使用時間の最大値（秒）
        step = 1,
        default = 0
    }
}
```

### Config.AllowedJobs - 権限設定

アイテム作成権限を持つジョブとグレードを設定します。

```lua
Config.AllowedJobs = {
    ['police'] = 3,        -- 警察、階級3以上
    ['ambulance'] = 3,     -- 救急、階級3以上
    ['8052'] = 3,          -- カスタムジョブ
}
```

### Config.Animations - アニメーション設定

新しいアニメーションを追加できます。

```lua
Config.Animations = {
    ['アニメーション名'] = {
        label = '表示名',
        dict = 'アニメーション辞書名',
        clip = 'アニメーションクリップ名',
        flag = 49  -- アニメーションフラグ
    }
}
```

#### 既存のアニメーション
- なし
- 食べる（バーガー）
- 食べる（サンドイッチ）
- 飲む（ボトル）
- 飲む（カップ）
- 喫煙
- 薬を飲む
- 注射

### Config.Props - プロップ設定

新しいプロップを追加できます。

```lua
Config.Props = {
    ['プロップ名'] = {
        label = '表示名',
        model = 'プロップモデル名',
        bone = 18905,  -- ボーンID
        pos = vector3(0.13, 0.05, 0.02),  -- 位置
        rot = vector3(-50.0, 16.0, 60.0)  -- 回転
    }
}
```

#### 既存のプロップ
**食べ物**: バーガー、サンドイッチ、ホットドッグ、ドーナツ、ピザ
**飲み物**: 水のボトル、ビール瓶、ワイン瓶、コーヒーカップ、紙コップ
**その他**: タバコ、葉巻、注射器、錠剤

#### よく使用されるボーンID
- `18905` - 右手 (SKEL_R_Hand)
- `28422` - 左手 (SKEL_L_Hand)
- `47419` - 口 (SKEL_Head)

## 使用方法

### アイテムの作成
1. ゲーム内で `/createitem` コマンドを実行
2. 「アイテムの追加」を選択
3. 必要な情報を入力:
   - **アイテム名**: ジョブプレフィックスが自動追加されます
   - **表示名**: インベントリに表示される名前
   - **スタック可能**: チェックボックスで選択
   - **重量**: スライダーで設定（グラム単位）
   - **説明文**: アイテムの説明
   - **画像URL**: `https://gazou1.dlup.by/` ドメインのみ許可
   - **満腹度回復量**: 0で効果なし
   - **水分回復量**: 0で効果なし
   - **ストレス減少量**: 0で効果なし
   - **アニメーション**: ドロップダウンから選択
   - **プロップ**: ドロップダウンから選択
   - **使用時間**: 0でデフォルト時間を使用（秒単位）

### アイテムの削除
1. `/createitem` コマンドを実行
2. 「アイテムの削除」を選択
3. 削除したいアイテムを選択
4. 確認ダイアログで「削除する」をクリック

### アイテムタイプの自動判定
- すべての効果が0の場合: **通常アイテム**（消費不可）
- 満腹度が0でない場合: **食べ物**（消費可能）
- 水分が0でない場合: **飲み物**（消費可能）
- ストレスが0でない場合: **ストレス軽減**（消費可能）

## Export関数

### QB-Core側 (qb-core)
```lua
-- アイテムを追加
exports['qb-core']:addItem(items)

-- アイテムを削除
exports['qb-core']:removeItem(itemName)

-- アイテムの存在確認
exports['qb-core']:itemExists(itemName)

-- アイテム一覧取得
exports['qb-core']:getItems()
```

### OX-Inventory側 (ox_inventory)
```lua
-- アイテムを追加
exports['ox_inventory']:addItem(items)

-- アイテムを削除
exports['ox_inventory']:removeItem(itemName)

-- アイテムの存在確認
exports['ox_inventory']:itemExists(itemName)

-- アイテム一覧取得
exports['ox_inventory']:getItems()
```

## 動作確認

### 正常起動時のログ
```
[QB-Core ItemCreator] QB-Core用アイテム管理システムが読み込まれました
[OX-Inventory ItemCreator] OX-Inventory用アイテム管理システムが読み込まれました
[NG-ItemCreator] Export版として起動しました
[NG-ItemCreator] QB-Core export接続成功
[NG-ItemCreator] OX-Inventory export接続成功
```

## トラブルシューティング

### よくある問題

#### 1. Export関数が見つからない
**原因**: itemcreator.luaが正しく配置されていない
**解決方法**: 
- `qb-core/server/itemcreator.lua` が存在するか確認
- `ox_inventory/server/itemcreator.lua` が存在するか確認
- 対象リソースを再起動

#### 2. アイテムが表示されない
**原因**: リソースの読み込み順序の問題
**解決方法**:
- QB-CoreとOX-Inventoryが先に起動していることを確認
- ng-itemcreatorを再起動

#### 3. 権限エラー
**原因**: Config.AllowedJobsに設定されていないジョブ
**解決方法**:
- `shared/config.lua` のAllowedJobsに該当ジョブを追加
- グレード設定を確認

#### 4. 画像URLエラー
**原因**: 許可されていないドメインを使用
**解決方法**:
- `https://gazou1.dlup.by/` ドメインのURLを使用

#### 5. ファイル書き込み権限エラー
**原因**: サーバーの実行権限不足
**解決方法**:
- FiveMサーバーの実行権限を確認
- ファイルの読み書き権限を確認

### デバッグモード
クライアント・サーバーの両方でデバッグフラグが設定されています:
```lua
local debug = true  -- falseにすると詳細ログを無効化
```

## セキュリティ

### 実装されているセキュリティ機能
- ジョブとグレードによる権限チェック
- アイテム名のバリデーション（英数字のみ）
- URL検証（指定ドメインのみ許可）
- ジョブプレフィックスによる所有権管理
- サーバー側での二重チェック

### 注意事項
- アイテム削除は取り消せません
- 他のジョブが作成したアイテムは削除できません
- 画像URLは信頼できるソースのみを使用してください

## カスタマイズ例

### 新しいアニメーションの追加
```lua
Config.Animations['カスタムアニメ'] = {
    label = 'カスタムアニメーション',
    dict = 'your_anim_dict',
    clip = 'your_anim_clip',
    flag = 49
}
```

### 新しいプロップの追加
```lua
Config.Props['カスタムプロップ'] = {
    label = 'カスタムプロップ',
    model = 'prop_custom_01',
    bone = 18905,
    pos = vector3(0.13, 0.05, 0.02),
    rot = vector3(-50.0, 16.0, 60.0)
}
```

### 重量制限の変更
```lua
Config.Limits.weight = {
    min = 1,
    max = 50000,  -- 最大50kg
    step = 10,
    default = 500
}
```

## 更新履歴

### v2.0.0 - 最新版
- アニメーションとプロップの選択機能追加
- Config.Limitsによる値制限のカスタマイズ対応
- 統合アイテムタイプシステム実装
- 管理者メニューの削除

### v1.5.0
- Export方式への移行
- QB-CoreとOX-Inventory両対応
- 自動バックアップ機能

### v1.0.0
- 初回リリース

## ライセンス・サポート

### 作成者
NG Development Team

### サポート
問題が発生した場合は、以下の情報を添えてお問い合わせください:
- サーバーコンソールのログ
- F8コンソールのエラーメッセージ
- 使用しているQB-CoreとOX-Inventoryのバージョン

## 今後の予定機能
- [ ] アイテムプレビュー機能
- [ ] バルクインポート/エクスポート
- [ ] アイテムテンプレート機能
- [ ] 詳細なアイテム統計
