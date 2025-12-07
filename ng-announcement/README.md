# ng-announcement

FiveM QBCore用の職業別お知らせシステムスクリプトです。
各職業がゲーム内でお知らせを出せるようになります。

## 作者情報

- **作者**: NCCGr
- **問い合わせ**: Discord: ayusak

## 機能

- 職業別のお知らせ送信
- 職業ごとに色とアイコンをカスタマイズ可能
- モダンなHTML/CSS UIデザイン
- 効果音付きの通知表示
- 15秒間の表示（設定変更可能）
- クールダウン機能で連続投稿を制限
- qb-radialmenu との連携対応
- Export機能で他スクリプトからの呼び出し可能

## 依存関係

- [qb-core](https://github.com/qbcore-framework/qb-core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [okokNotify](https://okok.tebex.io/package/4724080) （通知表示用）
- [qb-radialmenu](https://github.com/qbcore-framework/qb-radialmenu) （オプション）

## インストール

1. `ng-announcement` フォルダを `resources` ディレクトリに配置
2. `server.cfg` に以下を追加:
   ```
   ensure ng-announcement
   ```
3. サーバーを再起動

## 使用方法

### コマンド
```
/announce
```
お知らせ入力UIを開きます。

### qb-radialmenu
radial menuに「お知らせ」オプションが自動で追加されます。

### Export（他スクリプトから呼び出し）

**クライアント側:**
```lua
-- お知らせUIを開く
exports['ng-announcement']:openAnnouncementUI()
```

**サーバー側:**
```lua
-- 直接お知らせを送信
exports['ng-announcement']:sendAnnouncement('police', '山田太郎', 'お知らせ内容')
```

## 設定 (shared/config.lua)

### 基本設定

```lua
Config.Debug = false           -- デバッグモード
Config.DisplayDuration = 15000 -- 表示時間（ミリ秒）
Config.Command = 'announce'    -- コマンド名
Config.Cooldown = 30           -- クールダウン（秒）
Config.MaxLength = 200         -- 最大文字数
```

### 職業設定

```lua
Config.Jobs = {
    ['police'] = {
        color = '#3498db',              -- 表示色（HEX）
        icon = 'fa-solid fa-shield-halved', -- FontAwesomeアイコン
        label = '警察'                  -- 表示名
    },
    -- 他の職業を追加...
}
```

### デフォルト職業設定
設定に含まれていない職業の場合に使用されます。

```lua
Config.DefaultJob = {
    color = '#95a5a6',
    icon = 'fa-solid fa-bullhorn',
    label = '一般'
}
```

## プレビュー

### お知らせ表示例

```
┌─────────────────────────────────────┐
│ 🛡️ 警察の山田太郎からのお知らせ     │
├─────────────────────────────────────┤
│ お知らせ内容がここに表示されます。   │
│                                     │
├─────────────────────────────────────┤
│ ████████████████░░░░░░░░ 15:30     │
└─────────────────────────────────────┘
```

## キーボードショートカット

- **ESC**: UIを閉じる
- **Ctrl + Enter**: お知らせを送信

## ライセンス

このスクリプトは販売用として作成されています。
無断転載・再配布は禁止です。

## サポート

問題や質問がある場合は、Discord (ayusak) までお問い合わせください。
