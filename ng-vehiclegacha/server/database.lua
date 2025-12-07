-- データベーステーブル自動作成
local function createTables()
    -- ガチャ設定テーブル
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ng_vehiclegacha_settings` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `gacha_type` VARCHAR(50) NOT NULL UNIQUE,
            `label` VARCHAR(100) NOT NULL,
            `enabled` TINYINT(1) DEFAULT 1,
            `price_money` INT DEFAULT 10000,
            `price_ticket` INT DEFAULT 1,
            `icon` VARCHAR(50) DEFAULT 'fa-solid fa-car',
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    -- 車両リストテーブル
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ng_vehiclegacha_vehicles` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `gacha_type` VARCHAR(50) NOT NULL,
            `vehicle_model` VARCHAR(50) NOT NULL,
            `vehicle_label` VARCHAR(100) NOT NULL,
            `rarity` VARCHAR(20) NOT NULL,
            `enabled` TINYINT(1) DEFAULT 1,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_gacha_type` (`gacha_type`),
            INDEX `idx_rarity` (`rarity`),
            INDEX `idx_enabled` (`enabled`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    -- ガチャ履歴テーブル
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ng_vehiclegacha_history` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `citizenid` VARCHAR(50) NOT NULL,
            `player_name` VARCHAR(100),
            `gacha_type` VARCHAR(50) NOT NULL,
            `vehicle_model` VARCHAR(50) NOT NULL,
            `vehicle_label` VARCHAR(100) NOT NULL,
            `rarity` VARCHAR(20) NOT NULL,
            `payment_type` VARCHAR(20) NOT NULL,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_citizenid` (`citizenid`),
            INDEX `idx_gacha_type` (`gacha_type`),
            INDEX `idx_created_at` (`created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    -- プレイヤーチケット所持数テーブル
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ng_vehiclegacha_tickets` (
            `citizenid` VARCHAR(50) PRIMARY KEY,
            `tickets` INT DEFAULT 0,
            `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    print('^2[ng-vehiclegacha]^7 データベーステーブルを確認/作成しました')
end

-- 初期データ投入
local function insertInitialData()
    -- ガチャ設定の初期データ確認
    local result = MySQL.query.await('SELECT COUNT(*) as count FROM ng_vehiclegacha_settings')
    
    if result[1].count == 0 then
        -- ガチャタイプの初期データ
        MySQL.insert([[
            INSERT INTO ng_vehiclegacha_settings (gacha_type, label, enabled, price_money, price_ticket, icon) VALUES
            ('sports', 'スポーツカー', 1, 50000, 1, 'fa-solid fa-car-side'),
            ('luxury', '高級車', 1, 100000, 2, 'fa-solid fa-gem'),
            ('offroad', 'オフロード', 1, 30000, 1, 'fa-solid fa-truck-monster'),
            ('super', 'スーパーカー', 1, 200000, 3, 'fa-solid fa-rocket')
        ]])
        print('^2[ng-vehiclegacha]^7 ガチャタイプの初期データを投入しました')
    end

    -- 車両データの初期データ確認
    local vehicleResult = MySQL.query.await('SELECT COUNT(*) as count FROM ng_vehiclegacha_vehicles')
    
    if vehicleResult[1].count == 0 then
        -- サンプル車両データ
        MySQL.insert([[
            INSERT INTO ng_vehiclegacha_vehicles (gacha_type, vehicle_model, vehicle_label, rarity, enabled) VALUES
            -- スポーツカー
            ('sports', 'sultan', 'Karin Sultan', 'Common', 1),
            ('sports', 'futo', 'Karin Futo', 'Common', 1),
            ('sports', 'penumbra', 'Maibatsu Penumbra', 'Common', 1),
            ('sports', 'elegy2', 'Annis Elegy RH8', 'Rare', 1),
            ('sports', 'jester', 'Dinka Jester', 'Rare', 1),
            ('sports', 'massacro', 'Dewbauchee Massacro', 'SuperRare', 1),
            ('sports', 'carbonizzare', 'Grotti Carbonizzare', 'SuperRare', 1),
            ('sports', 'italigtb', 'Progen Itali GTB', 'UltraRare', 1),
            
            -- 高級車
            ('luxury', 'cognoscenti', 'Enus Cognoscenti', 'Common', 1),
            ('luxury', 'schafter2', 'Benefactor Schafter', 'Common', 1),
            ('luxury', 'superd', 'Enus Super Diamond', 'Rare', 1),
            ('luxury', 'windsor', 'Enus Windsor', 'Rare', 1),
            ('luxury', 'cognoscenti2', 'Enus Cognoscenti 55', 'SuperRare', 1),
            ('luxury', 'luxor', 'Luxor Deluxe', 'UltraRare', 1),
            
            -- オフロード
            ('offroad', 'bison', 'Bravado Bison', 'Common', 1),
            ('offroad', 'bodhi2', 'Canis Bodhi', 'Common', 1),
            ('offroad', 'dubsta3', 'Benefactor Dubsta 6x6', 'Rare', 1),
            ('offroad', 'sandking', 'Vapid Sandking XL', 'Rare', 1),
            ('offroad', 'rebel2', 'Karin Rebel', 'SuperRare', 1),
            ('offroad', 'trophy', 'Vapid Trophy Truck', 'UltraRare', 1),
            
            -- スーパーカー
            ('super', 'banshee2', 'Bravado Banshee 900R', 'Common', 1),
            ('super', 'bullet', 'Vapid Bullet', 'Rare', 1),
            ('super', 'cheetah', 'Grotti Cheetah', 'Rare', 1),
            ('super', 'entityxf', 'Progen Entity XF', 'SuperRare', 1),
            ('super', 'turismor', 'Grotti Turismo R', 'SuperRare', 1),
            ('super', 't20', 'Progen T20', 'UltraRare', 1),
            ('super', 'zentorno', 'Pegassi Zentorno', 'UltraRare', 1)
        ]])
        print('^2[ng-vehiclegacha]^7 車両の初期データを投入しました')
    end
