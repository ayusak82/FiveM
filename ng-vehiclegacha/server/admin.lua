local QBCore = exports['qb-core']:GetCoreObject()

-- 管理者権限チェック関数
local function isAdmin(source)
    if not source then return false end
    return IsPlayerAceAllowed(source, 'command.admin')
end

-- ============================================
-- ガチャチケット付与コマンド
-- ============================================
RegisterCommand('vgacha_ticket', function(source, args)
    if not isAdmin(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = Config.Locale.no_permission
        })
        return
    end
    
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2]) or 1
    
    if not targetId then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = '使用方法: /vgacha_ticket [プレイヤーID] [枚数]'
        })
        return
    end
    
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'プレイヤーが見つかりません'
        })
        return
    end
    
    -- チケット付与
    AddPlayerTickets(targetPlayer.PlayerData.citizenid, amount)
    
    -- 通知
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = string.format(Config.Locale.ticket_given, amount)
    })
    
    TriggerClientEvent('ox_lib:notify', targetId, {
        type = 'success',
        description = string.format('ガチャチケットを%s枚受け取りました', amount)
    })
    
end, false)

-- ============================================
-- ガチャ有効/無効切り替えコマンド
-- ============================================
RegisterCommand('vgacha_toggle', function(source, args)
    if not isAdmin(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = Config.Locale.no_permission
        })
        return
    end
    
    local gachaType = args[1]
    local enabled = args[2] == '1' or args[2] == 'true'
    
    if not gachaType then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = '使用方法: /vgacha_toggle [ガチャタイプ] [0/1]'
        })
        return
    end
    
    ToggleGacha(gachaType, enabled and 1 or 0)
    
    local message = enabled and Config.Locale.gacha_toggled_on or Config.Locale.gacha_toggled_off
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = message
    })
    
end, false)

-- ============================================
-- 管理メニューコマンド
-- ============================================
RegisterCommand('vgacha_admin', function(source)
    if not isAdmin(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = Config.Locale.no_permission
        })
        return
    end
    
    TriggerClientEvent('ng-vehiclegacha:client:openAdminMenu', source)
end, false)

-- ============================================
-- 管理メニュー: ガチャ設定一覧取得
-- ============================================
lib.callback.register('ng-vehiclegacha:server:admin:getGachaSettings', function(source)
    if not isAdmin(source) then return nil end
    return MySQL.query.await('SELECT * FROM ng_vehiclegacha_settings ORDER BY id ASC')
end)

-- ============================================
-- 管理メニュー: 車両一覧取得
-- ============================================
lib.callback.register('ng-vehiclegacha:server:admin:getVehicles', function(source, gachaType)
    if not isAdmin(source) then return nil end
    
    if gachaType then
        return MySQL.query.await('SELECT * FROM ng_vehiclegacha_vehicles WHERE gacha_type = ? ORDER BY rarity, vehicle_label', {gachaType})
    else
        return MySQL.query.await('SELECT * FROM ng_vehiclegacha_vehicles ORDER BY gacha_type, rarity, vehicle_label')
    end
end)

-- ============================================
-- 管理メニュー: 車両追加
-- ============================================
lib.callback.register('ng-vehiclegacha:server:admin:addVehicle', function(source, data)
    if not isAdmin(source) then return {success = false, message = Config.Locale.no_permission} end
    
    if not data.gacha_type or not data.vehicle_model or not data.vehicle_label or not data.rarity then
        return {success = false, message = '必須項目が入力されていません'}
    end
    
    -- 重複チェック
    local exists = MySQL.query.await('SELECT id FROM ng_vehiclegacha_vehicles WHERE gacha_type = ? AND vehicle_model = ?', 
        {data.gacha_type, data.vehicle_model})
    
    if exists[1] then
        return {success = false, message = 'この車両は既に登録されています'}
    end
    
    AddVehicle(data.gacha_type, data.vehicle_model, data.vehicle_label, data.rarity)
    return {success = true, message = '車両を追加しました'}
end)

-- ============================================
-- 管理メニュー: 車両削除
-- ============================================
lib.callback.register('ng-vehiclegacha:server:admin:removeVehicle', function(source, vehicleId)
    if not isAdmin(source) then return {success = false, message = Config.Locale.no_permission} end
    
    RemoveVehicle(vehicleId)
    return {success = true, message = '車両を削除しました'}
end)

