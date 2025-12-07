local QBCore = exports['qb-core']:GetCoreObject()

-- データベーステーブルの作成
CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS refund_history (
            id INT AUTO_INCREMENT PRIMARY KEY,
            admin_identifier VARCHAR(50) NOT NULL,
            admin_name VARCHAR(50) NOT NULL,
            target_identifier VARCHAR(50) NOT NULL,
            target_name VARCHAR(50) NOT NULL,
            type VARCHAR(10) NOT NULL,
            item_name VARCHAR(50),
            amount INT,
            vehicle_model VARCHAR(50),
            plate VARCHAR(8),
            claimed BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            deleted_at TIMESTAMP NULL
        )
    ]])
end)

-- 管理者権限チェック関数
local function isAdmin(source)
    if not source then return false end
    return IsPlayerAceAllowed(source, 'command.admin')
end

-- 管理者権限チェックのコールバック登録
lib.callback.register('ng-refund:server:isAdmin', function(source)
    return isAdmin(source)
end)

-- 車両検索のコールバック
lib.callback.register('ng-refund:server:SearchVehicles', function(source, searchTerm)
    if not isAdmin(source) then return {} end
    
    local vehicles = {}
    local searchTermLower = searchTerm and string.lower(searchTerm) or ''
    
    -- QBCore.Shared.Vehiclesから検索
    for vehicleModel, vehicleData in pairs(QBCore.Shared.Vehicles) do
        local vehicleNameLower = vehicleData.name and string.lower(vehicleData.name) or ''
        local vehicleModelLower = string.lower(vehicleModel)
        local vehicleBrandLower = vehicleData.brand and string.lower(vehicleData.brand) or ''
        
        -- 検索条件をチェック（空文字の場合は全車両表示）
        local matchesSearch = false
        if searchTerm == '' or searchTerm == nil then
            matchesSearch = true
        else
            matchesSearch = string.find(vehicleNameLower, searchTermLower) or 
                           string.find(vehicleModelLower, searchTermLower) or
                           string.find(vehicleBrandLower, searchTermLower)
        end
        
        if matchesSearch then
            table.insert(vehicles, {
                model = vehicleModel,
                name = vehicleData.name or vehicleModel,
                brand = vehicleData.brand,
                category = vehicleData.category,
                price = vehicleData.price,
                type = vehicleData.type
            })
        end
    end
    
    -- 検索結果を名前順でソート
    table.sort(vehicles, function(a, b)
        return string.lower(a.name) < string.lower(b.name)
    end)
    
    -- 最大件数に制限
    local maxResults = Config.Search.maxVehicleResults or 30
    if #vehicles > maxResults then
        local limitedVehicles = {}
        for i = 1, maxResults do
            table.insert(limitedVehicles, vehicles[i])
        end
        return limitedVehicles
    end
    
    return vehicles
end)
lib.callback.register('ng-refund:server:SearchItems', function(source, searchTerm)
    if not isAdmin(source) then return {} end
    
    if not searchTerm or searchTerm == '' then return {} end
    
    local items = {}
    local searchTermLower = string.lower(searchTerm)
    
    -- QBCore.Shared.Itemsから検索
    for itemName, itemData in pairs(QBCore.Shared.Items) do
        local itemNameLower = string.lower(itemName)
        local itemLabelLower = itemData.label and string.lower(itemData.label) or ''
        
        -- アイテム名またはラベルで検索
        if string.find(itemNameLower, searchTermLower) or 
           string.find(itemLabelLower, searchTermLower) then
            table.insert(items, {
                name = itemName,
                label = itemData.label or itemName,
                type = itemData.type or 'item',
                weight = itemData.weight,
                unique = itemData.unique,
                useable = itemData.useable,
                shouldClose = itemData.shouldClose,
                combinable = itemData.combinable,
                description = itemData.description
            })
        end
    end
    
    -- 検索結果をラベル順でソート
    table.sort(items, function(a, b)
        return string.lower(a.label) < string.lower(b.label)
    end)
    
    -- 最大50件に制限
    if #items > 50 then
        local limitedItems = {}
        for i = 1, 50 do
            table.insert(limitedItems, items[i])
        end
        return limitedItems
    end
    
    return items
end)
lib.callback.register('ng-refund:server:SearchPlayers', function(source, searchTerm)
    if not isAdmin(source) then return {} end
    
    if not searchTerm or searchTerm == '' then return {} end
    
    -- オンラインプレイヤーを検索
    local onlinePlayers = {}
    local allPlayers = QBCore.Functions.GetQBPlayers()
    
    for _, player in pairs(allPlayers) do
        local citizenId = player.PlayerData.citizenid
        local firstname = player.PlayerData.charinfo.firstname or ''
        local lastname = player.PlayerData.charinfo.lastname or ''
        local fullname = firstname .. ' ' .. lastname
        
        -- CitizenIDまたは名前で検索
        if string.find(string.lower(citizenId), string.lower(searchTerm)) or 
           string.find(string.lower(fullname), string.lower(searchTerm)) or
           string.find(string.lower(firstname), string.lower(searchTerm)) or
           string.find(string.lower(lastname), string.lower(searchTerm)) then
            table.insert(onlinePlayers, {
                citizenid = citizenId,
                name = fullname,
                online = true
            })
        end
    end
    
    -- オフラインプレイヤーをデータベースから検索（最大20件）
    local offlinePlayers = {}
    local dbResult = MySQL.query.await([[
        SELECT citizenid, charinfo 
        FROM players 
        WHERE (citizenid LIKE ? OR 
               JSON_EXTRACT(charinfo, '$.firstname') LIKE ? OR 
               JSON_EXTRACT(charinfo, '$.lastname') LIKE ? OR
               CONCAT(JSON_EXTRACT(charinfo, '$.firstname'), ' ', JSON_EXTRACT(charinfo, '$.lastname')) LIKE ?)
        ORDER BY CAST(JSON_EXTRACT(charinfo, '$.firstname') AS CHAR), CAST(JSON_EXTRACT(charinfo, '$.lastname') AS CHAR)
        LIMIT 20
    ]], {
        '%' .. searchTerm .. '%',
        '%' .. searchTerm .. '%', 
        '%' .. searchTerm .. '%',
        '%' .. searchTerm .. '%'
    })
    
    if dbResult and type(dbResult) == 'table' then
        for _, row in ipairs(dbResult) do
            local citizenId = row.citizenid
            local charinfo = json.decode(row.charinfo)
            local fullname = (charinfo.firstname or '') .. ' ' .. (charinfo.lastname or '')
            
            -- オンラインプレイヤーと重複しないかチェック
            local isOnline = false
            for _, onlinePlayer in ipairs(onlinePlayers) do
                if onlinePlayer.citizenid == citizenId then
                    isOnline = true
                    break
                end
            end
            
            if not isOnline then
                table.insert(offlinePlayers, {
                    citizenid = citizenId,
                    name = fullname,
                    online = false
                })
            end
        end
    end
    
    -- オンラインプレイヤーを先頭に、オフラインプレイヤーを後に結合
    local allResults = {}
    for _, player in ipairs(onlinePlayers) do
        table.insert(allResults, player)
    end
    for _, player in ipairs(offlinePlayers) do
        table.insert(allResults, player)
    end
    
    return allResults
end)

