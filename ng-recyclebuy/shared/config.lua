Config = {}

-- デバッグモード(開発時のみtrue)
Config.Debug = false

-- リサイクルセンターの場所
Config.RecycleLocations = {
    {
        coords = vector4(-470.75, -1718.14, 18.69, 287.91),
        blip = {
            enabled = true,
            sprite = 566, -- Recycling icon
            color = 2,    -- Green
            scale = 0.8,
            label = 'リサイクルセンター素材買い取り'
        },
        ped = {
            model = 's_m_y_garbage',
            scenario = 'WORLD_HUMAN_CLIPBOARD'
        }
    },
    -- 他の場所を追加する場合はここに追加
    -- {
    --     coords = vector4(x, y, z, heading),
    --     blip = { ... },
    --     ped = { ... }
    -- },
}

-- 買取可能なアイテムと価格
Config.RecycleItems = {
    -- アイテム名と買取価格を設定
    ['plastic'] = 600,
    ['glass'] = 600,
    ['aluminum'] = 600,
    ['copper'] = 600,
    ['rubber'] = 600,
    ['steel'] = 600,
    ['metalscrap'] = 600,
    ['iron'] = 600,
    ['titanium'] = 600,
    
    -- 必要に応じて追加
    -- ['item_name'] = price,
}

-- インタラクション設定
Config.Interaction = {
    distance = 2.5,        -- NPCとの対話可能距離
    useTarget = true,     -- ox_targetを使用する場合はtrue
    key = 38,              -- Eキー（ox_targetを使用しない場合）
}

-- アニメーション設定
Config.Animation = {
    dict = 'mp_common',
    anim = 'givetake1_a',
    duration = 2500, -- ミリ秒
}

-- 通知メッセージ
Config.Messages = {
    noItems = 'リサイクル可能なアイテムを持っていません',
    success = 'アイテムを売却しました',
    cancelled = 'キャンセルしました',
    processing = '処理中...',
    interact = '[E] リサイクルセンター',
}
