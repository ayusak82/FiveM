# ng-voicerecorder

FiveM 用のボイスレコーダーリソースです。
NUI（ブラウザ）で MediaRecorder を使ったローカル録音を行い、サーバーに保存してプレイヤーに配布できる仕組みを提供します。

## 📋 主な特徴

- ブラウザの MediaRecorder を使ったリアルタイム録音（NUI）
- 録音データをサーバーに保存し、データベース（MySQL）へメタデータを登録
- 録音済みテープアイテムを付与して、アイテムの情報（表示名 / systemId）を保持
- 再生はサーバー経由で近隣プレイヤーへ送信（距離で音量補正）
- qb-core の useable item と ox_inventory の両方に対応
- アップロード先 API を設定すれば外部サーバへアップロード可能（オプション）
- デバッグモード・デバッグコマンドあり

## 📦 依存関係（fxmanifest に定義）

- qb-core
- ox_lib
- oxmysql
- pma-voice

（上記がインストールされていることを確認してください）

## 🚀 インストール

1. リソースを `resources/[your-folder]/ng-voicerecorder` に配置します。

2. `server.cfg` にリソースを追加します：

```
ensure ng-voicerecorder
```

3. (任意) アイテムをインベントリに追加します。

qb-core での例（`qb-core/shared/items.lua`）:

```lua
voice_recorder = {
   name = 'voice_recorder',
   label = 'ボイスレコーダー',
   weight = 500,
   type = 'item',
   image = 'voice_recorder.png',
   unique = false,
   useable = true,
   shouldClose = true,
   description = '音声を録音できるデバイス'
},
empty_tape = {
   name = 'empty_tape',
   label = '空の録音テープ',
   weight = 50,
   type = 'item',
   image = 'empty_tape.png',
   unique = false,
   useable = false,
   shouldClose = true,
   description = '録音用の空テープ'
},
recorded_tape = {
   name = 'recorded_tape',
   label = '録音済みテープ',
   weight = 50,
   type = 'item',
   image = 'recorded_tape.png',
   unique = true,
   useable = true,
   shouldClose = true,
   description = '音声が録音されたテープ（説明文にテープ名が表示されます）'
},
```

ox_inventory での例（`ox_inventory/data/items.lua`）:

```lua
['voice_recorder'] = {
   label = 'ボイスレコーダー',
   weight = 500,
   stack = false,
   consume = 0,
   client = { export = 'ng-voicerecorder.useVoiceRecorder' }
},
['empty_tape'] = { label = '空の録音テープ', weight = 50, stack = true, consume = 0 },
['recorded_tape'] = { label = '録音済みテープ', weight = 50, stack = false, consume = 0, client = { export = 'ng-voicerecorder.useRecordedTape' } },
```

4. データベースにテーブルを作成します（例）:

```sql
CREATE TABLE IF NOT EXISTS ng_voicerecorder_recordings (
   id INT AUTO_INCREMENT PRIMARY KEY,
   system_id VARCHAR(50) UNIQUE NOT NULL,
   player_id INT NOT NULL,
   display_name VARCHAR(100) NOT NULL,
   file_path VARCHAR(255) NOT NULL,
   recorded_at DATETIME NOT NULL,
   duration INT NOT NULL,
   mime_type VARCHAR(50) DEFAULT 'audio/opus',
   file_size INT DEFAULT 0,
   created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## ⚙️ 設定（`shared/config.lua`）

主なデフォルト値:

- RecordingTime: 10
- PlaybackRange: 10.0
- FileRetentionDays: 30
- AudioQuality: "medium"
- RecordingsFolder: "recordings"
- Debug: false
- EnableDebugCommands: false

デバッグ用コマンド名（デフォルト）:

- TestRecorder: `testrecorder` (/testrecorder)
- GiveItems: `givevoiceitems` (/givevoiceitems)
- ClearRecordings: `clearrec` (/clearrec)

ローカルの `recordings/` フォルダに保存します。

## 🎮 使い方（プレイヤー向け）

1. インベントリで `voice_recorder` アイテムを使用するとメニューが開きます。
2. 録音する場合は空のテープ（`empty_tape`）が必要です。テープ名を入力すると NUI が開き、ブラウザ側で MediaRecorder による録音を行います。
3. 録音完了後、NUI からサーバーへ Base64 化した音声データを送信します。サーバーはファイル保存と DB 登録、アイテムの置き換え（空テープ -> 録音済みテープ）を行います。
4. 録音済みテープを使用するとサーバーが保存先を参照して近隣プレイヤーへ音声を送信します。クライアント側は `ng-voicerecorder:playAudioClient` を受け取り、NUI で再生します。

※ ブラウザ（NUI）による録音はプレイヤーのマイク許可が必要です。FiveM の NUI で録音を行うため、ブラウザ互換性にも依存します。

## イベント一覧（実装と一致）

クライアント → サーバー:
- `ng-voicerecorder:saveRecording` — NUI 経由で送られた録音データをサーバーに保存
- `ng-voicerecorder:playAudio` — 指定の systemId の再生をリクエスト

サーバー → クライアント:
- `ng-voicerecorder:useVoiceRecorder` — ボイスレコーダー使用トリガー（クライアント側でメニュー表示）
- `ng-voicerecorder:recordingComplete` — 録音の保存成功/失敗をクライアントへ通知
- `ng-voicerecorder:playAudioClient` — クライアントで音声データを受け取り再生するためのイベント

## 開発者向けメモ

- クライアント側の NUI は `html/index.html` と `html/script.js` を使用します。MediaRecorder を使って録音し、Blob を Base64 に変換してサーバへ送信します。
- サーバー側は `server/main.lua` で受信した Base64 をファイル化し、`recordings/` フォルダ（`Config.RecordingsFolder`）に保存します。保存成功後、空テープを削除して録音済みテープを付与します。
- アイテムのメタデータ (systemId, displayName 等) は qb-core では `item.info`、ox_inventory では `item.metadata` に格納されます。

## トラブルシューティング

- 録音が保存されない場合:
  - `recordings/` フォルダに書き込み権限があるか確認
  - `oxmysql` の接続設定を確認
  - `Config.Debug = true` にしてログを確認

- アイテムが動作しない場合:
  - アイテム定義が正しく追加されているか確認
  - ox_inventory を使う場合は client export 設定を確認

- 音声が再生されない場合:
  - ブラウザ側（NUI）でマイク許可が与えられているか確認
  - 対象プレイヤーが再生範囲内にいるか確認

## ライセンス

MIT ライセンス

---

**作成者**: NCCGr  
**バージョン**: 2.0.0  
**最終更新**: 2025年11月