end

-- リソース起動時に実行
CreateThread(function()
    createTables()
    Wait(1000) -- テーブル作成を待つ
    insertInitialData()
end)

-- ============================================
-- データベース操作関数
-- ============================================

-- ガチャタイプ一覧取得
function GetGachaTypes()
    return MySQL.query.await('SELECT * FROM ng_vehiclegacha_settings WHERE enabled = 1')
end

-- 特定のガチャタイプ取得
function GetGachaType(gachaType)
    local result = MySQL.query.await('SELECT * FROM ng_vehiclegacha_settings WHERE gacha_type = ? AND enabled = 1', {gachaType})
    return result[1]
end

-- ガチャの有効/無効切り替え
function ToggleGacha(gachaType, enabled)
    MySQL.update.await('UPDATE ng_vehiclegacha_settings SET enabled = ? WHERE gacha_type = ?', {enabled, gachaType})
end

-- 車両リスト取得(ガチャタイプ別)
function GetVehiclesByGachaType(gachaType)
    return MySQL.query.await('SELECT * FROM ng_vehiclegacha_vehicles WHERE gacha_type = ? AND enabled = 1', {gachaType})
end

-- レアリティ別車両取得
function GetVehiclesByRarity(gachaType, rarity)
    return MySQL.query.await('SELECT * FROM ng_vehiclegacha_vehicles WHERE gacha_type = ? AND rarity = ? AND enabled = 1', {gachaType, rarity})
end

-- 車両追加
function AddVehicle(gachaType, vehicleModel, vehicleLabel, rarity)
    MySQL.insert.await('INSERT INTO ng_vehiclegacha_vehicles (gacha_type, vehicle_model, vehicle_label, rarity) VALUES (?, ?, ?, ?)', 
        {gachaType, vehicleModel, vehicleLabel, rarity})
end

-- 車両削除
function RemoveVehicle(vehicleId)
    MySQL.execute.await('DELETE FROM ng_vehiclegacha_vehicles WHERE id = ?', {vehicleId})
end

-- 車両有効/無効切り替え
function ToggleVehicle(vehicleId, enabled)
    MySQL.update.await('UPDATE ng_vehiclegacha_vehicles SET enabled = ? WHERE id = ?', {enabled, vehicleId})
end

-- ガチャ履歴追加
function AddGachaHistory(citizenid, playerName, gachaType, vehicleModel, vehicleLabel, rarity, paymentType)
    MySQL.insert('INSERT INTO ng_vehiclegacha_history (citizenid, player_name, gacha_type, vehicle_model, vehicle_label, rarity, payment_type) VALUES (?, ?, ?, ?, ?, ?, ?)',
        {citizenid, playerName, gachaType, vehicleModel, vehicleLabel, rarity, paymentType})
end

-- ガチャ履歴取得(プレイヤー別)
function GetPlayerHistory(citizenid, limit)
    limit = limit or 50
    return MySQL.query.await('SELECT * FROM ng_vehiclegacha_history WHERE citizenid = ? ORDER BY created_at DESC LIMIT ?', {citizenid, limit})
end

-- ガチャ履歴取得(全体)
function GetAllHistory(limit)
    limit = limit or 100
    return MySQL.query.await('SELECT * FROM ng_vehiclegacha_history ORDER BY created_at DESC LIMIT ?', {limit})
end

-- チケット数取得
function GetPlayerTickets(citizenid)
    local result = MySQL.query.await('SELECT tickets FROM ng_vehiclegacha_tickets WHERE citizenid = ?', {citizenid})
    if result[1] then
        return result[1].tickets
    end
    return 0
end

-- チケット追加
function AddPlayerTickets(citizenid, amount)
    MySQL.query([[
        INSERT INTO ng_vehiclegacha_tickets (citizenid, tickets) 
        VALUES (?, ?) 
        ON DUPLICATE KEY UPDATE tickets = tickets + ?
    ]], {citizenid, amount, amount})
end

-- チケット使用
function UsePlayerTicket(citizenid, amount)
    local currentTickets = GetPlayerTickets(citizenid)
    if currentTickets >= amount then
        MySQL.execute.await('UPDATE ng_vehiclegacha_tickets SET tickets = tickets - ? WHERE citizenid = ?', {amount, citizenid})
        return true
    end
    return false
end

-- ガチャ統計取得
function GetGachaStats(gachaType)
    local total = MySQL.query.await('SELECT COUNT(*) as count FROM ng_vehiclegacha_history WHERE gacha_type = ?', {gachaType})
    local byRarity = MySQL.query.await([[
        SELECT rarity, COUNT(*) as count 
        FROM ng_vehiclegacha_history 
        WHERE gacha_type = ? 
        GROUP BY rarity
    ]], {gachaType})
    
    return {
        total = total[1].count,
        byRarity = byRarity
    }
end