-- 補填履歴を取得するコールバック
lib.callback.register('ng-refund:server:GetRefundHistory', function(source)
    if not isAdmin(source) then return {} end

    local history = MySQL.query.await([[
        SELECT 
            id,
            admin_identifier,
            admin_name,
            target_identifier,
            target_name,
            type,
            COALESCE(item_name, '') as item_name,
            COALESCE(amount, 0) as amount,
            COALESCE(vehicle_model, '') as vehicle_model,
            COALESCE(plate, '') as plate,
            claimed,
            UNIX_TIMESTAMP(created_at) as created_at
        FROM refund_history
        WHERE deleted_at IS NULL 
        ORDER BY created_at DESC 
        LIMIT ?
    ]], {Config.History.maxDisplayCount})

    if type(history) ~= 'table' then return {} end
    return history
end)

-- プレートの生成と検証
local function GeneratePlate()
    local attempts = 0
    while attempts < 100 do
        local plate = string.format('ADM%05d', math.random(0, 99999))
        -- プレートの重複チェック（両方のテーブルで）
        local vehicleCheck = MySQL.query.await('SELECT 1 FROM player_vehicles WHERE plate = ?', {plate})
        local historyCheck = MySQL.query.await('SELECT 1 FROM refund_history WHERE plate = ? AND type = "vehicle"', {plate})
        
        if (not vehicleCheck or #vehicleCheck == 0) and (not historyCheck or #historyCheck == 0) then
            return plate
        end
        attempts = attempts + 1
    end
    
    -- フォールバックとして現在時刻を使用
    local fallbackPlate = string.format('ADM%05d', os.time() % 100000)
    return fallbackPlate
end

local function ValidatePlate(plate)
    if not plate or plate == '' then return false end
    if string.len(plate) > 8 then return false end
    return string.match(plate, "^[A-Za-z0-9]+$") ~= nil
end

-- アイテム補填処理
local function GiveItem(source, citizenId, itemName, amount)
    local admin = QBCore.Functions.GetPlayer(source)
    local target = QBCore.Functions.GetPlayerByCitizenId(citizenId)
    
    if not admin then return false end

    -- アイテムの存在確認
    local item = QBCore.Shared.Items[itemName]
    if not item then
        lib.notify(source, {
            description = '指定されたアイテムが存在しません',
            type = 'error'
        })
        return false
    end

    -- プレイヤーの情報確認
    local targetName
    if target then
        targetName = target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname
    else
        local result = MySQL.query.await('SELECT charinfo FROM players WHERE citizenid = ?', {citizenId})
        if not result or #result == 0 then
            lib.notify(source, {
                description = '指定されたCitizenIDのプレイヤーが見つかりません',
                type = 'error'
            })
            return false
        end
        local charinfo = json.decode(result[1].charinfo)
        targetName = charinfo.firstname .. ' ' .. charinfo.lastname
    end

    -- 履歴に記録
    local success = MySQL.insert.await('INSERT INTO refund_history (admin_identifier, admin_name, target_identifier, target_name, type, item_name, amount) VALUES (?, ?, ?, ?, ?, ?, ?)',
        {
            admin.PlayerData.citizenid,
            admin.PlayerData.charinfo.firstname .. ' ' .. admin.PlayerData.charinfo.lastname,
            citizenId,
            targetName,
            'item',
            itemName,
            amount
        }
    )

    if success then
        lib.notify(source, {
            description = string.format(Config.Notifications.success.description, targetName, itemName .. ' x' .. amount),
            type = 'success'
        })
        return true
    end

    lib.notify(source, Config.Notifications.error)
    return false
end

-- 車両補填処理
local function GiveVehicle(source, citizenId, vehicleModel, customPlate)
    local admin = QBCore.Functions.GetPlayer(source)
    local target = QBCore.Functions.GetPlayerByCitizenId(citizenId)
    
    if not admin then return false end

    -- 車両の存在確認
    local vehicle = QBCore.Shared.Vehicles[vehicleModel]
    if not vehicle then
        lib.notify(source, {
            description = '指定された車両が存在しません',
            type = 'error'
        })
        return false
    end

    -- プレイヤーの情報確認
    local targetName, targetLicense
    if target then
        targetName = target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname
        targetLicense = target.PlayerData.license
    else
        local result = MySQL.query.await('SELECT license, charinfo FROM players WHERE citizenid = ?', {citizenId})
        if not result or #result == 0 then
            lib.notify(source, {
                description = '指定されたCitizenIDのプレイヤーが見つかりません',
                type = 'error'
            })
            return false
        end
        local charinfo = json.decode(result[1].charinfo)
        targetName = charinfo.firstname .. ' ' .. charinfo.lastname
        targetLicense = result[1].license
    end

    -- ナンバープレートの処理
    local plate
    if customPlate and customPlate ~= '' and ValidatePlate(customPlate) then
        customPlate = string.upper(customPlate)
        -- カスタムプレートの重複チェック
        local plateCheckVehicles = MySQL.query.await('SELECT 1 FROM player_vehicles WHERE plate = ?', {customPlate})
        local plateCheckHistory = MySQL.query.await('SELECT 1 FROM refund_history WHERE plate = ? AND type = "vehicle"', {customPlate})
        
        if (plateCheckVehicles and #plateCheckVehicles > 0) or (plateCheckHistory and #plateCheckHistory > 0) then
            lib.notify(source, {
                description = '指定されたナンバープレートは既に使用されています',
                type = 'error'
            })
            return false
        end
        plate = customPlate
    else
        plate = GeneratePlate()
    end

    -- 車両プロップスの設定
    local props = {
        model = GetHashKey(vehicleModel),
        plate = plate,
        fuel = 100,
        bodyHealth = 1000.0,
        engineHealth = 1000.0,
        tankHealth = 1000.0,
        dirtLevel = 0.0
    }

    -- 補填履歴に記録
    local success = MySQL.insert.await('INSERT INTO refund_history (admin_identifier, admin_name, target_identifier, target_name, type, vehicle_model, plate) VALUES (?, ?, ?, ?, ?, ?, ?)',
        {
            admin.PlayerData.citizenid,
            admin.PlayerData.charinfo.firstname .. ' ' .. admin.PlayerData.charinfo.lastname,
            citizenId,
            targetName,
            'vehicle',
            vehicleModel,
            plate
        }
    )

    if success then
        local vehicleName = vehicle.name or vehicleModel
        lib.notify(source, {
            description = string.format(Config.Notifications.success.description, 
                targetName, 
                string.format('%s (%s) - ナンバー: %s', vehicleName, vehicleModel, plate)
            ),
            type = 'success'
        })
        return true
    end

    lib.notify(source, Config.Notifications.error)
    return false
end

-- イベントの登録
RegisterNetEvent('ng-refund:server:GiveItem')
AddEventHandler('ng-refund:server:GiveItem', function(citizenId, itemName, amount)
    local source = source
    if not isAdmin(source) then
        lib.notify(source, Config.Notifications.noPermission)
        return
    end

    GiveItem(source, citizenId, itemName, amount)
end)

RegisterNetEvent('ng-refund:server:GiveVehicle')
AddEventHandler('ng-refund:server:GiveVehicle', function(citizenId, vehicleModel, customPlate)
    local source = source
    if not isAdmin(source) then
        lib.notify(source, Config.Notifications.noPermission)
        return
    end

    GiveVehicle(source, citizenId, vehicleModel, customPlate)
end)

-- プレイヤーコマンド：補填を受け取る
RegisterCommand('refunds', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    -- 未受け取りの補填を取得
    local refunds = MySQL.query.await([[
        SELECT * FROM refund_history 
        WHERE target_identifier = ? 
        AND claimed = FALSE 
        AND deleted_at IS NULL
    ]], {Player.PlayerData.citizenid})

    if not refunds or #refunds == 0 then
        lib.notify(source, {
            description = '受け取り可能な補填はありません',
            type = 'error'
        })
        return
    end

    -- 各補填を処理
    for _, refund in ipairs(refunds) do
        if refund.type == 'item' then
            -- アイテムの付与
            if exports.ox_inventory:CanCarryItem(source, refund.item_name, refund.amount) then
                exports.ox_inventory:AddItem(source, refund.item_name, refund.amount)
                lib.notify(source, {
                    description = string.format('受け取り完了: %s x%d', 
                        QBCore.Shared.Items[refund.item_name].label, 
                        refund.amount
                    ),
                    type = 'success'
                })
            else
                lib.notify(source, {
                    description = string.format('インベントリに空きがありません: %s', 
                        QBCore.Shared.Items[refund.item_name].label
                    ),
                    type = 'error'
                })
                return -- インベントリが一杯なら処理を中断
            end
        elseif refund.type == 'vehicle' then
            -- プレートの最終確認
            local plateCheck = MySQL.query.await('SELECT 1 FROM player_vehicles WHERE plate = ?', {refund.plate})
            if plateCheck and #plateCheck > 0 then
                -- プレートが重複している場合は新しいプレートを生成
                refund.plate = GeneratePlate()
            end

            -- 車両の付与
            local props = {
                model = GetHashKey(refund.vehicle_model),
                plate = refund.plate,
                fuel = 100,
                bodyHealth = 1000.0,
                engineHealth = 1000.0,
                tankHealth = 1000.0,
                dirtLevel = 0.0
            }

            MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, plate, hash, mods, garage, fuel, engine, body, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            {
                Player.PlayerData.license,
                Player.PlayerData.citizenid,
                refund.vehicle_model,
                refund.plate,
                props.model,
                json.encode(props),
                'pillboxgarage',
                props.fuel,
                props.engineHealth,
                props.bodyHealth,
                1
            })

            lib.notify(source, {
                description = string.format('受け取り完了: %s (ナンバー: %s)', 
                    refund.vehicle_model, 
                    refund.plate
                ),
                type = 'success'
            })
        end

        -- 補填を受け取り済みとしてマーク
        MySQL.update('UPDATE refund_history SET claimed = TRUE WHERE id = ?', {refund.id})
    end
end)