# GTA5 アイテムサウンドシステム

アイテム使用時にサウンドエフェクト、アニメーション、ステータス効果を追加するFiveM用リソースです。QBCoreフレームワーク用に作られています。

## 主な機能

- アイテム使用時のカスタムサウンド再生
- 全プレイヤーに同期されたサウンド再生
- アイテム使用時のアニメーション対応
- ステータス効果システム（体力、アーマー、食料、水分）
- 段階的または即時の回復効果
- 特殊効果（自殺、炎上）
- 設定可能な遅延時間とサウンドの伝播距離

## 必要なリソース

- qb-core
- xsound

## インストール方法

1. リソースをダウンロード
2. サーバーのresourcesフォルダに配置
3. server.cfgに以下を追加:
```
ensure qb-core
ensure xsound
ensure ng-sound
```

## 設定方法

### ベースURL設定
`config.lua`で、サウンドファイルのホスティングURLを設定します：
```lua
Config.BaseUrl = 'https://your-sound-hosting-url/'
```

### アイテムの設定
アイテムは`config.lua`で設定できます。設定例：

```lua
Config.Items = {
    ['アイテム名'] = {
        url = 'sound.mp3',            -- サウンドファイルのパス
        volume = 0.8,                 -- 音量 (0.0 - 1.0)
        maxDistance = 10.0,           -- サウンドが聞こえる最大距離
        soundDelay = 3000,            -- サウンド再生までの遅延時間（ミリ秒）
        loop = false,                 -- ループ再生の有無
        removeAfterUse = true,        -- 使用後にアイテムを削除するか
        
        -- アニメーション設定
        animation = {
            dict = 'アニメーション辞書',
            anim = 'アニメーション名',
            flag = 49,
            duration = 2800           -- 継続時間（ミリ秒）
        },
        
        -- エフェクト設定
        effect = {
            type = 'suicide',         -- 'suicide'（自殺）または'fire'（炎上）
            delay = 3000,             -- エフェクト発動までの遅延（ミリ秒）
            duration = 10000          -- 炎上の場合の継続時間（ミリ秒）
        },
        
        -- 回復効果設定
        recovery = {
            health = 0,               -- 体力の変化量
            armour = 0,               -- アーマーの変化量
            food = 0,                 -- 食料の変化量
            water = 0,                -- 水分の変化量
            time = 5000,              -- 回復までの時間（ミリ秒）
            isInstant = true,         -- true: 即時回復, false: 段階的回復
            gradualTick = 500         -- 段階的回復の場合の間隔（ミリ秒）
        }
    }
}
```

## 使用方法

### アイテムの使用
アイテムはQB-Coreのインベントリシステムを通じて使用できます。使用時の動作：
1. 設定されたアニメーションの再生
2. サウンドエフェクトの再生（ローカルおよび近くのプレイヤーに同期）
3. 設定されたステータス効果の適用
4. `removeAfterUse`が`true`の場合、アイテムの削除

### サウンドエフェクト
- xsoundリソースを使用してサウンドを再生
- 設定された`maxDistance`内の全プレイヤーがサウンドを聞くことが可能
- 音源からの距離に応じて音量が減衰
- `soundDelay`による遅延再生に対応

### 回復効果
2種類の回復効果をサポート：
1. 即時回復：設定された遅延後に変更が適用
2. 段階的回復：設定された間隔で徐々に変更が適用

### 特殊効果
- 自殺：設定された遅延後にプレイヤーの体力を0に設定
- 炎上：設定された時間だけプレイヤーを炎上させる

## 開発者向け情報

### イベントシステム
このリソースは以下のイベントを使用します：

クライアント側：
- `ng-sound:useItem`: アイテム使用時にトリガー
- `ng-sound:client:playSound`: ユーザー用のサウンド再生
- `ng-sound:client:playSoundFromCoord`: 特定の座標からのサウンド再生

サーバー側：
- `ng-sound:server:updateMetadata`: プレイヤーのメタデータ更新
- `ng-sound:server:useItem`: アイテム使用の処理
- `ng-sound:server:playSound`: サウンド再生の同期

# ox_inventory設定方法
['sample'] = {
    label = 'サンプル',
    weight = 2000,
    stack = false,
    close = true,
    description = '',
    client = {
        event = 'ng-sound:useItem',  -- このイベントを絶対に付けてください
    }
},

## ライセンス

このリソースはMITライセンスの下で提供されています。

## 作者

NCCGr