Config = {}

-- コマンド設定
Config.Command = 'magic' -- 魔法メニューを開くコマンド

-- 管理者のみ使用可能にするか
Config.AdminOnly = false -- true = 管理者のみ, false = 全員使用可能

-- 魔法のクールダウン時間(ミリ秒)
Config.CooldownTime = 5000 -- 5秒

-- 魔法の設定
Config.Spells = {
    {
        id = 'heal',
        label = 'ヒールマジック',
        description = '体力を回復します',
        icon = 'heart',
        healAmount = 50, -- 回復量
        cooldown = 10000, -- 個別クールダウン(ミリ秒)
        adminOnly = false
    },
    {
        id = 'teleport',
        label = 'テレポート',
        description = '前方にテレポートします',
        icon = 'location-arrow',
        distance = 10.0, -- テレポート距離
        cooldown = 15000,
        adminOnly = false
    },
    {
        id = 'fireball',
        label = 'ファイアボール',
        description = '炎のエフェクトを発射します',
        icon = 'fire',
        cooldown = 8000,
        adminOnly = false
    },
    {
        id = 'invisible',
        label = 'インビジブル',
        description = '透明になります',
        icon = 'eye-slash',
        duration = 10000, -- 持続時間(ミリ秒)
        cooldown = 30000,
        adminOnly = false
    },
    {
        id = 'speed',
        label = 'スピードブースト',
        description = '移動速度が上昇します',
        icon = 'running',
        duration = 15000,
        speedMultiplier = 1.5, -- 速度倍率
        cooldown = 20000,
        adminOnly = false
    },
    {
        id = 'jump',
        label = 'スーパージャンプ',
        description = 'ジャンプ力が上昇します',
        icon = 'arrow-up',
        duration = 10000,
        cooldown = 15000,
        adminOnly = false
    },
    {
        id = 'night_vision',
        label = 'ナイトビジョン',
        description = '暗闇でも見えるようになります',
        icon = 'moon',
        duration = 20000,
        cooldown = 25000,
        adminOnly = false
    },
    {
        id = 'armor',
        label = 'マジックアーマー',
        description = 'アーマーを回復します',
        icon = 'shield',
        armorAmount = 50,
        cooldown = 12000,
        adminOnly = false
    }
}

-- 通知設定
Config.Notifications = {
    cooldown = {
        title = '魔法システム',
        description = 'まだ使用できません。残り時間: %s秒',
        type = 'error',
        duration = 3000
    },
    success = {
        title = '魔法システム',
        description = '%sを使用しました',
        type = 'success',
        duration = 3000
    },
    adminOnly = {
        title = '魔法システム',
        description = 'この魔法は管理者のみ使用できます',
        type = 'error',
        duration = 3000
    },
    noPermission = {
        title = '魔法システム',
        description = '権限がありません',
        type = 'error',
        duration = 3000
    }
}
