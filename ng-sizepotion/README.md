# ng-sizepotion

サイズ変更薬スクリプト - 小さくなる薬と大きくなる薬

## 説明

プレイヤーが薬を使用することで一時的に体のサイズを変更できるスクリプトです。
小さくなる薬で移動速度アップ＆被ダメージ増加、大きくなる薬で移動速度ダウン＆被ダメージ軽減など、
ゲームプレイに影響を与える効果を設定できます。

## 作者情報

- **作者**: NCCGr
- **問い合わせ先**: Discord: ayusak

## 機能

- 🔽 **小さくなる薬**: 体を小さくする（移動速度アップ、ジャンプ力アップ、被ダメージ増加）
- 🔼 **大きくなる薬**: 体を大きくする（移動速度ダウン、ジャンプ力ダウン、被ダメージ軽減）
- 💊 **解毒剤**: 効果を即座に解除
- ⚙️ **高度な設定**: スケール、効果時間、クールダウン、追加効果など細かく設定可能
- 🎬 **アニメーション**: 薬を飲むアニメーション付き
- ✨ **パーティクルエフェクト**: 変身時のエフェクト
- 🔊 **サウンドエフェクト**: 使用時・効果終了時のサウンド

## 依存関係

- [qb-core](https://github.com/qbcore-framework/qb-core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [okokNotify](https://okok.tebex.io/package/4724993)

## インストール方法

1. `ng-sizepotion` フォルダを `resources` ディレクトリに配置
2. `server.cfg` に `ensure ng-sizepotion` を追加
3. qb-core にアイテムを登録（下記参照）
4. `images`のpngを各インベントリのimageフォルダに追加
5. `shared/config.lua` で設定をカスタマイズ
6. サーバーを再起動

## qb-core アイテム登録

`qb-core/shared/items.lua` に以下を追加：

```lua
-- サイズ変更薬
shrink_potion            = { name = 'shrink_potion', label = '縮小薬', weight = 100, type = 'item', image = 'shrink_potion.png', unique = false, useable = true, shouldClose = true, combinable = nil, description = '体を小さくする不思議な薬' },
grow_potion              = { name = 'grow_potion', label = '巨大化薬', weight = 100, type = 'item', image = 'grow_potion.png', unique = false, useable = true, shouldClose = true, combinable = nil, description = '体を大きくする不思議な薬' },
size_antidote            = { name = 'size_antidote', label = 'サイズ解毒剤', weight = 50, type = 'item', image = 'size_antidote.png', unique = false, useable = true, shouldClose = true, combinable = nil, description = 'サイズ変更薬の効果を即座に解除する' },
```

## アイテム画像

`ox_inventory/web/images/` フォルダに以下の画像を追加してください：
- `shrink_potion.png`
- `grow_potion.png`
- `size_antidote.png`

## 設定項目

`shared/config.lua` で以下の設定が可能：

### 基本設定
- `Config.Debug` - デバッグモード（開発時はtrue）

### 薬の設定（shrink / grow）
- `item` - qb-coreのアイテム名
- `scale` - 変更後のスケール（0.3〜3.0）
- `duration` - 効果時間（秒）
- `cooldown` - クールダウン時間（秒）
- `useTime` - 使用にかかる時間（ミリ秒）
- `effects.speedBoost` - 移動速度倍率
- `effects.jumpBoost` - ジャンプ力倍率
- `effects.damageMultiplier` - 被ダメージ倍率

### 解毒剤設定
- `Config.Antidote.enabled` - 解毒剤の有効/無効
- `Config.Antidote.item` - アイテム名

### 制限設定
- `allowInVehicle` - 車両内での使用許可
- `cancelOnDeath` - 死亡時に効果解除
- `cancelOnVehicleEnter` - 車両乗車時に効果解除

## 使用方法

1. インベントリから薬を使用（右クリックまたはダブルクリック）
2. プログレスバー完了後に効果が適用
3. 設定した時間が経過すると自動的に元に戻る
4. 解毒剤を使用すると即座に元に戻る

## テスト用コマンド

アイテムをテスト用に付与するコマンド（管理者向け）：

```
/giveitem [player_id] shrink_potion 1
/giveitem [player_id] grow_potion 1
/giveitem [player_id] size_antidote 1
```

## 注意事項

- 効果中に車両に乗ると視点がおかしくなる場合があります
- 他のスケール変更スクリプトとの競合に注意してください
- スケール値を極端に設定すると不具合が発生する可能性があります

## ライセンス

このスクリプトはEscrow対応です。設定ファイルのみ編集可能です。

## サポート

問題や質問がある場合は、Discord（ayusak）までお問い合わせください。
