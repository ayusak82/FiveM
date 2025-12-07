Config = {}

-- Discord Webhook URL("https://discord.webhook") または false
Config.Webhook = false

-- デバッグモード設定
Config.Debug = false  -- trueにすると詳細なログが表示されます

-- UI表示キー設定
Config.OpenKey = 'F7'

-- ace権限設定
Config.AdminGroup = 'group.admin'

-- 通知設定
Config.Notifications = {
    useOxNotify = true,         -- ox_libの通知を使用するか
    showInvoiceDetails = true,   -- 請求書の詳細を通知に表示するか
    playSound = true,            -- 通知音を鳴らすか
    soundName = "Event_Start_Text",
    soundSet = "GTAO_FM_Events_Soundset",
    duration = 5000,             -- 通知の表示時間（ミリ秒）
}

-- バンキングシステム設定
-- 'renewed' : Renewed-Banking
-- 'qb' : QB-Banking
-- 'okok' : okokBanking
-- 'qb-management' : qb-management
Config.BankingSystem = 'qb'

-- QBCoreの種類設定
-- 'qb' または 'qbx'
Config.QBType = 'qb'

-- データベーステーブル設定
Config.Database = {
    renewed = {
        accounts = 'bank_accounts_new',
        transactions = 'player_transactions'
    },
    ['qb-management'] = {
        accounts = 'management_funds',
        type = 'boss'
    },
    qb = {
        accounts = 'bank_accounts',
        statements = 'bank_statements'
    },
    okok = {
        transactions = 'okokbanking_transactions',
        societies = 'okokbanking_societies'
    }
}

-- 強制執行が可能な職業リスト
Config.ForcePaymentJobs = {
    ['police'] = true,
    ['ambulance'] = true,
    ['admin'] = true,
    ['police'] = true,
    ['ambulance'] = true,
    ['doctor'] = true,
    ['realestate'] = true,
    ['sample_mechanic_1'] = true,
    ['sample_mechanic_2'] = true,
    ['sample_mechanic_3'] = true,
    ['sample_mechanic_4'] = true,
    ['sample_mechanic_5'] = true,
    ['sample_mechanic_6'] = true,
    ['sample_mechanic_7'] = true,
    ['sample_mechanic_8'] = true,
    ['sample_mechanic_9'] = true,
    ['sample_mechanic_10'] = true,
    ['sample_mechanic_11'] = true,
    ['sample_mechanic_12'] = true,
    ['sample_mechanic_13'] = true,
    ['sample_mechanic_14'] = true,
    ['sample_mechanic_15'] = true,
    ['sample_mechanic_16'] = true,
    ['sample_restaurant_1'] = true,
    ['sample_restaurant_2'] = true,
    ['sample_restaurant_3'] = true,
    ['sample_restaurant_4'] = true,
    ['sample_restaurant_5'] = true,
    ['sample_restaurant_6'] = true,
    ['sample_restaurant_7'] = true,
    ['sample_restaurant_8'] = true,
    ['sample_restaurant_9'] = true,
    ['sample_restaurant_10'] = true,
    ['sample_restaurant_11'] = true,
    ['sample_restaurant_12'] = true,
    ['sample_restaurant_13'] = true,
    ['sample_restaurant_14'] = true,
    ['sample_restaurant_15'] = true,
    ['sample_restaurant_16'] = true,
    ['sample_restaurant_17'] = true,
    ['sample_restaurant_18'] = true,
    ['sample_restaurant_19'] = true,
    ['sample_restaurant_20'] = true,
    ['sample_restaurant_21'] = true,
    ['sample_restaurant_22'] = true,
    ['sample_restaurant_23'] = true,
    ['sample_restaurant_24'] = true,
    ['sample_restaurant_25'] = true,
    ['sample_restaurant_26'] = true,
    ['sample_restaurant_27'] = true,
    ['sample_restaurant_28'] = true,
}