-- ============================================
-- 管理メニュー: 車両有効/無効切り替え
-- ============================================
lib.callback.register('ng-vehiclegacha:server:admin:toggleVehicle', function(source, vehicleId, enabled)
    if not isAdmin(source) then return {success = false, message = Config.Locale.no_permission} end
    
    ToggleVehicle(vehicleId, enabled and 1 or 0)
    return {success = true, message = '車両の状態を変更しました'}
end)

-- ============================================
-- 管理メニュー: ガチャ設定更新
-- ============================================
lib.callback.register('ng-vehiclegacha:server:admin:updateGachaSetting', function(source, data)
    if not isAdmin(source) then return {success = false, message = Config.Locale.no_permission} end
    
    MySQL.update.await([[
        UPDATE ng_vehiclegacha_settings 
        SET label = ?, price_money = ?, price_ticket = ?, icon = ?, enabled = ?
        WHERE gacha_type = ?
    ]], {data.label, data.price_money, data.price_ticket, data.icon, data.enabled, data.gacha_type})
    
    return {success = true, message = 'ガチャ設定を更新しました'}
end)

-- ============================================
-- 管理メニュー: 全体履歴取得
-- ============================================
lib.callback.register('ng-vehiclegacha:server:admin:getAllHistory', function(source, limit)
    if not isAdmin(source) then return nil end
    return GetAllHistory(limit or 100)
end)

-- ============================================
-- 管理メニュー: ガチャ統計取得
-- ============================================
lib.callback.register('ng-vehiclegacha:server:admin:getStats', function(source)
    if not isAdmin(source) then return nil end
    
    -- 全体統計
    local totalGachas = MySQL.query.await('SELECT COUNT(*) as count FROM ng_vehiclegacha_history')
    local totalPlayers = MySQL.query.await('SELECT COUNT(DISTINCT citizenid) as count FROM ng_vehiclegacha_history')
    
    -- ガチャタイプ別統計
    local byGachaType = MySQL.query.await([[
        SELECT gacha_type, COUNT(*) as count 
        FROM ng_vehiclegacha_history 
        GROUP BY gacha_type
    ]])
    
    -- レアリティ別統計
    local byRarity = MySQL.query.await([[
        SELECT rarity, COUNT(*) as count 
        FROM ng_vehiclegacha_history 
        GROUP BY rarity
    ]])
    
    -- 支払い方法別統計
    local byPayment = MySQL.query.await([[
        SELECT payment_type, COUNT(*) as count 
        FROM ng_vehiclegacha_history 
        GROUP BY payment_type
    ]])
    
    -- 人気車両TOP10
    local topVehicles = MySQL.query.await([[
        SELECT vehicle_label, vehicle_model, COUNT(*) as count 
        FROM ng_vehiclegacha_history 
        GROUP BY vehicle_model 
        ORDER BY count DESC 
        LIMIT 10
    ]])
    
    return {
        total_gachas = totalGachas[1].count,
        total_players = totalPlayers[1].count,
        by_gacha_type = byGachaType,
        by_rarity = byRarity,
        by_payment = byPayment,
        top_vehicles = topVehicles
    }
end)

-- ============================================
-- 管理メニュー: 新規ガチャタイプ追加
-- ============================================
lib.callback.register('ng-vehiclegacha:server:admin:addGachaType', function(source, data)
    if not isAdmin(source) then return {success = false, message = Config.Locale.no_permission} end
    
    -- 重複チェック
    local exists = MySQL.query.await('SELECT id FROM ng_vehiclegacha_settings WHERE gacha_type = ?', {data.gacha_type})
    if exists[1] then
        return {success = false, message = 'このガチャタイプは既に存在します'}
    end
    
    MySQL.insert.await([[
        INSERT INTO ng_vehiclegacha_settings (gacha_type, label, enabled, price_money, price_ticket, icon) 
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {data.gacha_type, data.label, data.enabled or 1, data.price_money or 10000, data.price_ticket or 1, data.icon or 'fa-solid fa-car'})
    
    return {success = true, message = 'ガチャタイプを追加しました'}
end)

-- ============================================
-- デバッグログ
-- ============================================
if Config.Debug then
    print('^2[ng-vehiclegacha]^7 管理者コマンドがロードされました')
end
