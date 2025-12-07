Config = {}

-- クラフトテーブルの場所
Config.CraftingLocations = {
    --[[
    {
        coords = vector3(-590.49, -1063.02, 22.36), -- 変更が必要
        radius = 1.5,
        debug = false, -- trueの場合、デバッグスフィアが表示されます
    },
    {
        coords = vector3(-1174.04, -889.02, 13.9), -- 別の場所
        radius = 1.5,
        debug = false, 
        prop = {
            model = 'prop_food_bs_bshelf', -- 鉄板/グリドル
            rotation = vector3(0.0, 0.0, 0.0),
            offset = vector3(0.0, 0.0, -0.5),
            frozen = true
        }
    },
    --]]
    -- ベーカリー (サンプル)
    {
        coords = vector3(60.2, -122.59, 55.45), -- 別の場所
        radius = 1.5,
        debug = false,
    },
    -- タバコ屋 (サンプル)
    {
        coords = vector3(275.86, -1023.53, 29.24), -- 別の場所
        radius = 1.5,
        debug = false,
    },
    -- 猫カフェ (サンプル)
    {
        coords = vector3(-590.39, -1063.16, 22.36), -- 座標を設定してください
        radius = 1.5,
        debug = false,
    },
    -- コーヒー (サンプル)
    {
        coords = vector3(178.02, -236.51, 54.05), -- 座標を設定してください
        radius = 1.5,
        debug = false,
    },
    -- カフェ？ (サンプル)
    {
        coords = vector3(-592.19, -286.68, 35.48), -- 座標を設定してください
        radius = 1.5,
        debug = false,
    },
    -- ドーナツ屋 (サンプル)
    {
        coords = vector3(-1330.18, -243.19, 42.77), -- 座標を設定してください
        radius = 1.5,
        debug = false,
    },
    -- バー (サンプル)
    {
        coords = vector3(-1384.57, -676.52, 24.79), -- 座標を設定してください
        radius = 1.5,
        debug = false,
    },
    -- レストラン (サンプル)
    {
        coords = vector3(-1836.55, -1189.43, 14.31), -- 座標を設定してください
        radius = 1.5,
        debug = false,
    },
    -- バー (サンプル)
    {
        coords = vector3(-1659.73, -1062.53, 12.16), -- 座標を設定してください
        radius = 1.5,
        debug = false,
    },
    -- ラーメン屋 (サンプル)
    {
        coords = vector3(-1184.54, -1157.08, 7.67), -- 座標を設定してください
        radius = 1.5,
        debug = false,
    },
    -- バーガー (サンプル)
    {
        coords = vector3(-1186.58, -901.24, 13.8), -- 座標を設定してください
        radius = 1.5,
        debug = false,
    },
    -- ネイルサロン (サンプル)
    {
        coords = vector3(-1260.37, -800.34, 18.63), -- 座標を設定してください
        radius = 1.5,
        debug = false,
    },
    -- レストラン (サンプル)
    {
        coords = vector3(-1072.06, -1445.69, -1.42), -- 座標を設定してください
        radius = 1.5,
        debug = false,
    },
    -- バー (サンプル)
    {
        coords = vector3(129.75, -1281.63, 29.27), -- 座標を設定してください
        radius = 1.5,
        debug = false,
    },
    -- レストラン (サンプル)
    {
        coords = vector3(1116.93, -635.76, 56.82), -- 座標を設定してください
        radius = 1.5,
        debug = false,
    },
    -- バー (サンプル)
    {
        coords = vector3(1220.77, -499.98, 65.31), -- 座標を設定してください
        radius = 1.5,
        debug = false,
    },
    -- バー (サンプル)
    {
        coords = vector3(-562.22, 288.43, 82.18), -- 座標を設定してください
        radius = 1.5,
        debug = false,
    },
    -- バー (サンプル)
    {
        coords = vector3(-302.61, 6270.57, 31.49), -- 座標を設定してください
        radius = 1.5,
        debug = false,
    },
    -- バー (サンプル)
    {
        coords = vector3(1982.01, 3052.83, 47.22), -- 座標を設定してください
        radius = 1.5,
        debug = false,
    },
    -- ケバブ (サンプル)
    {
        coords = vector3(385.11, -934.89, 29.41), -- 座標を設定してください
        radius = 1.5,
        debug = false,
    },
    -- ビーンマシーン (サンプル)
    {
        coords = vector3(123.03, -1039.09, 29.28), -- 座標を設定してください
        radius = 1.5,
        debug = false,
    },
    -- バー (サンプル)
    {
        coords = vector3(1.09, -1005.39, 29.3), -- 座標を設定してください
        radius = 1.5,
        debug = false,
    },
    -- バー (サンプル)
    {
        coords = vector3(372.07, -345.8, 7.59), -- 座標を設定してください
        radius = 1.5,
        debug = false,
    },
    -- サンプル店舗
    {
        coords = vector3(-904.05, -446.58, 160.90), -- 座標を設定してください
        radius = 1.5,
        debug = false,
    },
    -- サンプル店舗
    {
        coords = vector3(-646.52, -1240.42, 11.63), -- 座標を設定してください
        radius = 1.5,
        debug = false,
    },
}

-- アイテムタイプの設定
Config.ItemTypes = {
    food = {
        requiredItems = {
            { name = 'food_material_1', amount = 1 },
            { name = 'food_material_2', amount = 1 },
            { name = 'food_material_3', amount = 1 },
        },
        outputMultiplier = 3, -- 完成品の数量の倍率
        progressBarDuration = 2000, -- ミリ秒
        animDict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@',
        anim = 'weed_crouch_checkingleaves_idle_01_inspector',
        flags = 1,
        label = '料理を作る'
    },
    drink = {
        requiredItems = {
            { name = 'drink_material_1', amount = 1 },
            { name = 'drink_material_2', amount = 1 },
            { name = 'drink_material_3', amount = 1 },
        },
        outputMultiplier = 3,
        progressBarDuration = 2000,
        animDict = 'mini@drinking',
        anim = 'shots_barman_b',
        flags = 8,
        label = '飲み物を作る'
    },
    stress = {
        requiredItems = {
            { name = 'stress_material_1', amount = 1 },
            { name = 'stress_material_2', amount = 1 },
            { name = 'stress_material_3', amount = 1 },
        },
        outputMultiplier = 3,
        progressBarDuration = 2000,
        animDict = 'misscarsteal4@aliens',
        anim = 'rehearsal_base_idle_director',
        flags = 1,
        label = 'リラックスアイテムを作る'
    },
    normal = {
        requiredItems = {
            { name = 'item_material_1', amount = 1 },
            { name = 'item_material_2', amount = 1 },
            { name = 'item_material_3', amount = 1 },
        },
        outputMultiplier = 3,
        progressBarDuration = 2000,
        animDict = 'anim@amb@clubhouse@bar@drink@one',
        anim = 'one_bartender',
        flags = 1,
        label = 'アイテムを作る'
    }
}

-- アイテムとタイプのマッピング（デフォルト値）
Config.DefaultItemTypeMapping = {
    --[[
    ['sandwich'] = 'food',
    ['coffee'] = 'drink',
    ['cigarette'] = 'stress',
    ['phone'] = 'normal',
    --]]
    -- 他のアイテムマッピングはサーバーサイドで自動生成されます
}

-- デバッグモード
Config.Debug = false