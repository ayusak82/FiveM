local QBCore = exports['qb-core']:GetCoreObject()

-- 管理者権限チェック関数
local function isAdmin(source)
    if not source then return false end
    return IsPlayerAceAllowed(source, 'command.admin')
end

-- 管理者権限チェックのコールバック登録
lib.callback.register('ng-vehiclegacha:server:isAdmin', function(source)
    return isAdmin(source)
end)

-- ============================================
-- ガチャタイプ一覧取得
-- ============================================
lib.callback.register('ng-vehiclegacha:server:getGachaTypes', function(source)
    return GetGachaTypes()
end)

-- ============================================
-- レアリティ抽選関数
-- ============================================
local function rollRarity()
    local rand = math.random(1, 100)
    local accumulated = 0
    
    for _, rarity in ipairs(Config.Rarities) do
        accumulated = accumulated + rarity.chance
        if rand <= accumulated then
            return rarity.name
        end
    end
    
    return 'Common'
end

-- ============================================
-- 車両抽選関数
-- ============================================
local function rollVehicle(gachaType)
    local rarity = rollRarity()
    local vehicles = GetVehiclesByRarity(gachaType, rarity)
    
    if #vehicles == 0 then
        print('^1[ng-vehiclegacha]^7 エラー: ガチャタイプ ' .. gachaType .. ' のレアリティ ' .. rarity .. ' に車両が存在しません')
        return nil
    end
    
    local selectedVehicle = vehicles[math.random(1, #vehicles)]
    
    return {
        model = selectedVehicle.vehicle_model,
        label = selectedVehicle.vehicle_label,
        rarity = selectedVehicle.rarity
    }
end

-- ============================================
-- 車両をガレージに追加
-- ============================================
local function addVehicleToGarage(source, vehicleModel)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local citizenid = Player.PlayerData.citizenid
    local plate = GeneratePlate()
    
    local vehicleData = {
        citizenid = citizenid,
        vehicle = vehicleModel,
        hash = GetHashKey(vehicleModel),
        mods = json.encode({}),
        plate = plate,
        garage = 'pillboxgarage',
        state = 0
    }
    
    MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        {Player.PlayerData.license, citizenid, vehicleModel, vehicleData.hash, vehicleData.mods, plate, vehicleData.garage, vehicleData.state})
    
    return true, plate
end

-- ============================================
-- プレートナンバー生成
-- ============================================
function GeneratePlate()
    local plate = QBCore.Shared.RandomStr(3) .. QBCore.Shared.RandomInt(3)
    local result = MySQL.query.await('SELECT plate FROM player_vehicles WHERE plate = ?', {plate})
    if result[1] then
        return GeneratePlate()
    end
    return plate:upper()
end

-- ============================================
-- 単発ガチャ実行処理
-- ============================================
lib.callback.register('ng-vehiclegacha:server:executeGacha', function(source, gachaType, paymentType)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {success = false, message = 'プレイヤーが見つかりません'} end
    
    local gachaSetting = GetGachaType(gachaType)
    if not gachaSetting then
        return {success = false, message = Config.Locale.gacha_disabled}
    end
    
    -- 支払い処理
    if paymentType == 'money' then
        local playerMoney = Player.PlayerData.money.cash
        if playerMoney < gachaSetting.price_money then
            return {success = false, message = Config.Locale.not_enough_money}
        end
        Player.Functions.RemoveMoney('cash', gachaSetting.price_money, 'vehicle-gacha')
        
    elseif paymentType == 'ticket' then
        local tickets = GetPlayerTickets(Player.PlayerData.citizenid)
        if tickets < gachaSetting.price_ticket then
            return {success = false, message = Config.Locale.not_enough_ticket}
        end
        UsePlayerTicket(Player.PlayerData.citizenid, gachaSetting.price_ticket)
    else
        return {success = false, message = '不正な支払い方法です'}
    end
    
    -- 車両抽選
    local vehicle = rollVehicle(gachaType)
    if not vehicle then
        if paymentType == 'money' then
            Player.Functions.AddMoney('cash', gachaSetting.price_money, 'vehicle-gacha-refund')
        elseif paymentType == 'ticket' then
            AddPlayerTickets(Player.PlayerData.citizenid, gachaSetting.price_ticket)
        end
        return {success = false, message = 'ガチャの抽選に失敗しました'}
    end
    
    -- 車両をガレージに追加
    local success, plate = addVehicleToGarage(source, vehicle.model)
    if not success then
        if paymentType == 'money' then
            Player.Functions.AddMoney('cash', gachaSetting.price_money, 'vehicle-gacha-refund')
        elseif paymentType == 'ticket' then
            AddPlayerTickets(Player.PlayerData.citizenid, gachaSetting.price_ticket)
        end
        return {success = false, message = '車両の追加に失敗しました'}
    end
    
    -- 履歴に記録
    AddGachaHistory(
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        gachaType,
        vehicle.model,
        vehicle.label,
        vehicle.rarity,
        paymentType
    )
    
    -- レアリティ情報を追加
    local rarityInfo = nil
    for _, r in ipairs(Config.Rarities) do
        if r.name == vehicle.rarity then
            rarityInfo = r
            break
        end
    end
    
    return {
        success = true,
        vehicle = {
            model = vehicle.model,
            label = vehicle.label,
            rarity = vehicle.rarity,
            rarityLabel = rarityInfo and rarityInfo.label or vehicle.rarity,
            rarityColor = rarityInfo and rarityInfo.color or '#FFFFFF',
            plate = plate
        },
        message = Config.Locale.gacha_success
    }
end)

-- ============================================
-- 10連ガチャ実行処理
-- ============================================
lib.callback.register('ng-vehiclegacha:server:executeMultiGacha', function(source, gachaType, paymentType)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {success = false, message = 'プレイヤーが見つかりません'} end
    
    local gachaSetting = GetGachaType(gachaType)
    if not gachaSetting then
        return {success = false, message = Config.Locale.gacha_disabled}
    end
    
    -- 10連の価格計算(割引適用)
    local multiCount = Config.MultiGacha.count
    local discount = Config.MultiGacha.discount
    local totalPrice = math.floor(gachaSetting.price_money * multiCount * (1 - discount))
    local totalTickets = math.floor(gachaSetting.price_ticket * multiCount * (1 - discount))
    
    -- 支払い処理
    if paymentType == 'money' then
        local playerMoney = Player.PlayerData.money.cash
        if playerMoney < totalPrice then
            return {success = false, message = Config.Locale.not_enough_money}
        end
        Player.Functions.RemoveMoney('cash', totalPrice, 'vehicle-gacha-multi')
        
    elseif paymentType == 'ticket' then
        local tickets = GetPlayerTickets(Player.PlayerData.citizenid)
        if tickets < totalTickets then
            return {success = false, message = Config.Locale.not_enough_ticket}
        end
        UsePlayerTicket(Player.PlayerData.citizenid, totalTickets)
    else
        return {success = false, message = '不正な支払い方法です'}
    end
    
    -- 10回抽選
    local vehicles = {}
    local failCount = 0
    
    for i = 1, multiCount do
        local vehicle = rollVehicle(gachaType)
        
        if vehicle then
            local success, plate = addVehicleToGarage(source, vehicle.model)
            
            if success then
                -- レアリティ情報取得
                local rarityInfo = nil
                for _, r in ipairs(Config.Rarities) do
                    if r.name == vehicle.rarity then
                        rarityInfo = r
                        break
                    end
                end
                
                table.insert(vehicles, {
                    model = vehicle.model,
                    label = vehicle.label,
                    rarity = vehicle.rarity,
                    rarityLabel = rarityInfo and rarityInfo.label or vehicle.rarity,
                    rarityColor = rarityInfo and rarityInfo.color or '#FFFFFF',
                    plate = plate
                })
                
                -- 履歴に記録
                AddGachaHistory(
                    Player.PlayerData.citizenid,
                    Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                    gachaType,
                    vehicle.model,
                    vehicle.label,
                    vehicle.rarity,
                    paymentType .. '_multi'
                )
            else
                failCount = failCount + 1
            end
        else
            failCount = failCount + 1
        end
    end
    
    -- 失敗があった場合は一部返金
    if failCount > 0 then
        local refundAmount = math.floor((totalPrice / multiCount) * failCount)
        local refundTickets = math.floor((totalTickets / multiCount) * failCount)
        
        if paymentType == 'money' then
            Player.Functions.AddMoney('cash', refundAmount, 'vehicle-gacha-multi-refund')
        elseif paymentType == 'ticket' then
            AddPlayerTickets(Player.PlayerData.citizenid, refundTickets)
        end
    end
    
    if #vehicles == 0 then
        return {success = false, message = 'ガチャの抽選に失敗しました'}
    end
    
    return {
        success = true,
        vehicles = vehicles,
        message = Config.Locale.multi_gacha_success
    }
end)

-- ============================================
-- プレイヤーのチケット数取得
-- ============================================
lib.callback.register('ng-vehiclegacha:server:getPlayerTickets', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return 0 end
    
    return GetPlayerTickets(Player.PlayerData.citizenid)
end)

-- ============================================
-- プレイヤーのガチャ履歴取得
-- ============================================
lib.callback.register('ng-vehiclegacha:server:getPlayerHistory', function(source, limit)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {} end
    
    return GetPlayerHistory(Player.PlayerData.citizenid, limit)
end)

-- ============================================
-- ガチャ統計取得
-- ============================================
lib.callback.register('ng-vehiclegacha:server:getGachaStats', function(source, gachaType)
    if not isAdmin(source) then return nil end
    return GetGachaStats(gachaType)
end)

if Config.Debug then
    print('^2[ng-vehiclegacha]^7 サーバーメイン処理がロードされました')
end