-- 強制執行の設定
Config.ForcePayment = {
    allowNegativeBalance = false, -- trueの場合、残高がマイナスになることを許可
    checkAccounts = {  -- 残高チェック対象の口座タイプ
        bank = true,   -- 銀行口座
        cash = true    -- 現金所持
    }
}

-- プリセット請求を使用できる職業リスト（その他の職業はその他の金額のみ使用可能）
Config.JobList = {
    ['admin'] = true,
    ['police'] = true,
    ['ambulance'] = true,
    ['doctor'] = true,
    ['realestate'] = true,
    ['taxi'] = true,
    ['casino'] = true,
    ['print'] = true, 
    ['sample_mechanic_1'] = true,
    ['sample_mechanic_2'] = true,
    ['sample_mechanic_3'] = true,
    ['sample_mechanic_4'] = true,
    ['sample_mechanic_5'] = true,
    ['sample_mechanic_6'] = true,
    ['sample_mechanic_7'] = true,
    ['sample_mechanic_8'] = true,
    ['sample_mechanic_9'] = true,
    ['sample_mechanic_10'] = true,
    ['sample_mechanic_11'] = true,
    ['sample_mechanic_12'] = true,
    ['sample_mechanic_13'] = true,
    ['sample_mechanic_14'] = true,
    ['sample_mechanic_15'] = true,
    ['sample_mechanic_16'] = true,
    ['sample_restaurant_1'] = true,
    ['sample_restaurant_2'] = true,
    ['sample_restaurant_3'] = true,
    ['sample_restaurant_4'] = true,
    ['sample_restaurant_5'] = true,
    ['sample_restaurant_6'] = true,
    ['sample_restaurant_7'] = true,
    ['sample_restaurant_8'] = true,
    ['sample_restaurant_9'] = true,
    ['sample_restaurant_10'] = true,
    ['sample_restaurant_11'] = true,
    ['sample_restaurant_12'] = true,
    ['sample_restaurant_13'] = true,
    ['sample_restaurant_14'] = true,
    ['sample_restaurant_15'] = true,
    ['sample_restaurant_16'] = true,
    ['sample_restaurant_17'] = true,
    ['sample_restaurant_18'] = true,
    ['sample_restaurant_19'] = true,
    ['sample_restaurant_20'] = true,
    ['sample_restaurant_21'] = true,
    ['sample_restaurant_22'] = true,
    ['sample_restaurant_23'] = true,
    ['sample_restaurant_24'] = true,
    ['sample_restaurant_25'] = true,
    ['sample_restaurant_26'] = true,
    ['sample_restaurant_27'] = true,
    ['sample_restaurant_28'] = true,
}

-- 職業ごとの収入分配率設定（%） - 設定された%が職業口座に入金
Config.JobPaymentRatio = {
    ['admin'] = 100,
    ['police'] = 50,
    ['ambulance'] = 50,
    ['realestate'] = 50,
    ['taxi'] = 50,
    ['casino'] = 50,
    ['print'] = 50, 
    ['sample_mechanic_1'] = 50,
    ['sample_mechanic_2'] = 50,
    ['sample_mechanic_3'] = 50,
    ['sample_mechanic_4'] = 50,
    ['sample_mechanic_5'] = 50,
    ['sample_mechanic_6'] = 50,
    ['sample_mechanic_7'] = 50,
    ['sample_mechanic_8'] = 50,
    ['sample_mechanic_9'] = 50,
    ['sample_mechanic_10'] = 50,
    ['sample_mechanic_11'] = 50,
    ['sample_mechanic_12'] = 50,
    ['sample_mechanic_13'] = 50,
    ['sample_mechanic_14'] = 50,
    ['sample_mechanic_15'] = 50,
    ['sample_mechanic_16'] = 50,
    ['sample_restaurant_1'] = 50,
    ['sample_restaurant_2'] = 50,
    ['sample_restaurant_3'] = 50,
    ['sample_restaurant_4'] = 50,
    ['sample_restaurant_5'] = 50,
    ['sample_restaurant_6'] = 50,
    ['sample_restaurant_7'] = 50,
    ['sample_restaurant_8'] = 50,
    ['sample_restaurant_9'] = 50,
    ['sample_restaurant_10'] = 50,
    ['sample_restaurant_11'] = 50,
    ['sample_restaurant_12'] = 50,
    ['sample_restaurant_13'] = 50,
    ['sample_restaurant_14'] = 50,
    ['sample_restaurant_15'] = 50,
    ['sample_restaurant_16'] = 50,
    ['sample_restaurant_17'] = 50,
    ['sample_restaurant_18'] = 50,
    ['sample_restaurant_19'] = 50,
    ['sample_restaurant_20'] = 50,
    ['sample_restaurant_21'] = 50,
    ['sample_restaurant_22'] = 50,
    ['sample_restaurant_23'] = 50,
    ['sample_restaurant_24'] = 50,
    ['sample_restaurant_25'] = 50,
    ['sample_restaurant_26'] = 50,
    ['sample_restaurant_27'] = 50,
}

