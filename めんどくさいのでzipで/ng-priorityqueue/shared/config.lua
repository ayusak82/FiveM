Config = {}

-- サーバー設定
Config.MaxPlayers = 128 -- 最大接続数
Config.QueueMessage = "キューに参加しています..." -- キュー待機中メッセージ
Config.ConnectingMessage = "サーバーに接続中..." -- 接続中メッセージ

-- Discord Bot設定
-- ⚠️ 重要: 以下の値を実際の値に変更してください
Config.DiscordBot = {
    Token = "YOUR_DISCORD_BOT_TOKEN_HERE", -- Discordボットのトークンをここに入力
    GuildId = "YOUR_DISCORD_SERVER_ID_HERE", -- DiscordサーバーIDをここに入力
}

-- 優先度設定（数値が高いほど優先度が高い）
-- ⚠️ 重要: 以下のロールIDを実際のDiscordロールIDに変更してください
Config.Priority = {
    [1] = {
        roles = {
            "ADMIN_ROLE_ID_1", -- 管理者ロール1のID
            "ADMIN_ROLE_ID_2", -- 管理者ロール2のID
        },
        priority = 100,
        name = "管理者"
    },
    [2] = {
        roles = {
            "VIP_PLAN_6_ROLE_ID", -- プラン6ロールのID
        },
        priority = 80,
        name = "プラン6"
    },
    [3] = {
        roles = {
            "VIP_PLAN_5_ROLE_ID", -- プラン5ロールのID
        },
        priority = 70,
        name = "プラン5"
    },
    [4] = {
        roles = {
            "VIP_PLAN_4_ROLE_ID", -- プラン4ロールのID
        },
        priority = 60,
        name = "プラン4"
    },
    [5] = {
        roles = {
            "VIP_PLAN_3_ROLE_ID", -- プラン3ロールのID
        },
        priority = 50,
        name = "プラン3"
    },
    [6] = {
        roles = {
            "VIP_PLAN_2_ROLE_ID", -- プラン2ロールのID
        },
        priority = 40,
        name = "プラン2"
    },
    [7] = {
        roles = {
            "VIP_PLAN_1_ROLE_ID", -- プラン1ロールのID
        },
        priority = 30,
        name = "プラン1"
    },
    [8] = {
        roles = {
            "CITIZEN_ROLE_ID", -- 市民ロールのID
        },
        priority = 1,
        name = "市民"
    }
}

-- UI設定
Config.UI = {
    QueueTitle = "優先キューシステム",
    QueueSubtitle = "サーバーへの接続をお待ちください",
    JoinQueueText = "キューに参加",
    LeaveQueueText = "キューから退出",
    PositionText = "現在の順番: %d位",
    EstimatedTimeText = "推定待機時間: %d分",
    PlayersInQueueText = "キュー内プレイヤー数: %d人",
    ConnectedPlayersText = "接続中プレイヤー数: %d/%d人"
}

-- デバッグ設定
Config.Debug = false -- デバッグメッセージの表示（初期設定時はtrueに変更推奨）

-- 接続間隔（ミリ秒）
Config.ConnectionInterval = 5000 -- 5秒ごとに接続チェック

-- キュー更新間隔（ミリ秒）
Config.QueueUpdateInterval = 3000 -- 3秒ごとにキュー情報更新

--[[
設定手順:
1. Discord Developer Portalでボットを作成
2. ボットトークンを取得してConfig.DiscordBot.Tokenに設定
3. DiscordサーバーのIDを取得してConfig.DiscordBot.GuildIdに設定
4. 各ロールのIDを取得してConfig.Priorityの各rolesに設定
5. Config.Debug = trueにして動作確認
6. 問題なければConfig.Debug = falseに戻す

ロールID取得方法:
1. Discordで開発者モードを有効化
2. 対象のロールを右クリック
3. 「IDをコピー」を選択
4. 取得したIDを該当箇所に貼り付け

セキュリティ注意:
- ボットトークンは絶対に他人に見せないでください
- このファイルをGitHubなどに公開する際は必ずトークンを削除してください
- ボットには最小限の権限のみ付与してください
--]]