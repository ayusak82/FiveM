Config = {}

-- デバッグモード
Config.Debug = true

-- クラフト設定
Config.Crafting = {
    -- 基本クラフト時間（秒）
    BaseTime = 10.0,
    -- 最大同時クラフト数
    MaxConcurrentCrafts = 5,
    -- 経験値倍率
    XPMultiplier = 1.0,
    -- レベルアップに必要な経験値（レベル * この値）
    XPPerLevel = 1000
}

-- クラフト台の設定
Config.CraftingStations = {
    {
        name = "weapon_workbench",
        label = "武器作業台",
        coords = vector3(1262.46, -1710.3, 54.66), -- テスト用：スポーン地点
        size = vec3(2.0, 2.0, 1.0),
        rotation = 45.0,
        categories = {"weapons", "weapon_parts"},
        requiredLevel = 0
    },
    {
        name = "electronics_bench",
        label = "電子工作台",
        coords = vector3(1261.74, -1713.17, 54.66), -- テスト用座標
        size = vec3(2.0, 2.0, 1.0),
        rotation = 45.0,
        categories = {"electronics", "tools"},
        requiredLevel = 5
    },
    {
        name = "cooking_station",
        label = "料理台",
        coords = vector3(1265.41, -1707.66, 54.66), -- テスト用座標
        size = vec3(2.0, 2.0, 1.0),
        rotation = 45.0,
        categories = {"food", "drinks"},
        requiredLevel = 0
    }
}

-- クラフトレシピ
Config.Recipes = {
    -- 武器カテゴリ
    weapons = {
        {
            name = "WEAPON_PISTOL",
            label = "ピストル",
            category = "weapons",
            ingredients = {
                {item = "steel", amount = 5},
                {item = "plastic", amount = 3},
                {item = "screw", amount = 10}
            },
            result = {item = "WEAPON_PISTOL", amount = 1},
            craftTime = 30.0,
            xpReward = 100,
            requiredLevel = 10,
            icon = "fas fa-gun"
        },
        {
            name = "pistol_ammo",
            label = "ピストル弾薬",
            category = "weapons",
            ingredients = {
                {item = "metal", amount = 2},
                {item = "gunpowder", amount = 1}
            },
            result = {item = "pistol_ammo", amount = 50},
            craftTime = 10.0,
            xpReward = 25,
            requiredLevel = 5,
            icon = "fas fa-bullet"
        }
    },

    -- 武器パーツカテゴリ
    weapon_parts = {
        {
            name = "weapon_scope",
            label = "武器スコープ",
            category = "weapon_parts",
            ingredients = {
                {item = "glass", amount = 2},
                {item = "steel", amount = 3},
                {item = "screw", amount = 5}
            },
            result = {item = "weapon_scope", amount = 1},
            craftTime = 20.0,
            xpReward = 75,
            requiredLevel = 8,
            icon = "fas fa-crosshairs"
        }
    },

    -- 電子機器カテゴリ
    electronics = {
        {
            name = "radio",
            label = "ラジオ",
            category = "electronics",
            ingredients = {
                {item = "plastic", amount = 3},
                {item = "wire", amount = 5},
                {item = "battery", amount = 1}
            },
            result = {item = "radio", amount = 1},
            craftTime = 15.0,
            xpReward = 50,
            requiredLevel = 3,
            icon = "fas fa-broadcast-tower"
        },
        {
            name = "phone",
            label = "スマートフォン",
            category = "electronics",
            ingredients = {
                {item = "plastic", amount = 5},
                {item = "wire", amount = 8},
                {item = "battery", amount = 2},
                {item = "glass", amount = 1}
            },
            result = {item = "phone", amount = 1},
            craftTime = 25.0,
            xpReward = 100,
            requiredLevel = 12,
            icon = "fas fa-mobile-alt"
        }
    },

    -- 道具カテゴリ
    tools = {
        {
            name = "repair_kit",
            label = "修理キット",
            category = "tools",
            ingredients = {
                {item = "screw", amount = 10},
                {item = "wire", amount = 5},
                {item = "plastic", amount = 3}
            },
            result = {item = "repair_kit", amount = 1},
            craftTime = 20.0,
            xpReward = 60,
            requiredLevel = 6,
            icon = "fas fa-tools"
        }
    },

    -- 料理カテゴリ
    food = {
        {
            name = "sandwich",
            label = "サンドイッチ",
            category = "food",
            ingredients = {
                {item = "bread", amount = 2},
                {item = "meat", amount = 1},
                {item = "lettuce", amount = 1}
            },
            result = {item = "sandwich", amount = 1},
            craftTime = 5.0,
            xpReward = 15,
            requiredLevel = 0,
            icon = "fas fa-hamburger"
        },
        {
            name = "cooked_meat",
            label = "調理済み肉",
            category = "food",
            ingredients = {
                {item = "raw_meat", amount = 1}
            },
            result = {item = "cooked_meat", amount = 1},
            craftTime = 8.0,
            xpReward = 10,
            requiredLevel = 0,
            icon = "fas fa-drumstick-bite"
        }
    },

    -- 飲み物カテゴリ
    drinks = {
        {
            name = "water_bottle",
            label = "水ボトル",
            category = "drinks",
            ingredients = {
                {item = "plastic_bottle", amount = 1},
                {item = "water", amount = 1}
            },
            result = {item = "water_bottle", amount = 1},
            craftTime = 3.0,
            xpReward = 5,
            requiredLevel = 0,
            icon = "fas fa-tint"
        }
    }
}

-- レベル特典（レベルアップ時のボーナス）
Config.LevelBenefits = {
    -- クラフト速度ボーナス（レベル毎の%減少）
    SpeedBonus = 2, -- レベル1毎に2%速度向上
    -- 最大速度ボーナス（%）
    MaxSpeedBonus = 50, -- 最大50%まで速度向上
}

-- 言語設定
Config.Locales = {
    ['open_crafting'] = 'クラフトメニューを開く',
    ['insufficient_items'] = '必要なアイテムが不足しています',
    ['crafting_success'] = 'クラフトが完了しました！',
    ['crafting_failed'] = 'クラフトに失敗しました',
    ['level_up'] = 'レベルアップ！現在のレベル: %s',
    ['insufficient_level'] = 'レベルが不足しています。必要レベル: %s',
    ['crafting_in_progress'] = 'クラフト中...',
    ['max_concurrent_reached'] = '同時クラフトの上限に達しています',
    ['gained_xp'] = '%s XP を獲得しました'
}