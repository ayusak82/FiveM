Config = {}

-- NPCの設定
Config.NPCs = {
    {
        model = 'u_m_m_streetart_01', -- NPCモデル
        coords = vector4(-448.92, -1658.26, 11.26, 251.56), -- 座標 (x, y, z, heading)
        scenario = 'WORLD_HUMAN_STAND_MOBILE', -- NPCのアニメーション
        blip = {
            enabled = false, -- マップにブリップを表示するかどうか
            sprite = 500, -- ブリップのスプライト
            color = 2, -- ブリップの色
            scale = 0.7, -- ブリップのサイズ
            label = 'アイテム売却', -- ブリップのラベル
        }
    },
    {
        model = 'u_m_m_streetart_01', -- NPCモデル
        coords = vector4(156.21, 1210.1, 226.79, 157.61), -- 座標 (x, y, z, heading)
        scenario = 'WORLD_HUMAN_STAND_MOBILE', -- NPCのアニメーション
        blip = {
            enabled = false, -- マップにブリップを表示するかどうか
            sprite = 500, -- ブリップのスプライト
            color = 2, -- ブリップの色
            scale = 0.7, -- ブリップのサイズ
            label = 'アイテム売却', -- ブリップのラベル
        }
    },
    {
        model = 'u_m_m_streetart_01', -- NPCモデル
        coords = vector4(-364.73, 6107.96, 39.47, 41.78), -- 座標 (x, y, z, heading)
        scenario = 'WORLD_HUMAN_STAND_MOBILE', -- NPCのアニメーション
        blip = {
            enabled = false, -- マップにブリップを表示するかどうか
            sprite = 500, -- ブリップのスプライト
            color = 2, -- ブリップの色
            scale = 0.7, -- ブリップのサイズ
            label = 'アイテム売却', -- ブリップのラベル
        }
    },
    -- 必要に応じて他のNPC場所を追加できます
}

-- 売却可能アイテムの設定
Config.SellableItems = {
    ['markedbills'] = {
        label = 'マーク札',
        priceType = 'metadata', -- 'fixed' または 'metadata'
        fixedPrice = 100, -- priceType = 'fixed'の場合の1個あたりの価格
        metadataKey = 'worth', -- priceType = 'metadata'の場合のメタデータキー
        sellPercentage = 1.0, -- 実際の価値に対する支払い率（100%）
        cooldown = 5, -- 売却後のクールダウン（分）
        icon = 'money-bill', -- メニューアイコン
    },
    ['stacksofcash'] = {
        label = '現金の山',
        priceType = 'fixed',
        fixedPrice = 1,
        metadataKey = nil,
        sellPercentage = 1.0, -- 70%で売却
        cooldown = 5,
        icon = 'box',
    },
    --[[
    ['contraband'] = {
        label = '密売品',
        priceType = 'metadata',
        fixedPrice = 0,
        metadataKey = 'value',
        sellPercentage = 0.85, -- 85%で売却
        cooldown = 3,
        icon = 'exclamation-triangle',
    },
    ]]
    -- 必要に応じて他のアイテムを追加
}

-- 通知メッセージ
Config.Notifications = {
    noSellableItems = '売却可能なアイテムを持っていません。',
    sellSuccess = '%s円分の%sを%s円で売却しました。',
    cooldown = 'あと%s分待ってからもう一度お越しください。',
    cancelSale = '取引をキャンセルしました。',
}