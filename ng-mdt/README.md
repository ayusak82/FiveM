# ng-mdt - Police MDT System

警察職専用のMDT(Mobile Data Terminal)システムです。犯罪記録の作成・管理・検索が可能です。

## 機能

### 基本機能
- ✅ 記録作成（対応警察官・罪状・犯人・備考の入力）
- ✅ 履歴検索（複数条件による検索）
- ✅ 記録編集（警察職全員）
- ✅ 記録削除（ボスのみ）
- ✅ ページネーション対応（50件/ページ）
- ✅ 完全日本語対応

### 詳細機能
- **複数選択対応**: 対応警察官・罪状・犯人を複数選択可能
- **手動入力対応**: CitizenIDの手動入力（カンマ区切り）
- **罰金額自動計算**: 選択した罪状から自動計算
- **柔軟な検索**: 警察官・犯人・罪状・日付・備考での検索
- **プレイヤー表示**: `|サーバーID|名前|CitizenID|` 形式で表示

## 必要な依存関係

- **qb-core**: QBCore フレームワーク
- **ox_lib**: UI システム
- **oxmysql**: データベース接続

## インストール

### 1. ファイル配置
```
FiveMサーバー/resources/ng-mdt/
```
このフォルダを FiveMサーバーの `resources` フォルダに配置してください。

### 2. server.cfg 設定
```cfg
ensure qb-core
ensure ox_lib
ensure oxmysql
ensure ng-mdt
```

### 3. データベース
サーバー起動時に自動的に `ng-mdt` テーブルが作成されます。
手動で作成する場合は以下のSQLを実行してください：

```sql
CREATE TABLE IF NOT EXISTS `ng-mdt` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `officers` longtext DEFAULT NULL COMMENT 'JSON: 対応警察官リスト',
    `crimes` longtext DEFAULT NULL COMMENT 'JSON: 罪状リスト',
    `fine_amount` int(11) DEFAULT 0 COMMENT '一人当たりの罰金額',
    `criminals` longtext DEFAULT NULL COMMENT 'JSON: 犯人リスト',
    `notes` longtext DEFAULT NULL COMMENT '備考',
    `created_by` varchar(50) DEFAULT NULL COMMENT '作成者のCitizenID',
    `created_at` timestamp NULL DEFAULT current_timestamp(),
    `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

## 使用方法

### コマンド
```
/mdt
```
警察職のプレイヤーがこのコマンドを実行するとMDTメニューが開きます。

### Export（外部スクリプトから呼び出し）
```lua
-- MDTメニューを開く
exports['ng-mdt']:OpenMDT()
```

#### Radial Menuでの使用例
```lua
-- qb-radialmenu や他のラジアルメニューでの使用例
{
    id = 'police_mdt',
    title = 'MDT',
    icon = 'laptop',
    type = 'client',
    event = 'ng-mdt:client:openMDT',
    shouldClose = true
}
```

#### ox_target での使用例
```lua
exports.ox_target:addBoxZone({
    coords = vec3(441.5, -982.0, 30.69),
    size = vec3(1, 1, 1),
    options = {
        {
            name = 'mdt_computer',
            icon = 'fas fa-laptop',
            label = 'MDTを開く',
            canInteract = function()
                return QBCore.Functions.GetPlayerData().job.name == 'police'
            end,
            onSelect = function()
                exports['ng-mdt']:OpenMDT()
            end
        }
    }
})
```

## 権限設定

### MDTアクセス
- **条件**: `job.name == 'police'`
- **対象**: 警察職の全員

### 記録削除
- **条件**: `job.name == 'police'` かつ `job.grade.name == 'boss'`
- **対象**: 警察のボスのみ

## 設定

### shared/config.lua

#### コマンド変更
```lua
Config.Command = 'mdt'  -- コマンド名を変更可能
```

#### 罪状リスト編集
```lua
Config.Crimes = {
    { label = '罪状名', fine = 金額 },
    -- 追加・編集・削除が可能
}
```

#### 表示件数変更
```lua
Config.ResultsPerPage = 50  -- 1ページあたりの表示件数
```

#### ロケール変更
```lua
Config.Locale = {
    menu_title = 'MDTメニュー',
    -- その他のテキストも編集可能
}
```

## UI構造

### メインメニュー
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MDTメニュー
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
作成
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
履歴確認
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 記録作成
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
対応警察官（複数選択）
※オンライン警察官一覧 + 手動入力
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
罪状（複数選択）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
犯人（複数選択）
※オンライン全プレイヤー + 手動入力
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
備考（任意）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 履歴検索
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
警察官 CitizenID
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
犯人 CitizenID
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
罪状
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
開始日
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
終了日
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
備考
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 記録詳細
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
対応警察官
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
罪状
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
罰金額（一人あたり）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
犯人
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
備考
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
作成日時
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
編集 | 削除（ボスのみ）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## トラブルシューティング

### MDTが開かない
1. 警察職であることを確認
2. F8コンソールでエラーを確認
3. 依存関係（qb-core, ox_lib, oxmysql）が正しく起動しているか確認

### データベースエラー
1. oxmysql が正しく設定されているか確認
2. データベーステーブル `ng-mdt` が存在するか確認
3. サーバーコンソールでエラーログを確認

### 権限エラー
1. QBCore の job 設定を確認
2. ボス権限は `job.grade.name == 'boss'` で判定されます

## アップデート履歴

### Version 1.0.0
- 初回リリース
- 基本機能実装
- Export機能追加

## サポート

- **作者**: NCCGr
- **バージョン**: 1.0.0
- **ライセンス**: Escrow対応

## 注意事項

- このスクリプトは販売用に作成されています
- `shared/config.lua` 以外のファイルは escrow で保護されます
- 無断での再配布・改変は禁止です

## ライセンス

Copyright © 2024 NCCGr. All rights reserved.

このソフトウェアは販売用として提供されており、`shared/config.lua` を除くすべてのファイルは escrow で保護されています。