Config = {}

-- 重装備設定
Config.HeavyArmor = {
    -- 使用時間（秒）
    Duration = 300, -- 5分

    -- 重装備モデル
    PedModel = 'u_m_y_juggernaut_01', -- ジャガーノートモデル
    
    -- 武器設定
    Weapon = 'WEAPON_MINIGUN',
    Ammo = 9999,

    -- 体力・アーマー設定
    MaxHealth = 5000, -- 通常200から大幅増加（5000に）
    MaxArmor = 500, -- 通常100から増加（500に）
    
    -- ダメージ軽減設定
    DamageMultiplier = 0.05, -- 受けるダメージを5%に軽減（95%カット）
    ExplosionDamageMultiplier = 0.1, -- 爆発ダメージを10%に軽減（90%カット）
    HeadshotProtection = true, -- ヘッドショット完全無効化
    HeadshotMultiplier = 0.0, -- ヘッドショット時のダメージを0に（完全無効化）

    -- エフェクト設定
    EnableScreenEffect = true, -- 画面エフェクト有効化
    ScreenEffect = 'REDMIST_LEVEL_6_STAGE_01',
    
    -- 移動速度設定
    MovementSpeed = 0.8, -- 80%の速度（重い装備のため）
    
    -- インベントリ設定
    DisableInventory = true, -- 重装備中はインベントリ無効化
}

-- コマンド設定
Config.Command = {
    Name = 'heavyarmor', -- コマンド名
    AdminOnly = false, -- 管理者専用
}

-- UI設定
Config.UI = {
    -- プログレスバー
    EquipDuration = 3000, -- 装備時間（ミリ秒）
    UnequipDuration = 2000, -- 解除時間（ミリ秒）
    
    -- 通知設定
    Position = 'top-right',
}

-- 通知メッセージ
Config.Notifications = {
    Equipped = '重装備を装着しました',
    Unequipped = '重装備を解除しました',
    TimeExpired = '重装備の使用時間が終了しました',
    TimeRemaining = '残り時間: %s秒',
    AlreadyEquipped = '既に重装備を装着しています',
    NoPermission = 'この機能を使用する権限がありません',
    Equipping = '重装備を装着中...',
    Unequipping = '重装備を解除中...',
    InventoryDisabled = '重装備中はインベントリを使用できません',
}

-- デバッグモード
Config.Debug = true
