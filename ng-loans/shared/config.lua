Config = {}

-- ローンNPCの位置と情報
Config.LoanNPC = {
    model = "a_m_y_business_03", -- NPCのモデル
    position = vector4(-554.01, -193.7, 38.23, 229.24), -- 市役所の位置
    scenario = "WORLD_HUMAN_CLIPBOARD", -- NPCのアニメーション
    label = "ローン担当者"
}

-- ローン設定
Config.Loans = {
    -- 通常ローン
    standard = {
        minAmount = 5000,
        maxAmount = 50000,
        interestRate = 0.05, -- 5%
        maxDays = 7, -- 最大返済期間（日）
        lateFeeDailyRate = 0.02 -- 返済期限超過時の日割り追加利息（2%）
    },
    
    -- 車両担保ローン
    vehicle = {
        interestRate = 0.03, -- 3%
        maxDays = 14, -- 最大返済期間（日）
        lateFeeDailyRate = 0.015, -- 返済期限超過時の日割り追加利息（1.5%）
        vehicleClasses = { -- 車のクラスごとの最大ローン額
            [0] = 25000,   -- Compacts
            [1] = 35000,   -- Sedans
            [2] = 40000,   -- SUVs
            [3] = 30000,   -- Coupes
            [4] = 45000,   -- Muscle
            [5] = 50000,   -- Sports Classics
            [6] = 65000,   -- Sports
            [7] = 100000,  -- Super
            [8] = 15000,   -- Motorcycles
            [9] = 35000,   -- Off-road
            [10] = 45000,  -- Industrial
            [11] = 25000,  -- Utility
            [12] = 35000,  -- Vans
            [13] = 10000,  -- Cycles
            [14] = 20000,  -- Boats
            [15] = 150000, -- Helicopters
            [16] = 250000, -- Planes
            [17] = 40000,  -- Service
            [18] = 10000,  -- Emergency
            [19] = 75000,  -- Military
            [20] = 150000, -- Commercial
            [21] = 0       -- Trains (利用不可)
        }
    }
}

-- ローンのステータス
Config.LoanStatus = {
    ACTIVE = 0,    -- アクティブ
    PAID = 1,      -- 完済
    DEFAULTED = 2, -- 債務不履行
    SEIZED = 3     -- 担保没収済み
}

-- データベーステーブル名
Config.DatabaseTables = {
    loans = "ng_loans",
    vehicleLoans = "ng_vehicle_loans"
}

-- 通知設定
Config.Notifications = {
    loanCreated = {
        title = "ローン申請完了",
        description = "ローンが承認されました。%s ドルが口座に振り込まれました。",
        type = "success"
    },
    loanRepaid = {
        title = "ローン返済完了",
        description = "ローンが完済されました。",
        type = "success"
    },
    insufficientFunds = {
        title = "返済失敗",
        description = "口座残高が不足しています。",
        type = "error"
    },
    vehicleLoanCreated = {
        title = "車両担保ローン申請完了",
        description = "担保ローンが承認されました。%s ドルが口座に振り込まれました。",
        type = "success"
    },
    vehicleNotOwned = {
        title = "担保設定エラー",
        description = "この車両はあなたの所有物ではありません。",
        type = "error"
    },
    vehicleAlreadyLoaned = {
        title = "担保設定エラー",
        description = "この車両は既に担保に設定されています。",
        type = "error"
    },
    loanDefaultWarning = {
        title = "ローン返済期限警告",
        description = "あなたのローンの返済期限が近づいています。今すぐ返済してください。",
        type = "warning"
    },
    vehicleSeized = {
        title = "車両担保没収",
        description = "ローン滞納により、担保車両が没収されました。",
        type = "error"
    },
    vehicleReleased = {
        title = "車両担保解除",
        description = "ローンが完済され、車両の担保が解除されました。",
        type = "success"
    },
    vehicleImpounded = {
        title = "車両担保設定",
        description = "車両が担保に設定され、ローン返済まで使用できません。",
        type = "info"
    }
}