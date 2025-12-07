Config = {}

-- デバッグモード（本番環境ではfalseに設定）
Config.Debug = false

-- サイズ変更薬の設定
Config.Potions = {
    -- 小さくなる薬
    shrink = {
        item = 'shrink_potion',      -- アイテム名（qb-coreに登録するアイテム名）
        scale = 0.5,                  -- 変更後のスケール（0.1〜1.0）
        duration = 60,                -- 効果時間（秒）
        cooldown = 10,                -- クールダウン時間（秒）
        useTime = 3000,               -- 使用にかかる時間（ミリ秒）
        animation = {
            dict = 'mp_suicide',
            anim = 'pill',
            duration = 2500
        },
        effects = {
            speedBoost = 1.2,         -- 移動速度ボーナス（1.0 = 通常）
            jumpBoost = 1.5,          -- ジャンプ力ボーナス
            damageMultiplier = 1.5    -- 被ダメージ倍率（小さいと脆い）
        },
        particles = {
            enabled = true,
            dict = 'scr_rcbarry2',
            name = 'scr_exp_clown',
            scale = 0.5
        }
    },
    
    -- 大きくなる薬
    grow = {
        item = 'grow_potion',        -- アイテム名（qb-coreに登録するアイテム名）
        scale = 3.0,                  -- 変更後のスケール（1.0〜5.0）
        duration = 60,                -- 効果時間（秒）
        cooldown = 10,                -- クールダウン時間（秒）
        useTime = 3000,               -- 使用にかかる時間（ミリ秒）
        animation = {
            dict = 'mp_suicide',
            anim = 'pill',
            duration = 2500
        },
        effects = {
            speedBoost = 0.8,         -- 移動速度ボーナス（大きいと遅い）
            jumpBoost = 0.7,          -- ジャンプ力ボーナス
            damageMultiplier = 0.7    -- 被ダメージ倍率（大きいと頑丈）
        },
        particles = {
            enabled = true,
            dict = 'scr_rcbarry2',
            name = 'scr_exp_clown',
            scale = 1.5
        }
    }
}

-- 解毒剤（効果を即座に解除）
Config.Antidote = {
    enabled = true,
    item = 'size_antidote',          -- アイテム名
    useTime = 2000,                   -- 使用にかかる時間（ミリ秒）
    animation = {
        dict = 'mp_suicide',
        anim = 'pill',
        duration = 1500
    }
}

-- 通知設定
Config.Notifications = {
    shrinkStart = '体が小さくなっていく...',
    shrinkEnd = '体が元のサイズに戻った',
    growStart = '体が大きくなっていく...',
    growEnd = '体が元のサイズに戻った',
    antidoteUsed = '解毒剤で効果が解除された',
    cooldownActive = 'クールダウン中です（残り%s秒）',
    alreadyAffected = '既に薬の効果を受けています',
    cannotUseInVehicle = '車両内では使用できません'
}

-- 制限設定
Config.Restrictions = {
    allowInVehicle = false,           -- 車両内での使用を許可
    cancelOnDeath = true,             -- 死亡時に効果を解除
    cancelOnVehicleEnter = false,     -- 車両乗車時に効果を解除
    maxScale = 5.0,                   -- 最大スケール制限
    minScale = 0.3                    -- 最小スケール制限
}

-- サウンド設定
Config.Sounds = {
    enabled = true,
    onUse = {
        name = 'CHALLENGE_UNLOCKED',
        ref = 'HUD_AWARDS'
    },
    onEnd = {
        name = 'MEDAL_UP',
        ref = 'HUD_MINI_GAME_SOUNDSET'
    }
}

-- 同期設定
Config.Sync = {
    enabled = true,                   -- 他プレイヤーへの同期を有効化
    updateInterval = 100              -- 同期更新間隔（ミリ秒）
}
