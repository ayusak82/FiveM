# ng-heavyarmor

FiveM用の重装備システムスクリプト  
ミニガンを装備した重装甲兵になることができます。

## 作者情報
- **作者**: NCCGr
- **問い合わせ先**: Discord: ayusak

## 特徴

- ✅ コマンドで重装備を装着・解除
- ✅ ミニガン自動装備
- ✅ 使用時間制限システム
- ✅ 体力・アーマー大幅増加
- ✅ ヘッドショット無効化
- ✅ ダメージ軽減システム
- ✅ 管理者権限チェック
- ✅ ox_lib UI使用
- ✅ 日本語対応
- ✅ CFX Escrow対応

## 必要な依存関係

- qb-core
- ox_lib

## インストール方法

1. `ng-heavyarmor` フォルダをサーバーの `resources` フォルダに配置
2. `server.cfg` に以下を追加:
```cfg
ensure ng-heavyarmor
```
3. サーバーを再起動

## 使用方法

### コマンド

- `/heavyarmor` - 重装備を装着/解除

**注意**: デフォルトでは管理者専用コマンドです

### 管理者権限の設定

`server.cfg` で管理者権限を設定:

```cfg
# 管理者権限付与
add_ace group.admin command.admin allow

# プレイヤーを管理者グループに追加（例）
add_principal identifier.steam:110000XXXXXXXX group.admin
add_principal identifier.license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx group.admin
```

## 機能詳細

### 重装備装着時の効果

1. **外見変更**
   - ジャガーノート風の重装備モデルに変更

2. **武器**
   - ミニガン自動装備
   - 無限弾薬

3. **ステータス強化**
   - 最大体力: 400（通常200）
   - 最大アーマー: 100
   - ダメージ軽減: 70%（受けるダメージが30%に）
   - ヘッドショット無効化

4. **制限**
   - 移動速度: 80%（重い装備のため）
   - 使用時間制限: 5分（設定可能）

### 使用時間制限

- デフォルト: 300秒（5分）
- 残り時間の通知:
  - 30秒ごと
  - 最後の10秒間は毎秒
- 時間切れで自動解除

### 安全機能

- プレイヤー死亡時に自動解除
- リソース停止時に自動解除
- 装着/解除時のプログレスバー表示

## 設定ファイル

`shared/config.lua` で以下の設定が可能です:

### 重装備設定
```lua
Config.HeavyArmor = {
    Duration = 300,              -- 使用時間（秒）
    PedModel = 's_m_y_blackops_01', -- モデル
    Weapon = 'WEAPON_MINIGUN',   -- 武器
    Ammo = 9999,                 -- 弾薬数
    MaxHealth = 400,             -- 最大体力
    MaxArmor = 100,              -- 最大アーマー
    DamageMultiplier = 0.3,      -- ダメージ軽減率
    HeadshotProtection = true,   -- ヘッドショット無効化
    MovementSpeed = 0.8,         -- 移動速度倍率
}
```

### コマンド設定
```lua
Config.Command = {
    Name = 'heavyarmor',    -- コマンド名
    AdminOnly = true,       -- 管理者専用
}
```

### UI設定
```lua
Config.UI = {
    EquipDuration = 3000,    -- 装備時間（ms）
    UnequipDuration = 2000,  -- 解除時間（ms）
    Position = 'top-right',  -- 通知位置
}
```

## 将来の拡張予定

- [ ] アイテム使用での装備機能
- [ ] ox_inventory連携
- [ ] クールダウンシステム
- [ ] 使用回数制限
- [ ] ログシステム

## トラブルシューティング

### コマンドが実行できない
- 管理者権限が正しく設定されているか確認
- `shared/config.lua` の `AdminOnly` 設定を確認

### 装備が解除されない
- `/heavyarmor` コマンドを再度実行
- サーバー再起動で強制解除

### モデルが表示されない
- ゲームキャッシュをクリア
- サーバーを再起動

### デバッグモード

`shared/config.lua` で有効化:
```lua
Config.Debug = true
```

F8コンソールでデバッグログを確認できます。

## ライセンス

このスクリプトは販売用です。  
無断での再配布・改変は禁止されています。

## サポート

問題が発生した場合は、Discordでお問い合わせください:
- Discord: ayusak

---

**Version**: 1.0.0  
**Last Updated**: 2024
