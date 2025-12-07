Config = {}

-- Discord Webhook URL("https://discord.webhook") または false
Config.Webhook = false

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
    ['police'] = true,
    ['ambulance'] = true,
}

-- 職業ごとの収入分配率設定（%） - 設定された%が職業口座に入金
Config.JobPaymentRatio = {
    ['police'] = 50,     -- 50%が職業口座、50%が個人の手持ち
    ['ambulance'] = 50,  -- 50%が職業口座、50%が個人の手持ち
}

-- 職業ごとの請求内容プリセット
Config.JobInvoicePresets = {
    ['police'] = {
        {label = '道路交通法違反', amount = 100000},
        {label = '公務執行妨害', amount = 100000},
    },
    ['ambulance'] = {
        {label = 'ケガ治療', amount = 150000},
        {label = '院内蘇生', amount = 300000},
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