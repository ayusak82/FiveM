Config = {}

-- 武器屋の場所とNPC設定
Config.Locations = {
    {
        coords = vector4(15.7, -1109.52, 29.8, 178.65), -- 場所の座標と向き
        pedModel = 'cs_josef', -- NPCモデル
        blip = {
            enable = true,
            sprite = 110, -- 武器屋のブリップスプライト
            color = 1, -- 赤色
            scale = 0.8,
            label = '武器屋'
        }
    },
    {
        coords = vector4(252.4, -48.2, 69.94, 70.0),
        pedModel = 's_m_y_ammucity_01',
        blip = {
            enable = true,
            sprite = 110,
            color = 1,
            scale = 0.8,
            label = '武器屋'
        }
    },
    {
        coords = vector4(843.28, -1034.0, 28.19, 4.5),
        pedModel = 'mp_m_weapexp_01',
        blip = {
            enable = true,
            sprite = 110,
            color = 1,
            scale = 0.8,
            label = '武器屋'
        }
    },
    {
        coords = vector4(-663.21, -934.1, 21.83, 174.23),
        pedModel = 'cs_josef',
        blip = {
            enable = true,
            sprite = 110,
            color = 1,
            scale = 0.8,
            label = '武器屋'
        }
    },
    {
        coords = vector4(810.2, -2158.0, 29.62, 359.94),
        pedModel = 'mp_m_weapexp_01',
        blip = {
            enable = true,
            sprite = 110,
            color = 1,
            scale = 0.8,
            label = '武器屋'
        }
    }
}

-- 武器屋で販売する武器とアイテム
Config.Items = {
    {
        name = 'WEAPON_PISTOL',
        label = 'Pistol',
        price = 500000,
        description = '標準的なハンドガン',
        type = 'weapon'
    },
    {
        name = 'WEAPON_KNUCKLE',
        label = 'Knuckle Dusters',
        price = 100000,
        description = '近接戦闘用の武器',
        type = 'weapon'
    },
    {
        name = 'WEAPON_KNIFE',
        label = 'Knife',
        price = 100000,
        description = '近接戦闘用のナイフ',
        type = 'weapon'
    },
    {
        name = 'ammo-9',
        label = '9mm Ammo',
        price = 500,
        description = 'ピストル用の弾薬',
        type = 'item'
    },
}

-- UIの設定
Config.UI = {
    title = "武器ショップ",
    subtitle = "最高品質の武器を取り揃えております",
    logo = "nui://ox_inventory/web/images/WEAPON_PISTOL.png", -- ox_inventoryの武器アイコン
    colorTheme = "rgba(200, 50, 50, 0.8)" -- 赤系のテーマカラー
}

-- 支払い方法の設定
Config.PaymentMethods = {
    cash = true, -- 現金払いを有効化
    bank = true  -- 銀行払いを有効化
}