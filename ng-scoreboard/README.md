# ng-scoreboard - スコアボードシステム

FiveM用のシンプルで機能的なスコアボードシステムです。プレイヤー情報、ジョブ統計、強盗条件などを表示します。

## 特徴

- リアルタイムプレイヤー情報表示
- ジョブ別プレイヤー数統計
- サーバー再起動時間のカウントダウン
- 強盗実行可能条件の表示（警察人数）
- プレイヤー名変更機能
- 電話番号表示
- 通報機能（警察への通報）
- カスタマイズ可能な設定

## 作者情報

- **作者**: NCCGr
- **問い合わせ先**: Discord: ayusak
- **バージョン**: 1.0.0

## 依存関係

以下のリソースが必要です：

- [qb-core](https://github.com/qbcore-framework/qb-core) - QBCoreフレームワーク
- [ox_lib](https://github.com/overextended/ox_lib) - UIライブラリ
- [oxmysql](https://github.com/overextended/oxmysql) - MySQLライブラリ

## インストール方法

1. `ng-scoreboard` フォルダをサーバーの `resources` ディレクトリに配置
2. `server.cfg` に以下を追加：
```cfg
ensure qb-core
ensure ox_lib
ensure oxmysql
ensure ng-scoreboard
```
3. サーバーを再起動

## 使用方法

### 基本操作

1. ゲーム内で `HOME` キーを押してスコアボードを開く
2. スコアボードには以下の情報が表示されます：
   - 現在のプレイヤー数 / 最大プレイヤー数
   - 次回サーバー再起動までの時間
   - ジョブ別プレイヤー数
   - プレイヤーリスト（名前、ジョブ、電話番号）
   - 強盗実行可能条件

### プレイヤー名変更機能

1. スコアボードを開く
2. 自分の名前の横にある「名前変更」ボタンをクリック
3. 新しい名前を入力
4. 確定すると、データベースの`players`テーブルの`name`カラムが更新されます

### 通報機能

1. スコアボードを開く
2. 他のプレイヤーの横にある「通報」ボタンをクリック
3. 警察に通報が送信されます

## 設定

`shared/config.lua` で以下の設定をカスタマイズできます：

### 基本設定
```lua
Config.OpenKey = 'HOME'              -- スコアボードを開くキー
Config.PoliceJobName = 'police'      -- 警察の職業名
```

### サーバー再起動時間
```lua
Config.ServerRestartTimes = {
    "00:00",
    "03:00",
    "06:00",
    "09:00",
    "12:00",
    "15:00",
    "18:00",
    "21:00",
}
```

### ジョブ設定
```lua
Config.Jobs = {
    {name = "運営", jobName = "admin"},
    {name = "警察", jobName = "police"},
    {name = "医者", jobName = "ambulance"},
    -- 追加のジョブ...
}
```

### 強盗設定
```lua
Config.Robberies = {
    {
        name = "店舗強盗",
        requiredPolice = 2  -- 必要な警察人数
    },
    -- 追加の強盗...
}
```

## データベース

このスクリプトは以下のテーブルを使用します：

### players テーブル
- `citizenid`: プレイヤーのCitizen ID
- `name`: プレイヤーの表示名（名前変更機能で更新）

### phone_phones テーブル（オプション）
- `owner_id`: プレイヤーのCitizen ID
- `phone_number`: 電話番号

## 機能詳細

### プレイヤー名変更
- データベースの`players`テーブルの`name`カラムを直接更新
- 3文字以上50文字以下の制限
- 不適切な文字（`<>$;`）のチェック
- 変更後は全プレイヤーのスコアボードが自動更新

### 通報機能
- 警察職のプレイヤーに通報を送信
- 通報者の情報と位置を含む
- 警察が0人の場合は通知

### 再起動時間表示
- 複数の再起動時間に対応
- 次回の再起動時間と残り時間を自動計算
- カウントダウン形式で表示

## トラブルシューティング

### スコアボードが開かない
- `HOME` キーが他のスクリプトと競合していないか確認
- F8コンソールでエラーメッセージを確認

### プレイヤー名が変更できない
- データベース接続を確認
- `players`テーブルに`name`カラムが存在するか確認
- 名前の長さと文字制限を確認

### 電話番号が表示されない
- `phone_phones`テーブルが存在するか確認
- テーブル構造が正しいか確認（`owner_id`, `phone_number`カラム）

### 依存関係エラー
- `qb-core`, `ox_lib`, `oxmysql` が正しくインストールされているか確認
- `server.cfg` で依存関係が `ng-scoreboard` より前に読み込まれているか確認

## カスタマイズ

### UIのカスタマイズ
`html/style.css` でスタイルをカスタマイズできます。

### 新しいジョブの追加
`shared/config.lua` の `Config.Jobs` に追加：
```lua
{name = "表示名", jobName = "job_id"}
```

### 新しい強盗の追加
`shared/config.lua` の `Config.Robberies` に追加：
```lua
{
    name = "強盗名",
    requiredPolice = 必要警察人数
}
```

## ライセンス

このスクリプトは販売用です。無断での再配布や改変は禁止されています。

## サポート

問題や質問がある場合は、Discord: ayusak までお問い合わせください。
