# ng-cargo - FiveM 貨物輸送システム

航空貨物輸送ジョブスクリプト - レベルシステム、ランダムイベント、ランキング機能を備えた本格的な配送システム

## 📋 目次

- [特徴](#-特徴)
- [必要要件](#-必要要件)
- [インストール](#-インストール)
- [設定](#-設定)
- [使い方](#-使い方)
- [レベルシステム](#-レベルシステム)
- [報酬システム](#-報酬システム)
- [ランダムイベント](#-ランダムイベント)
- [コマンド](#-コマンド)
- [データベース](#-データベース)
- [トラブルシューティング](#-トラブルシューティング)
- [更新履歴](#-更新履歴)

## ✨ 特徴

- **3段階の難易度システム** - 簡単/普通/難しい (1〜3箇所の配送先)
- **レベルシステム** - 経験値とレベルに応じた報酬倍率 (最大レベル50で2倍)
- **レベルアップ報酬** - 特定レベル到達時にボーナス報酬
- **時間ボーナス** - 制限時間の70%以内に完了で追加報酬
- **ランダムイベント** - 25%の確率で特殊イベント発生
- **複数目的地配送** - 最大3箇所への連続配送
- **統計・ランキングシステム** - 総配送回数、収入、最速記録などを記録
- **ルーティングバケット** - プレイヤーごとに独立したインスタンス
- **QBCore統合** - ox_lib、ox_inventory対応

## 📦 必要要件

- [QBCore Framework](https://github.com/qbcore-framework)
- [ox_lib](https://github.com/overextended/ox_lib)
- [oxmysql](https://github.com/overextended/oxmysql)
- MySQL/MariaDBデータベース

### 推奨
- ox_inventory (アイテム報酬の表示用)

## 🔧 インストール

### 1. リソースのインストール

```bash
# サーバーのresourcesフォルダに配置
cd resources/[qb]
git clone [your-repo-url] ng-cargo
# または手動でフォルダをコピー
```

### 2. データベーステーブルの作成

スクリプトは初回起動時に自動的にテーブルを作成しますが、手動で作成する場合:

```sql
CREATE TABLE IF NOT EXISTS cargo_stats (
    identifier VARCHAR(50) PRIMARY KEY,
    total_deliveries INT DEFAULT 0,
    successful_deliveries INT DEFAULT 0,
    total_earned INT DEFAULT 0,
    experience INT DEFAULT 0,
    level INT DEFAULT 1,
    best_time INT DEFAULT 0,
    last_delivery TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### 3. server.cfg に追加

```cfg
ensure ng-cargo
```

### 4. アイテムの追加 (オプション)

`qb-core/shared/items.lua` にアイテムを追加:

```lua
-- 既存のアイテムを使用する場合は不要
['money']         = {['name'] = 'money',         ['label'] = '現金',      ['weight'] = 0,    ['type'] = 'item', ['image'] = 'money.png',      ['unique'] = false, ['useable'] = false, ['shouldClose'] = false, ['combinable'] = nil, ['description'] = '現金'},
['plastic']       = {['name'] = 'plastic',       ['label'] = 'プラスチック', ['weight'] = 100,  ['type'] = 'item', ['image'] = 'plastic.png',    ['unique'] = false, ['useable'] = false, ['shouldClose'] = false, ['combinable'] = nil, ['description'] = 'プラスチック'},
['glass']         = {['name'] = 'glass',         ['label'] = 'ガラス',     ['weight'] = 100,  ['type'] = 'item', ['image'] = 'glass.png',      ['unique'] = false, ['useable'] = false, ['shouldClose'] = false, ['combinable'] = nil, ['description'] = 'ガラス'},
-- 以下同様...
```

## ⚙️ 設定

### shared/config.lua

#### 基本設定

```lua
Config.Debug = false -- デバッグモード (true/false)

-- NPC受注場所
Config.NPCLocation = {
    coords = vector4(-956.48, -2918.93, 13.96, 151.75), -- LSIA貨物エリア
    model = 's_m_m_pilot_02',
    scenario = 'WORLD_HUMAN_CLIPBOARD'
}

-- 車両スポーン位置
Config.VehicleSpawn = {
    coords = vector4(-975.74, -2977.44, 13.95, 58.21),
    model = 'titan' -- 使用する航空機のモデル
}

-- 帰還場所
Config.ReturnLocation = vector3(-956.48, -2918.93, 13.96)
Config.ReturnRadius = 50.0 -- 帰還判定の半径
```

#### 目的地の追加/編集

```lua
Config.Destinations = {
    {
        name = '軍事基地',
        coords = vector3(-1828.03, 2974.82, 32.81),
        difficulty = 'hard',
        distance = 5800 -- メートル
    },
    -- 目的地を追加...
}
```

#### 難易度設定

```lua
Config.Difficulties = {
    easy = {
        label = '簡単 (1箇所配送)',
        destinations = 1,        -- 配送先の数
        timeLimit = 600,         -- 制限時間 (秒)
        baseReward = 50000,      -- 基本報酬
        experience = 50,         -- 経験値
        timeBonus = 10000,       -- 時間ボーナス
        unloadCount = 3          -- 荷下ろし回数
    },
    -- normal, hard も同様
}
```

#### 報酬アイテムの設定

```lua
Config.Rewards = {
    items = {
        {name = 'money', amount = 100000, type = 'item'},
        {name = 'plastic', amount = 50, type = 'item'},
        {name = 'glass', amount = 50, type = 'item'},
        -- アイテムを追加/削除可能
    },
    
    -- レベルボーナス倍率
    levelBonus = {
        [1] = 1.0,   -- レベル1: 100%
        [5] = 1.1,   -- レベル5: 110%
        [10] = 1.2,  -- レベル10: 120%
        [15] = 1.3,
        [20] = 1.5,
        [30] = 1.7,
        [50] = 2.0   -- レベル50: 200%
    }
}
```

#### レベルシステム

```lua
Config.LevelSystem = {
    experiencePerLevel = 500, -- レベルアップに必要な経験値
    maxLevel = 50,
    
    -- レベルアップ報酬
    levelUpRewards = {
        [5] = {money = 100000, message = 'レベル5到達ボーナス!'},
        [10] = {money = 250000, message = 'レベル10到達ボーナス!'},
        [20] = {money = 500000, message = 'レベル20到達ボーナス!'},
        [30] = {money = 1000000, message = 'レベル30到達ボーナス!'},
        [50] = {money = 2500000, message = 'レベル50(最大)到達ボーナス!'}
    }
}
```

#### ランダムイベント

```lua
Config.RandomEvents = {
    enabled = true,
    chance = 25, -- 発生確率 (%)
    
    events = {
        {
            name = '追加荷物',
            description = '追加の貨物が見つかりました!',
            rewardMultiplier = 1.3,
            extraUnloads = 2
        },
        {
            name = '緊急配送',
            description = '緊急配送依頼です!',
            rewardMultiplier = 1.5,
            timeReduction = 120 -- 制限時間-2分
        },
        {
            name = 'VIP貨物',
            description = 'VIP貨物の配送です!',
            rewardMultiplier = 2.0,
            experienceMultiplier = 1.5
        }
    }
}
```

## 🎮 使い方

### プレイヤー向け

1. **ジョブの開始**
   - LSIA（ロスサントス国際空港）の貨物エリアにいるNPCに近づく
   - Eキーでメニューを開く
   - 難易度を選択 (簡単/普通/難しい)

2. **配送の実行**
   - 航空機でスポーンする
   - GPS/マップに表示される目的地に向かう
   - 目的地に到着したら航空機を着陸
   - Eキーで荷下ろしを実行（複数回）
   - 複数の目的地がある場合は次の目的地へ

3. **ジョブの完了**
   - 全ての配送が完了したら空港に帰還
   - 帰還エリアに入ると自動的にジョブ完了
   - 報酬と統計情報が表示される

4. **ジョブのキャンセル**
   - メニューから「ジョブをキャンセル」を選択
   - または航空機が破壊されると自動的に失敗

### 報酬の計算例

```
基本報酬: 50,000円
配送先数: 3箇所 → x2.0倍 = 100,000円
時間ボーナス: 10,000円 (70%以内に完了)
ランダムイベント: x1.5倍 = 165,000円
レベルボーナス: レベル50 → x2.0倍 = 330,000円

最終報酬: 330,000円 + アイテム
```

## 📊 レベルシステム

### 経験値とレベルアップ

- **経験値取得**: ジョブ完了時に取得
- **レベルアップ**: 500経験値ごとにレベルアップ
- **最大レベル**: レベル50

### レベルボーナス倍率

| レベル | 報酬倍率 | 効果 |
|--------|----------|------|
| 1-4    | 1.0x     | 100% |
| 5-9    | 1.1x     | 110% |
| 10-14  | 1.2x     | 120% |
| 15-19  | 1.3x     | 130% |
| 20-29  | 1.5x     | 150% |
| 30-49  | 1.7x     | 170% |
| 50     | 2.0x     | 200% |

### レベルアップ報酬

| レベル | 報酬金額 |
|--------|----------|
| 5      | $100,000 |
| 10     | $250,000 |
| 20     | $500,000 |
| 30     | $1,000,000 |
| 50     | $2,500,000 |

## 💰 報酬システム

### 報酬の種類

1. **現金報酬**
   - 基本報酬
   - 時間ボーナス
   - イベントボーナス
   - レベルボーナス

2. **アイテム報酬** (Config設定による)
   - money (現金)
   - plastic (プラスチック)
   - glass (ガラス)
   - aluminum (アルミニウム)
   - copper (銅)
   - rubber (ゴム)
   - steel (鋼鉄)
   - metalscrap (金属スクラップ)
   - iron (鉄)
   - titanium (チタン)

3. **経験値**
   - ジョブ完了で取得
   - イベント発生時は1.5倍

### 配送先数ボーナス

- **1箇所**: 1.0倍
- **2箇所**: 1.5倍
- **3箇所**: 2.0倍

## 🎲 ランダムイベント

### イベント発生

- **発生確率**: 25%
- **発生タイミング**: ジョブ開始時

### イベントの種類

1. **追加荷物**
   - 報酬: 1.3倍
   - 荷下ろし回数: +2回

2. **緊急配送**
   - 報酬: 1.5倍
   - 制限時間: -2分

3. **VIP貨物**
   - 報酬: 2.0倍
   - 経験値: 1.5倍

## 🎯 ランキングシステム

### ランキングカテゴリー

1. **総配送回数** - 完了した配送の総数
2. **総収入** - 獲得した報酬の総額
3. **レベル** - 現在のレベル
4. **最速記録** - 最も速く完了した時間

### ランキングの確認

- NPCメニューから「ランキングを見る」を選択
- トップ10のプレイヤーが表示される

## 🔧 コマンド

### プレイヤーコマンド

現在、プレイヤー用のチャットコマンドはありません。全てNPCメニューから操作します。

### 管理者コマンド

**注意**: `Config.AdminGroups` に設定されたグループのみ使用可能

```lua
/cargostats <citizenid>
```
指定したプレイヤーの統計情報を表示

```lua
/cargoresetstats <citizenid>
```
指定したプレイヤーの統計をリセット

```lua
/cargoresetall
```
全プレイヤーの統計をリセット

```lua
/cargogivexp <citizenid> <amount>
```
指定したプレイヤーに経験値を付与

```lua
/cargosetlevel <citizenid> <level>
```
指定したプレイヤーのレベルを設定

### デバッグコマンド

`Config.Debug = true` の場合のみ使用可能

```lua
/cargodebug
```
アクティブなジョブとバケット情報を表示

```lua
/cargogeneratedata <count>
```
テスト用のランダムデータを生成

## 💾 データベース

### テーブル構造

```sql
cargo_stats
├── identifier (VARCHAR(50)) - citizenid (主キー)
├── total_deliveries (INT) - 総配送回数
├── successful_deliveries (INT) - 成功した配送回数
├── total_earned (INT) - 総収入
├── experience (INT) - 経験値
├── level (INT) - レベル
├── best_time (INT) - 最速記録 (秒)
├── last_delivery (TIMESTAMP) - 最終配送日時
├── created_at (TIMESTAMP) - 作成日時
└── updated_at (TIMESTAMP) - 更新日時
```

### データベースクエリ例

```sql
-- 全プレイヤーの統計を確認
SELECT * FROM cargo_stats ORDER BY level DESC, experience DESC;

-- トップ配送者を確認
SELECT * FROM cargo_stats ORDER BY successful_deliveries DESC LIMIT 10;

-- 特定プレイヤーの統計を確認
SELECT * FROM cargo_stats WHERE identifier = 'ABC12345';

-- プレイヤーの統計をリセット
UPDATE cargo_stats SET 
    total_deliveries = 0,
    successful_deliveries = 0,
    total_earned = 0,
    experience = 0,
    level = 1,
    best_time = 0
WHERE identifier = 'ABC12345';
```

## 🔍 トラブルシューティング

### よくある問題

#### 1. NPCが表示されない

**原因**: リソースが正しく起動していない

**解決方法**:
```bash
# F8コンソールで確認
ensure ng-cargo

# サーバーコンソールでログを確認
```

#### 2. ジョブが開始できない

**原因**: 
- 既にジョブ中
- QBCoreが正しく読み込まれていない

**解決方法**:
- メニューから「ジョブをキャンセル」を試す
- サーバーを再起動
- `Config.Debug = true` でログを確認

#### 3. レベルアップ報酬がもらえない

**原因**: スクリプトのバグ（修正済み）

**解決方法**:
- 最新版のスクリプトを使用
- `server/main.lua` を最新版に更新

#### 4. 報酬が2倍にならない

**原因**: レベルボーナス計算のバグ（修正済み）

**解決方法**:
- `GetLevelBonusMultiplier` 関数が修正されているか確認
- デバッグモードでログを確認

#### 5. 航空機が消える

**原因**: ルーティングバケットの問題

**解決方法**:
```lua
-- Config.lua で無効化
Config.RoutingBucket = {
    enabled = false
}
```

#### 6. データベースエラー

**原因**: テーブルが作成されていない

**解決方法**:
```sql
-- 手動でテーブルを作成
CREATE TABLE IF NOT EXISTS cargo_stats (
    identifier VARCHAR(50) PRIMARY KEY,
    total_deliveries INT DEFAULT 0,
    successful_deliveries INT DEFAULT 0,
    total_earned INT DEFAULT 0,
    experience INT DEFAULT 0,
    level INT DEFAULT 1,
    best_time INT DEFAULT 0,
    last_delivery TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### デバッグモード

`Config.Debug = true` に設定すると、詳細なログが出力されます:

```lua
[ng-cargo] Player X moved to bucket Y
[ng-cargo] Level check - Old: X, New: Y, XP: Z
[ng-cargo] Level X reward given: $Y
[ng-cargo] Level X bonus multiplier: Y.Xx
[ng-cargo] Added item: X xY to player Z
[ng-cargo] Stats updated for ABC12345: Level X, XP Y
```

## 📝 更新履歴

### v1.1.0 (修正版)

**修正**:
- レベルアップ報酬が正しく付与されない問題を修正
- レベル50での報酬倍率が適用されない問題を修正
- 複数レベルアップ時に全ての報酬が付与されるように改善
- デバッグログの追加

**変更**:
- `GetLevelBonusMultiplier` 関数の最適化
- レベルアップ判定ロジックの改善

### v1.0.0 (初版)

**機能**:
- 基本的な貨物輸送システム
- 3段階の難易度
- レベルシステム
- ランダムイベント
- 統計・ランキング機能

## 🤝 サポート

### 問題が発生した場合

1. `Config.Debug = true` に設定してログを確認
2. サーバーコンソールとF8コンソールのエラーメッセージを確認
3. データベーステーブルが正しく作成されているか確認
4. 必要要件が全てインストールされているか確認

### 推奨設定

```lua
-- 安定動作のための推奨設定
Config.Debug = false
Config.RoutingBucket.enabled = true
Config.RandomEvents.enabled = true
Config.RandomEvents.chance = 25
```

## 📄 ライセンス

このスクリプトは個人・商用利用可能です。再配布する場合は、クレジット表記をお願いします。

## 🎉 クレジット

- 開発: ng-cargo Team
- QBCore Framework
- ox_lib
- FiveM Community

---

**注意**: このREADMEは修正版 (v1.1.0) に基づいています。古いバージョンを使用している場合は、最新版への更新を推奨します。