-- 職業ごとの請求内容プリセット
Config.JobInvoicePresets = {
    ['police'] = {
        {label = 'テルミット強盗罪', amount = 5000000},
        {label = 'オイルリグ強盗罪', amount = 6250000},
        {label = '住宅強盗罪', amount = 6700000},
        {label = '店舗強盗罪', amount = 6700000},
        {label = 'ATM強盗罪', amount = 5000000},
        {label = '列車強盗罪', amount = 8300000},
        {label = 'フリーカ強盗罪', amount = 18750000},
        {label = '宝石強盗罪', amount = 12500000},
        {label = '豪華客船強盗罪', amount = 10000000},
        {label = 'ヒューメイン強盗罪', amount = 12500000},
        {label = 'パレト強盗罪', amount = 12500000},
        {label = 'ボブキャット強盗罪', amount = 9375000},
        {label = '金庫強盗罪', amount = 16000000},
        {label = 'アーティファクト強盗罪', amount = 16000000},
        {label = 'メイズバンク強盗罪', amount = 16000000},
        {label = '飛行場襲撃強盗罪', amount = 18750000},
        {label = 'アンダーグラウンド強盗罪', amount = 18750000},
        {label = 'カジノ強盗罪', amount = 25000000},
        {label = 'ユニオン強盗罪', amount = 31250000},
        {label = 'パシフィック強盗罪', amount = 37500000},
        {label = '殺人罪', amount = 2000000},
        {label = '殺人未遂', amount = 1000000},
        {label = '公務執行妨害 (逃走含む)', amount = 1000000},
        {label = '銃刀法違反', amount = 1000000},
        {label = '車両窃盗', amount = 1000000},
        {label = 'わいせつ罪', amount = 300000000},
        {label = 'テロ罪', amount = 500000000},
    },
    ['ambulance'] = {
        {label = '院内治療', amount = 300000},
        {label = '院内蘇生', amount = 700000},
        {label = '院外治療', amount = 500000},
        {label = '院外蘇生', amount = 1000000},
        {label = '警察蘇生', amount = 600000},
        {label = '医者蘇生', amount = 600000},
        {label = '海難救助', amount = 1300000},
        {label = '山岳救助', amount = 1300000},
    }
}

-- メッセージ設定
Config.Messages = {
    invoice_created = '請求書を作成しました',
    invoice_received = '新しい請求書を受け取りました',
    invoice_paid = '請求書の支払いが完了しました',
    invoice_cancelled = '請求書をキャンセルしました',
    not_enough_money = '所持金が不足しています',
    invalid_target = '無効な請求先です',
    no_permission = '権限がありません',
    insufficient_funds = '対象者の所持金が不足しているため強制執行できません',
    force_payment_success = '強制執行が完了しました',
    force_payment_failed = '強制執行に失敗しました'
}

return Config