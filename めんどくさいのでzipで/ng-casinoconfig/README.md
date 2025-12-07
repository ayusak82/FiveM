rcore_casino 設定マネージャー
このスクリプトは、rcore_casinoの設定をゲーム内から簡単に切り替えることができるツールです。
機能

低設定、中設定、高設定の3種類のプリセットからカジノの設定を変更できます
権限を持つプレイヤーのみが設定を変更できます
コマンドで簡単に設定変更メニューを開くことができます
設定変更時は自動的にバックアップが作成されます

インストール方法

ng-casinoconfig フォルダをサーバーのリソースディレクトリに配置します
重要: rcore_casinoに必要なファイルを追加する必要があります

installフォルダにある backups をrcore_casino/に配置
installフォルダにあるngcasinoconf.lua ファイルを rcore_casino/server/ ディレクトリに配置します
rcore_casinoの fxmanifest.lua を開き、server_scripts セクションの一番下に以下の行を追加します

"server/ngcasinoconf.lua"


サーバーの server.cfg に以下の行を追加します:
コピーensure ng-casinoconfig

サーバーを再起動します

使用方法

カジノ管理者は /casinoconfig コマンドを入力して設定変更メニューを開きます
低設定、中設定、高設定から選択します
設定が適用され、全プレイヤーに通知が送信されます

権限設定
デフォルトでは、casino ジョブを持つプレイヤーのみが設定を変更できます。これは config.lua の Config.AuthorizedJobs で変更できます。
トラブルシューティング

設定が変更されない場合は、rcore_casinoに必要なファイルが正しく追加されているか確認してください
権限がない場合は、自分のジョブが Config.AuthorizedJobs に含まれているか確認してください
バックアップは rcore_casino/backups/ ディレクトリに保存されます

※configs,constsの中身は現在使用している物を張り付けて使用してください。
※現在のまま使用すると不具合が発生します！