Config = {}

-- アイテム作成の権限を持つジョブとグレード
Config.AllowedJobs = {
    ['police'] = 3, -- 階級3以上
    ['ambulance'] = 3,
    ['mechanic'] = 3,
}

-- アイテムタイプの定義
Config.ItemTypes = {
    'normal',    -- 通常アイテム
    'food',      -- 食べ物
    'drink',      -- 飲み物
    'stress'      -- ストレス
}

-- 消費アイテムの効果設定
Config.ConsumableEffects = {
    food = {
        hunger = true
    },
    drink = {
        thirst = true
    },
    stress = {
        stress = true
    }
}

-- デフォルトのアイテム設定
Config.DefaultSettings = {
    weight = 500,         -- デフォルトの重量(グラム)
    description = "",     -- デフォルトの説明文
    client = {
        status = {},      -- ステータス効果
        export = "",      -- エクスポート関数
    }
}

-- アイテム画像の保存パス
Config.ImagePath = "ox_inventory/web/images/"