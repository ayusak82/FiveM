local QBCore = exports['qb-core']:GetCoreObject()

-- ============================================
-- 管理者権限チェック関数
-- ============================================

local function isAdmin(source)
    if not source then return false end
    return IsPlayerAceAllowed(source, 'command.admin')
end

-- ============================================
-- 車両ラベル取得関数（サーバー側用）
-- ============================================

local function GetVehicleLabel(model)
    -- QBCoreの車両データから取得を試みる
    local QBVehicles = QBCore.Shared.Vehicles
    if QBVehicles and QBVehicles[model] then
        return QBVehicles[model].name or QBVehicles[model].brand and QBVehicles[model].brand .. ' ' .. QBVehicles[model].model or model
    end
    
    -- Configのショップリストから取得を試みる
    for _, category in ipairs(Config.ShopVehicles) do
        for _, vehicle in ipairs(category.vehicles) do
            if vehicle.model == model then
                return vehicle.label
            end
        end
    end
    
    -- 見つからない場合はモデル名をそのまま返す
    return model:upper()
end

-- ============================================
-- 車両カード作成コマンド
-- ============================================

RegisterCommand('createvehiclecard', function(source, args)
    -- 権限チェック
    if not isAdmin(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'エラー',
            description = Locale.cmd_no_permission,
            type = 'error'
        })
        return
    end
    
    -- 引数チェック
    if not args[1] or not args[2] then
        TriggerClientEvent('ox_lib:notify', source, {
            title = '使用方法',
            description = Locale.cmd_create_usage,
            type = 'info'
        })
        return
    end
    
    local targetId = tonumber(args[1])
    local vehicleModel = string.lower(args[2])
    local uses = tonumber(args[3]) or Config.DefaultUses
    
    -- プレイヤーチェック
    if not targetId then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'エラー',
            description = Locale.cmd_invalid_player,
            type = 'error'
        })
        return
    end
    
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'エラー',
            description = Locale.cmd_player_offline,
            type = 'error'
        })
        return
    end
    
    -- 車両ラベルを取得
    local vehicleLabel = GetVehicleLabel(vehicleModel)
    
    -- メタデータ作成
    local metadata = {
        vehicle = vehicleModel,
        uses = uses,
        max_uses = uses,
        label = string.format('車両カード (%s)', vehicleLabel),
        description = string.format('使用回数: %d/%d', uses, uses)
    }
    
    -- アイテム付与
    local success = exports.ox_inventory:AddItem(targetId, 'vehicle_card', 1, metadata)
    
    if success then
        -- 管理者に通知
        TriggerClientEvent('ox_lib:notify', source, {
            title = '成功',
            description = string.format(Locale.cmd_created, vehicleLabel, uses),
            type = 'success'
        })
        
        -- 対象プレイヤーに通知
        TriggerClientEvent('ox_lib:notify', targetId, {
            title = 'アイテム受領',
            description = string.format(Locale.cmd_received, vehicleLabel),
            type = 'success'
        })
    else
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'エラー',
            description = Locale.shop_full_inventory,
            type = 'error'
        })
    end
end, false)

-- ============================================
-- 車両カード付与コマンド（別名）
-- ============================================

RegisterCommand('givevehiclecard', function(source, args)
    -- 権限チェック
    if not isAdmin(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'エラー',
            description = Locale.cmd_no_permission,
            type = 'error'
        })
        return
    end
    
    -- 引数チェック
    if not args[1] or not args[2] then
        TriggerClientEvent('ox_lib:notify', source, {
            title = '使用方法',
            description = Locale.cmd_give_usage,
            type = 'info'
        })
        return
    end
    
    local targetId = tonumber(args[1])
    local vehicleModel = string.lower(args[2])
    local uses = tonumber(args[3]) or Config.DefaultUses
    
    -- プレイヤーチェック
    if not targetId then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'エラー',
            description = Locale.cmd_invalid_player,
            type = 'error'
        })
        return
    end
    
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'エラー',
            description = Locale.cmd_player_offline,
            type = 'error'
        })
        return
    end
    
    -- 車両ラベルを取得
    local vehicleLabel = GetVehicleLabel(vehicleModel)
    
    -- メタデータ作成
    local metadata = {
        vehicle = vehicleModel,
        uses = uses,
        max_uses = uses,
        label = string.format('車両カード (%s)', vehicleLabel),
        description = string.format('使用回数: %d/%d', uses, uses)
    }
    
    -- アイテム付与
    local success = exports.ox_inventory:AddItem(targetId, 'vehicle_card', 1, metadata)
    
    if success then
        -- 管理者に通知
        TriggerClientEvent('ox_lib:notify', source, {
            title = '成功',
            description = string.format(Locale.cmd_given, targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname, vehicleLabel, uses),
            type = 'success'
        })
        
        -- 対象プレイヤーに通知
        TriggerClientEvent('ox_lib:notify', targetId, {
            title = 'アイテム受領',
            description = string.format(Locale.cmd_received, vehicleLabel),
            type = 'success'
        })
    else
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'エラー',
            description = Locale.shop_full_inventory,
            type = 'error'
        })
    end
end, false)

print('^2[ng-vehiclecard]^7 Commands loaded successfully')
