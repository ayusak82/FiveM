Config = {}

-- ガチャNPCの設定
Config.NPCs = {
    {
        model = 's_m_m_autoshop_01', -- NPCモデル
        coords = vector4(-32.59, -1102.43, 26.42, 160.0), -- 座標と向き(Legion Square付近)
        scenario = 'WORLD_HUMAN_CLIPBOARD', -- NPCのアニメーション
        blipSettings = {
            enabled = true,
            sprite = 669, -- ガチャマシンアイコン
            color = 5, -- 黄色
            scale = 0.8,
            label = '車両ガチャ'
        }
    },
}

-- インタラクション設定
Config.Interaction = {
    distance = 2.5, -- インタラクション可能距離
    label = '[E] 車両ガチャ', -- 表示テキスト
    icon = 'fa-solid fa-ticket', -- アイコン
}

-- 通知設定
Config.Notify = {
    position = 'top', -- 通知位置
    duration = 5000, -- 表示時間(ミリ秒)
}

-- ガチャUI設定
Config.GachaUI = {
    animationDuration = 3000, -- ルーレット演出時間(ミリ秒)
    showPreview = true, -- 車両プレビュー表示
}

-- 10連ガチャ設定
Config.MultiGacha = {
    enabled = true, -- 10連ガチャ有効/無効
    count = 10, -- 回数
    discount = 0.1, -- 割引率(10%割引)
}

-- レアリティ設定
Config.Rarities = {
    {
        name = 'Common',
        label = 'コモン',
        color = '#B0B0B0', -- グレー
        chance = 60, -- 排出確率(%)
    },
    {
        name = 'Rare',
        label = 'レア',
        color = '#4169E1', -- 青
        chance = 25,
    },
    {
        name = 'SuperRare',
        label = 'スーパーレア',
        color = '#9370DB', -- 紫
        chance = 12,
    },
    {
        name = 'UltraRare',
        label = 'ウルトラレア',
        color = '#FFD700', -- 金
        chance = 3,
    }
}

-- ガチャチケットアイテム名
Config.TicketItem = 'gacha_ticket'

-- デバッグモード
Config.Debug = false

-- 言語設定
Config.Locale = {
    -- 通知メッセージ
    not_enough_money = '所持金が足りません',
    not_enough_ticket = 'ガチャチケットが足りません',
    gacha_disabled = 'このガチャは現在利用できません',
    vehicle_won = '🎉 %s を獲得しました!',
    vehicle_added_garage = '車両がガレージに追加されました',
    gacha_success = 'ガチャを回しました',
    multi_gacha_success = '10連ガチャを回しました!',
    
    -- 管理者メッセージ
    no_permission = '権限がありません',
    ticket_given = '%s枚のガチャチケットを付与しました',
    gacha_toggled_on = 'ガチャを有効化しました',
    gacha_toggled_off = 'ガチャを無効化しました',
    
    -- UIテキスト
    select_gacha_type = 'ガチャの種類を選択',
    payment_method = '支払い方法',
    use_money = 'お金で支払う',
    use_ticket = 'チケットを使用',
    confirm_gacha = 'ガチャを回す',
    gacha_result = 'ガチャ結果',
    close = '閉じる',
    single_gacha = '単発ガチャ',
    multi_gacha = '10連ガチャ',
    
    -- ガチャ演出
    rolling = 'ガチャを回しています...',
    multi_rolling = '10連ガチャを回しています... (%d/%d)',
    congratulations = 'おめでとうございます!',
}

return Config
