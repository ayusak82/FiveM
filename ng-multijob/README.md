# ng-multijob

QBCore Framework用マルチジョブ管理システム

## 概要

ng-multijobは、QBCoreフレームワーク向けの高度なマルチジョブ管理システムです。プレイヤーは複数の職業を持つことができ、直感的なUIを通じて簡単に職業を切り替えることができます。

### 主な機能

- ox_libを使用したモダンなUI
- 複数の職業を同時に保持可能（デフォルトで最大3つ）
- ホワイトリスト職業のサポート（警察、救急隊、メカニックなど）
- 管理者用の包括的な職業管理システム
- ボス権限による従業員の雇用システム
- データベースによる永続的なジョブ保存
- 完全なエクスポート機能
- キーバインドとコマンドによるメニュー呼び出し

## 必要な依存関係

- qb-core
- ox_lib
- oxmysql

## インストール方法

1. このリソースを`resources`フォルダにコピー
2. `server.cfg`に以下の行を追加:
```cfg
ensure ox_lib
ensure ng-multijob
```

3. サーバー起動時に必要なデータベーステーブルが自動的に作成されます

## 設定

`config.lua`で以下の項目を設定できます:

```lua
-- 基本設定
Config.MaxJobs = 3 -- プレイヤーが持てる最大職業数
Config.WhitelistJobs = { -- 特殊職業（ホワイトリスト職業）の設定
    ['police'] = true,
    ['ambulance'] = true,
    ['mechanic'] = true
}
Config.DefaultJob = 'unemployed' -- デフォルトの職業
Config.DefaultGrade = 0 -- デフォルトの職業グレード

-- UI設定
Config.UI = {
    position = 'middle',
    icon = 'briefcase',
    commandName = 'jobs',
    keyBind = 'J'
}
```

## 使用方法

### プレイヤー向け機能
- `/jobs`コマンドまたは`J`キーで職業メニューを開く
- メニューから職業の確認、切り替えが可能
- 現在の職業、グレード、給与情報を確認可能
- 職業を辞める機能（デフォルト職業以外）

### 管理者向け機能
- 管理者は全プレイヤーの職業を管理可能
- オンラインプレイヤーリストまたはCitizenIDで対象を検索可能
- 職業の追加、削除、グレードの設定が可能
- プレイヤーの職業切り替えを強制可能

### ボス向け機能
- 従業員の雇用が可能
- サーバーIDまたはCitizenIDで対象を指定可能
- グレードを指定して雇用可能

## Exports

### サーバーサイド Exports

```lua
-- プレイヤーの全職業を取得
local jobs = exports['ng-multijob']:GetPlayerJobs(citizenid)

-- 職業を追加
local success, reason = exports['ng-multijob']:AddJob(citizenid, job, grade)

-- 職業を削除
local success, reason = exports['ng-multijob']:RemoveJob(citizenid, job)

-- 職業を切り替え
local success = exports['ng-multijob']:SwitchJob(source, citizenid, job)
```

### Export の使用例

```lua
-- プレイヤーの職業を取得
local function GetPlayerJobs(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {} end
    
    return exports['ng-multijob']:GetPlayerJobs(Player.PlayerData.citizenid)
end

-- 新しい職業を追加
local function AddNewJob(source, job, grade)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local success, reason = exports['ng-multijob']:AddJob(Player.PlayerData.citizenid, job, grade)
    return success, reason
end
```

## データベース構造

```sql
CREATE TABLE `ng_multijobs` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) NOT NULL,
    `job` varchar(50) NOT NULL,
    `grade` int(11) NOT NULL DEFAULT 0,
    `is_duty` tinyint(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_citizen_job` (`citizenid`, `job`),
    KEY `citizenid` (`citizenid`)
);
```

## 通知のカスタマイズ

`config.lua`の`Config.Notifications`セクションで、すべての通知メッセージをカスタマイズできます。

```lua
Config.Notifications = {
    ['error'] = {
        already_has_job = 'すでにこの職業を持っています',
        already_has_whitelist_job = 'すでに特殊職業を持っています',
        max_jobs_reached = '職業の上限に達しています',
        -- その他のメッセージ
    },
    ['success'] = {
        job_added = '職業が追加されました',
        job_removed = '職業が削除されました',
        job_switched = '職業を切り替えました'
        -- その他のメッセージ
    }
}
```

## デバッグ機能

開発時のトラブルシューティングを支援するデバッグ機能が含まれています。

```lua
Config.Debug = true -- config.luaでデバッグモードを有効化
```

デバッグモードでは以下の情報が出力されます：
- 職業情報の詳細なログ
- 給与計算のプロセス
- データベース操作の結果
- エラーメッセージの詳細

## ライセンス

このスクリプトは商用ライセンスで提供されています。再配布や改変は禁止されています。

## サポート

不具合や質問がある場合は、以下の方法でサポートを受けることができます。

Discord: ayusak