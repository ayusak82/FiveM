local QBCore = exports['qb-core']:GetCoreObject()

-- 日時フォーマット関数
local function formatDateTime(timestamp)
    if not timestamp then return '' end
    
    -- UNIX時間の場合
    if type(timestamp) == 'number' then
        local date = os.date('*t', timestamp / 1000) -- ミリ秒を秒に変換
        return string.format('%04d年%02d月%02d日 %02d:%02d:%02d', 
            date.year, date.month, date.day, date.hour, date.min, date.sec)
    end
    
    -- 文字列の場合（MySQL datetime形式）
    local year, month, day, hour, min, sec = string.match(tostring(timestamp), '(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)')
    if year then
        return string.format('%s年%s月%s日 %s:%s:%s', year, month, day, hour, min, sec)
    end
    
    return tostring(timestamp)
end

-- 警察職チェック関数
local function isPolice(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    return Player.PlayerData.job.name == 'police'
end

-- ボスチェック関数
local function isBoss(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    return Player.PlayerData.job.name == 'police' and Player.PlayerData.job.isboss == true
end

-- オンライン警察官取得
QBCore.Functions.CreateCallback('ng-mdt:server:getOnlineOfficers', function(source, cb)
    if not isPolice(source) then
        cb({})
        return
    end
    
    local officers = {}
    local players = QBCore.Functions.GetQBPlayers()
    
    for src, Player in pairs(players) do
        if Player.PlayerData.job.name == 'police' then
            table.insert(officers, {
                source = src,
                citizenid = Player.PlayerData.citizenid,
                name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
            })
        end
    end
    
    cb(officers)
end)

-- オンライン全プレイヤー取得
QBCore.Functions.CreateCallback('ng-mdt:server:getOnlinePlayers', function(source, cb)
    if not isPolice(source) then
        cb({})
        return
    end
    
    local players = {}
    local allPlayers = QBCore.Functions.GetQBPlayers()
    
    for src, Player in pairs(allPlayers) do
        table.insert(players, {
            source = src,
            citizenid = Player.PlayerData.citizenid,
            name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        })
    end
    
    cb(players)
end)

-- 記録作成
QBCore.Functions.CreateCallback('ng-mdt:server:createRecord', function(source, cb, data)
    if not isPolice(source) then
        cb(false)
        return
    end
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(false)
        return
    end
    
    local officersJson = json.encode(data.officers)
    local crimesJson = json.encode(data.crimes)
    local criminalsJson = json.encode(data.criminals)
    local createdBy = Player.PlayerData.citizenid
    
    MySQL.insert('INSERT INTO `ng-mdt` (officers, crimes, fine_amount, criminals, notes, created_by) VALUES (?, ?, ?, ?, ?, ?)', {
        officersJson,
        crimesJson,
        data.fine_amount,
        criminalsJson,
        data.notes,
        createdBy
    }, function(id)
        if id then
            cb(true)
        else
            cb(false)
        end
    end)
end)

-- 記録検索
QBCore.Functions.CreateCallback('ng-mdt:server:searchRecords', function(source, cb, searchData)
    if not isPolice(source) then
        cb({})
        return
    end
    
    -- ベースクエリ
    local query = 'SELECT *, UNIX_TIMESTAMP(created_at) * 1000 as created_timestamp, UNIX_TIMESTAMP(updated_at) * 1000 as updated_timestamp FROM `ng-mdt` WHERE 1=1'
    local params = {}
    
    -- 警察官で検索
    if searchData.officer and searchData.officer ~= '' then
        query = query .. ' AND officers LIKE ?'
        table.insert(params, '%' .. searchData.officer .. '%')
    end
    
    -- 犯人で検索
    if searchData.criminal and searchData.criminal ~= '' then
        query = query .. ' AND criminals LIKE ?'
        table.insert(params, '%' .. searchData.criminal .. '%')
    end
    
    -- 罪状で検索
    if searchData.crime and searchData.crime ~= '' then
        query = query .. ' AND crimes LIKE ?'
        table.insert(params, '%' .. searchData.crime .. '%')
    end
    
    -- 開始日で検索
    if searchData.date_start and searchData.date_start ~= '' then
        query = query .. ' AND DATE(created_at) >= ?'
        table.insert(params, searchData.date_start)
    end
    
    -- 終了日で検索
    if searchData.date_end and searchData.date_end ~= '' then
        query = query .. ' AND DATE(created_at) <= ?'
        table.insert(params, searchData.date_end)
    end
    
    -- 備考で検索
    if searchData.notes and searchData.notes ~= '' then
        query = query .. ' AND notes LIKE ?'
        table.insert(params, '%' .. searchData.notes .. '%')
    end
    
    -- 日付降順でソート
    query = query .. ' ORDER BY created_at DESC'
    
    MySQL.query(query, params, function(results)
        if results then
            local records = {}
            for _, row in ipairs(results) do
                table.insert(records, {
                    id = row.id,
                    officers = json.decode(row.officers),
                    crimes = json.decode(row.crimes),
                    fine_amount = row.fine_amount,
                    criminals = json.decode(row.criminals),
                    notes = row.notes,
                    created_by = row.created_by,
                    created_at = formatDateTime(row.created_at),
                    updated_at = formatDateTime(row.updated_at)
                })
            end
            cb(records)
        else
            cb({})
        end
    end)
end)

-- 記録更新
QBCore.Functions.CreateCallback('ng-mdt:server:updateRecord', function(source, cb, data)
    if not isPolice(source) then
        cb(false)
        return
    end
    
    local officersJson = json.encode(data.officers)
    local crimesJson = json.encode(data.crimes)
    local criminalsJson = json.encode(data.criminals)
    
    MySQL.update('UPDATE `ng-mdt` SET officers = ?, crimes = ?, fine_amount = ?, criminals = ?, notes = ? WHERE id = ?', {
        officersJson,
        crimesJson,
        data.fine_amount,
        criminalsJson,
        data.notes,
        data.id
    }, function(affectedRows)
        if affectedRows > 0 then
            cb(true)
        else
            cb(false)
        end
    end)
end)

-- 記録削除
QBCore.Functions.CreateCallback('ng-mdt:server:deleteRecord', function(source, cb, recordId)
    if not isBoss(source) then
        cb(false)
        return
    end
    
    MySQL.query('DELETE FROM `ng-mdt` WHERE id = ?', {recordId}, function(result)
        if result and result.affectedRows and result.affectedRows > 0 then
            cb(true)
        else
            cb(false)
        end
    end)
end)

-- 車両照会
QBCore.Functions.CreateCallback('ng-mdt:server:searchVehicle', function(source, cb, plate)
    if not isPolice(source) then
        cb(nil)
        return
    end
    
    -- ナンバープレートを大文字に変換してトリム
    plate = string.gsub(string.upper(plate), '%s+', '')
    
    -- player_vehiclesテーブルから車両情報を取得
    MySQL.query('SELECT * FROM player_vehicles WHERE plate = ?', {plate}, function(result)
        if result and result[1] then
            local vehicle = result[1]
            
            -- 車両ハッシュから車両名を取得
            local vehicleModel = 'Unknown'
            if vehicle.hash then
                -- まずQBCore.Shared.Vehiclesから検索
                for modelName, vehicleData in pairs(QBCore.Shared.Vehicles) do
                    if GetHashKey(modelName) == tonumber(vehicle.hash) then
                        vehicleModel = vehicleData.name or vehicleData.brand .. ' ' .. vehicleData.model or modelName
                        break
                    end
                end
                
                -- 見つからない場合はハッシュ値を表示
                if vehicleModel == 'Unknown' then
                    vehicleModel = 'Hash: ' .. vehicle.hash
                end
            end
            
            -- modsデータのデコード（カラー情報など）
            local modsData = {}
            local colorStr = 'Unknown'
            if vehicle.mods and vehicle.mods ~= '' then
                local success, decoded = pcall(json.decode, vehicle.mods)
                if success and decoded then
                    modsData = decoded
                    -- カラー情報を取得
                    if modsData.color1 then
                        colorStr = 'Primary: ' .. tostring(modsData.color1)
                        if modsData.color2 then
                            colorStr = colorStr .. ', Secondary: ' .. tostring(modsData.color2)
                        end
                    end
                end
            end
            
            -- 所有者情報を取得
            MySQL.query('SELECT charinfo FROM players WHERE citizenid = ?', {vehicle.citizenid}, function(ownerResult)
                local ownerName = Config.Locale.vehicle_no_owner
                
                if ownerResult and ownerResult[1] and ownerResult[1].charinfo then
                    local success, charinfo = pcall(json.decode, ownerResult[1].charinfo)
                    if success and charinfo then
                        ownerName = (charinfo.firstname or '') .. ' ' .. (charinfo.lastname or '')
                    end
                end
                
                -- 車両情報を返す
                cb({
                    model = vehicleModel,
                    plate = vehicle.plate or plate,
                    owner = ownerName,
                    citizenid = vehicle.citizenid or 'Unknown',
                    color = colorStr,
                    mods = modsData
                })
            end)
        else
            cb(nil)
        end
    end)
end)

-- ============================================
-- プロファイル管理
-- ============================================

-- プロファイル作成
QBCore.Functions.CreateCallback('ng-mdt:server:createProfile', function(source, cb, data)
    if not isPolice(source) then
        cb(false, 'no_permission')
        return
    end
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(false, 'error')
        return
    end
    
    -- CitizenIDから名前を取得
    MySQL.query('SELECT charinfo FROM players WHERE citizenid = ?', {data.citizenid}, function(result)
        local playerName = 'Unknown'
        if result and result[1] and result[1].charinfo then
            local success, charinfo = pcall(json.decode, result[1].charinfo)
            if success and charinfo then
                playerName = (charinfo.firstname or '') .. ' ' .. (charinfo.lastname or '')
            end
        end
        
        -- プロファイルを作成
        MySQL.insert([[
            INSERT INTO `ng-mdt-profiles` 
            (citizenid, fingerprint, name, alias, dob, gender, nationality, danger_level, organization, known_locations, notes, photo_url, wanted, created_by) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]], {
            data.citizenid,
            data.fingerprint,
            playerName,
            data.alias or '',
            data.dob or '',
            data.gender or '',
            data.nationality or '',
            data.danger_level or '',
            data.organization or '',
            data.known_locations or '',
            data.notes or '',
            data.photo_url or '',
            data.wanted and 1 or 0,
            Player.PlayerData.citizenid
        }, function(id)
            if id then
                cb(true, 'success')
            else
                cb(false, 'exists')
            end
        end)
    end)
end)

-- プロファイル検索
QBCore.Functions.CreateCallback('ng-mdt:server:searchProfiles', function(source, cb, searchData)
    if not isPolice(source) then
        cb({})
        return
    end
    
    local query = 'SELECT * FROM `ng-mdt-profiles` WHERE 1=1'
    local params = {}
    
    if searchData.citizenid and searchData.citizenid ~= '' then
        query = query .. ' AND citizenid LIKE ?'
        table.insert(params, '%' .. searchData.citizenid .. '%')
    end
    
    if searchData.name and searchData.name ~= '' then
        query = query .. ' AND name LIKE ?'
        table.insert(params, '%' .. searchData.name .. '%')
    end
    
    if searchData.danger_level and searchData.danger_level ~= '' then
        query = query .. ' AND danger_level = ?'
        table.insert(params, searchData.danger_level)
    end
    
    if searchData.organization and searchData.organization ~= '' then
        query = query .. ' AND organization LIKE ?'
        table.insert(params, '%' .. searchData.organization .. '%')
    end
    
    if searchData.wanted_only then
        query = query .. ' AND wanted = 1'
    end
    
    query = query .. ' ORDER BY updated_at DESC'
    
    MySQL.query(query, params, function(results)
        if results then
            cb(results)
        else
            cb({})
        end
    end)
end)

-- プロファイル詳細取得
QBCore.Functions.CreateCallback('ng-mdt:server:getProfile', function(source, cb, citizenid)
    if not isPolice(source) then
        cb(nil)
        return
    end
    
    MySQL.query('SELECT * FROM `ng-mdt-profiles` WHERE citizenid = ?', {citizenid}, function(result)
        if result and result[1] then
            local profile = result[1]
            
            -- 所有車両を取得
            MySQL.query('SELECT plate, hash FROM player_vehicles WHERE citizenid = ?', {citizenid}, function(vehicles)
                local vehicleList = {}
                if vehicles then
                    for _, v in ipairs(vehicles) do
                        local vehicleModel = 'Unknown'
                        if v.hash then
                            for modelName, vehicleData in pairs(QBCore.Shared.Vehicles) do
                                if GetHashKey(modelName) == tonumber(v.hash) then
                                    vehicleModel = vehicleData.name or modelName
                                    break
                                end
                            end
                        end
                        table.insert(vehicleList, {
                            plate = v.plate,
                            model = vehicleModel
                        })
                    end
                end
                
                profile.vehicles = vehicleList
                profile.wanted = profile.wanted == 1
                cb(profile)
            end)
        else
            cb(nil)
        end
    end)
end)

-- プロファイル更新
QBCore.Functions.CreateCallback('ng-mdt:server:updateProfile', function(source, cb, data)
    if not isPolice(source) then
        cb(false)
        return
    end
    
    MySQL.update([[
        UPDATE `ng-mdt-profiles` 
        SET fingerprint = ?, alias = ?, dob = ?, gender = ?, nationality = ?, 
            danger_level = ?, organization = ?, known_locations = ?, notes = ?, 
            photo_url = ?, wanted = ?
        WHERE citizenid = ?
    ]], {
        data.fingerprint,
        data.alias or '',
        data.dob or '',
        data.gender or '',
        data.nationality or '',
        data.danger_level or '',
        data.organization or '',
        data.known_locations or '',
        data.notes or '',
        data.photo_url or '',
        data.wanted and 1 or 0,
        data.citizenid
    }, function(affectedRows)
        if affectedRows > 0 then
            cb(true)
        else
            cb(false)
        end
    end)
end)

-- プロファイル削除
QBCore.Functions.CreateCallback('ng-mdt:server:deleteProfile', function(source, cb, citizenid)
    if not isBoss(source) then
        cb(false)
        return
    end
    
    MySQL.query('DELETE FROM `ng-mdt-profiles` WHERE citizenid = ?', {citizenid}, function(result)
        if result and result.affectedRows and result.affectedRows > 0 then
            cb(true)
        else
            cb(false)
        end
    end)
end)

-- リソース開始時にテーブル作成
MySQL.ready(function()
    -- MDT記録テーブル
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ng-mdt` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `officers` longtext DEFAULT NULL COMMENT 'JSON: 対応警察官リスト',
            `crimes` longtext DEFAULT NULL COMMENT 'JSON: 罪状リスト',
            `fine_amount` int(11) DEFAULT 0 COMMENT '一人当たりの罰金額',
            `criminals` longtext DEFAULT NULL COMMENT 'JSON: 犯人リスト',
            `notes` longtext DEFAULT NULL COMMENT '備考',
            `created_by` varchar(50) DEFAULT NULL COMMENT '作成者のCitizenID',
            `created_at` timestamp NULL DEFAULT current_timestamp(),
            `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    -- プロファイルテーブル
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ng-mdt-profiles` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `citizenid` varchar(50) NOT NULL,
            `fingerprint` varchar(255) NOT NULL,
            `name` varchar(255) DEFAULT NULL,
            `alias` varchar(255) DEFAULT NULL,
            `dob` varchar(50) DEFAULT NULL,
            `gender` varchar(50) DEFAULT NULL,
            `nationality` varchar(100) DEFAULT NULL,
            `danger_level` varchar(20) DEFAULT NULL,
            `organization` varchar(255) DEFAULT NULL,
            `known_locations` text DEFAULT NULL,
            `notes` longtext DEFAULT NULL,
            `photo_url` varchar(500) DEFAULT NULL,
            `wanted` tinyint(1) DEFAULT 0,
            `created_by` varchar(50) DEFAULT NULL,
            `created_at` timestamp NULL DEFAULT current_timestamp(),
            `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
            PRIMARY KEY (`id`),
            UNIQUE KEY `citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    print('^2[ng-mdt]^7 Database tables initialized')
end)