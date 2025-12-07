Config = {}

-- 基本設定
Config.Debug = false -- デバッグモード
Config.UseTarget = true -- ox_targetを使用する

-- 自動販売機の位置データ
Config.VendingMachines = {
    -- 例: 各自販機に個別のID、位置、モデル、権限を設定
    [1] = {
        coords = vector4(276.6, -1028.78, 29.21, 0.0), -- x, y, z, heading
        model = `prop_vend_soda_01`,
        jobs = { -- この自販機を管理できる職業と必要な階級
            ['sample_job_1'] = 3,
        },
        label = 'サンプル飲食店 自販機',
    },
    [2] = {
        coords = vector4(-582.67, -1071.25, 22.33, 0.0),
        model = `prop_vend_soda_01`,
        jobs = {
            ['sample_job_2'] = 3,
        },
        label = 'サンプル飲食店 自販機',
    },
    [3] = {
        coords = vector4(-636.83, -1250.53, 11.81, 0.0),
        model = `prop_vend_soda_01`,
        jobs = {
            ['sample_job_3'] = 3,
        },
        label = 'サンプル飲食店 自販機',
    },
    [4] = {
        coords = vector4(8.05, -984.9, 29.37, 159.15),
        model = `prop_vend_soda_01`,
        jobs = {
            ['sample_job_4'] = 3,
        },
        label = 'サンプル飲食店 自販機',
    },
}

-- 自動販売機モデル一覧（新規設置時に選択可能）
Config.AvailableModels = {
    {model = `prop_vend_soda_01`, label = 'ソーダ自販機タイプ1'},
    {model = `prop_vend_soda_02`, label = 'ソーダ自販機タイプ2'},
    {model = `prop_vend_water_01`, label = '水自販機'},
}

-- 販売可能なアイテム（各自販機でカスタマイズ可能）
Config.DefaultItems = {
    --[[
    {name = 'water', label = '水', price = 10, stock = 20},
    {name = 'cola', label = 'コーラ', price = 15, stock = 20}, 
    {name = 'sprunk', label = 'スプランク', price = 15, stock = 20},
    {name = 'coffee', label = 'コーヒー', price = 20, stock = 15},
    {name = 'sandwich', label = 'サンドイッチ', price = 25, stock = 10},
    --]]
}

-- データベーステーブル（自販機の実際の在庫と価格を保存）
Config.DatabaseTable = 'ng_vendingmachines'

-- 自販機UI設定
Config.UI = {
    title = '自動販売機',
    adminTitle = '自動販売機 - 管理',
}

-- 翻訳テキスト
Config.Text = {
    interact = '自動販売機を利用する',
    manage = '自動販売機を管理する',
    noPerms = '管理権限がありません',
    outOfStock = '売り切れました',
    notEnoughMoney = 'お金が足りません',
    purchased = '%sを購入しました',
    stockAdded = '%sの在庫を追加しました',
    priceChanged = '%sの価格を変更しました',
    machineRegistered = '自動販売機を登録しました',
    machineRemoved = '自動販売機を削除しました',
    itemAdded = '%sを自販機に追加しました',
    itemRemoved = '%sを自販機から削除しました',
    insufficientBank = '銀行残高が足りません',
    invalidPayment = '無効な支払い方法です',
}