# ng-shooting-range

射撃練習用スクリプトです。指定した範囲内にランダムにNPCをスポーンさせ、プレイヤーが制限時間内に撃つことでスコアを獲得できます。

## 作者情報
- **作者**: NCCGr
- **問い合わせ先**: Discord: ayusak

## 主要機能

### 射撃練習システム
- 指定範囲内にランダムな位置でNPCを出現
- NPCは2秒間のみ存在し、撃たれなければ自動デスポーン
- 命中部位と反応時間によってスコアを算出
- 開始時にスポーンさせるNPC数を指定可能（5〜50体）

### スコアリングシステム
- **部位別スコア**:
  - ヘッドショット: 100ポイント
  - 胴体: 50ポイント
  - その他: 25ポイント

- **タイムボーナス**:
  - 0.5秒以内: +50ポイント
  - 1.0秒以内: +30ポイント
  - 1.5秒以内: +10ポイント
  - 2.0秒以内: +0ポイント

### UI機能
- 練習開始メニュー（ox_lib）
- リアルタイムスコア表示
- 結果画面（合計スコア、命中率、平均反応時間）

## 依存関係

### 必須
- [qb-core](https://github.com/qbcore-framework/qb-core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [okokNotify](https://okok.tebex.io/package/4724993)

## インストール方法

1. `ng-shooting-range` フォルダをサーバーの `resources` フォルダに配置
2. `server.cfg` に以下を追加:
```cfg
ensure ng-shooting-range
```
3. サーバーを再起動

## 設定方法

`shared/config.lua` で以下の設定が可能です:

### 射撃場の追加・編集
```lua
Config.ShootingRanges = {
    {
        name = "LSPD射撃場",
        interactionPoint = vector3(11.29, -1097.77, 29.8),
        spawnArea = {
            point1 = vector2(5.0, -1105.0),
            point2 = vector2(17.0, -1105.0),
            point3 = vector2(17.0, -1112.0),
            point4 = vector2(5.0, -1112.0),
            minZ = 29.5,
            maxZ = 31.0
        },
        heading = 0.0,
        blip = {
            enabled = true,
            sprite = 313,
            color = 1,
            scale = 0.8
        }
    }
}
```

### ゲーム設定
```lua
Config.GameSettings = {
    npcModel = "a_m_y_skater_01",  -- NPCモデル
    npcLifetime = 2000,             -- NPC生存時間（ミリ秒）
    minTargets = 5,                 -- 最小ターゲット数
    maxTargets = 50,                -- 最大ターゲット数
    defaultTargets = 10             -- デフォルトターゲット数
}
```

### スコア設定
```lua
Config.Scoring = {
    bodyParts = {
        head = 100,    -- ヘッドショット
        torso = 50,    -- 胴体
        other = 25     -- その他
    },
    timeBonus = {
        { time = 0.5, bonus = 50 },
        { time = 1.0, bonus = 30 },
        { time = 1.5, bonus = 10 },
        { time = 2.0, bonus = 0 }
    }
}
```

## 使用方法

1. 射撃場の緑色のマーカーに近づく
2. `[E]` キーを押して練習を開始
3. ターゲット数（5〜50）を入力
4. ランダムにスポーンするNPCを撃つ
5. 全てのターゲットを撃ち終えると結果が表示される

## デバッグモード

開発時には `shared/config.lua` で以下を設定:
```lua
Config.Debug = true
```

デバッグメッセージはサーバーコンソールとF8コンソールに表示されます。

## トラブルシューティング

### NPCがスポーンしない
- スポーンエリアの座標が正しいか確認
- デバッグモードを有効にしてエラーメッセージを確認
- NPCモデルが有効か確認

### スコアが正しく計算されない
- デバッグモードで命中部位を確認
- Config.Scoringの設定を確認

### マーカーが表示されない
- 射撃場の座標に近づいているか確認
- Config.GameSettings.markerDrawDistanceを増やす

## 今後の拡張予定

- 複数の難易度設定
- リーダーボード機能
- 武器制限機能
- 移動ターゲット
- マルチプレイヤーモード

## ライセンス

このスクリプトは販売用です。無断での再配布や改変は禁止されています。

## サポート

問題や質問がある場合は、Discord: ayusak までお問い合わせください。
