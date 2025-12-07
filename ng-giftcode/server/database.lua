-- データベース自動セットアップ
local function setupDatabase()
    print('^3[ng-giftcode]^7 データベースのセットアップを開始します...')
    
    -- giftcodesテーブル作成
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `giftcodes` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `code` varchar(50) NOT NULL,
            `items` longtext DEFAULT NULL,
            `money_type` varchar(20) DEFAULT NULL,
            `money_amount` int(11) DEFAULT 0,
            `vehicle` varchar(50) DEFAULT NULL,
            `max_uses` int(11) DEFAULT 1,
            `current_uses` int(11) DEFAULT 0,
            `expire_date` datetime DEFAULT NULL,
            `one_per_player` tinyint(1) DEFAULT 0,
            `allowed_identifiers` longtext DEFAULT NULL,
            `is_active` tinyint(1) DEFAULT 1,
            `created_by` varchar(50) DEFAULT NULL,
            `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `code` (`code`),
            KEY `is_active` (`is_active`),
            KEY `expire_date` (`expire_date`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {}, function(success)
        if success then
            print('^2[ng-giftcode]^7 giftcodesテーブルのセットアップが完了しました')
        else
            print('^1[ng-giftcode]^7 giftcodesテーブルの作成に失敗しました')
        end
    end)
    
    -- giftcode_logsテーブル作成
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `giftcode_logs` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `code` varchar(50) NOT NULL,
            `identifier` varchar(50) NOT NULL,
            `player_name` varchar(100) DEFAULT NULL,
            `license` varchar(100) DEFAULT NULL,
            `rewards` longtext DEFAULT NULL,
            `used_at` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `code` (`code`),
            KEY `identifier` (`identifier`),
            KEY `used_at` (`used_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {}, function(success)
        if success then
            print('^2[ng-giftcode]^7 giftcode_logsテーブルのセットアップが完了しました')
            print('^2[ng-giftcode]^7 データベースのセットアップが完了しました！')
        else
            print('^1[ng-giftcode]^7 giftcode_logsテーブルの作成に失敗しました')
        end
    end)
end

-- リソース起動時に実行
CreateThread(function()
    Wait(1000) -- oxmysqlの初期化を待つ
    setupDatabase()
end)
