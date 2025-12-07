Config = {}

-- 基本設定
Config.Command = 'dailybonus' -- デイリーボーナスを開くコマンド
Config.Locale = 'ja' -- 言語設定

-- Discord設定
Config.Discord = {
    enabled = false, -- Discord連携を有効にするか (false = 基本ボーナスのみ, true = ロールボーナスも表示)
    guildId = 'YOUR_GUILD_ID_HERE', -- DiscordサーバーID
    botToken = 'YOUR_DISCORD_BOT_TOKEN_HERE' -- Discordボットトークン
}

-- 基本デイリーボーナス（全プレイヤー対象）
Config.BasicBonus = {
    enabled = true,
    name = '基本デイリーボーナス',
    description = '毎日受け取れる基本ボーナスです',
    cooldown = 24, -- 時間（24時間 = 1日）
    rewards = {
        { item = 'plastic', amount = 150, label = 'プラスチック' },
        { item = 'glass', amount = 150, label = 'ガラス' },
        { item = 'aluminum', amount = 150, label = 'アルミニウム' },
        { item = 'copper', amount = 150, label = '銅' },
        { item = 'rubber', amount = 150, label = 'ゴム' },
        { item = 'steel', amount = 150, label = '鉄' },
        { item = 'metalscrap', amount = 150, label = '金属スクラップ' },
        { item = 'iron', amount = 150, label = '鉄鉱石' },
        { item = 'titanium', amount = 150, label = 'チタン' }
    }
}

-- Discord ロール別ボーナス
Config.RoleBonuses = {
    -- VIPロール (サンプル)
    {
        roleId = 'YOUR_VIP_ROLE_ID', -- DiscordロールID
        name = 'VIPボーナス',
        description = 'VIPメンバー限定の特別ボーナスです',
        cooldown = 24, -- 時間
        rewards = {
            { item = 'money', amount = 10000, label = '現金' },
            { item = 'lockpick', amount = 3, label = 'ロックピック' },
            { item = 'repairkit', amount = 1, label = '修理キット' }
        }
    },
    
    -- 管理者ロール (サンプル)
    {
        roleId = 'YOUR_ADMIN_ROLE_ID', -- DiscordロールID
        name = '管理者ボーナス',
        description = '管理者専用ボーナスです',
        cooldown = 24, -- 時間
        rewards = {
            { item = 'money', amount = 25000, label = '現金' },
            { item = 'diamond', amount = 5, label = 'ダイヤモンド' },
            { item = 'goldbar', amount = 3, label = '金の延べ棒' }
        }
    }
}

-- UI設定
Config.UI = {
    title = 'デイリーボーナス',
    subtitle = '毎日のボーナスを受け取ろう！',
    position = 'top-right'
}

-- 通知設定
Config.Notifications = {
    success = {
        title = 'デイリーボーナス',
        description = 'ボーナスを受け取りました！',
        type = 'success',
        duration = 5000
    },
    error = {
        title = 'エラー',
        type = 'error',
        duration = 3000
    },
    cooldown = {
        title = 'クールダウン中',
        description = 'まだ受け取ることができません',
        type = 'warning',
        duration = 3000
    }
}

-- デバッグモード
Config.Debug = false -- デバッグ情報を表示するか (テスト時は true に設定)