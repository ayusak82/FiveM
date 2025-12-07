local QBCore = exports['qb-core']:GetCoreObject()

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
-- スターターパック配布システム
-- ============================================

if Config.StarterPack.enabled then
    
    -- 新規プレイヤーチェック用のデータベーステーブル作成
    CreateThread(function()
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS ng_vehiclecard_starter (
                citizenid VARCHAR(50) PRIMARY KEY,
                received TINYINT(1) DEFAULT 0,
                received_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ]])
    end)
    
    -- プレイヤーがスターターパックを受け取ったかチェック
    local function hasReceivedStarter(citizenid)
        local result = MySQL.scalar.await('SELECT received FROM ng_vehiclecard_starter WHERE citizenid = ?', {citizenid})
        return result == 1
    end
    
    -- スターターパック受け取り記録
    local function markStarterReceived(citizenid)
        MySQL.insert('INSERT INTO ng_vehiclecard_starter (citizenid, received) VALUES (?, 1) ON DUPLICATE KEY UPDATE received = 1', {citizenid})
    end
    
    -- プレイヤー参加時の処理
    RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
        if not Player then return end
        
        local citizenid = Player.PlayerData.citizenid
        
        -- 既に受け取っている場合はスキップ
        if hasReceivedStarter(citizenid) then
            return
        end
        
        -- 少し待機（プレイヤーの初期化完了を待つ）
        Wait(5000)
        
        local source = Player.PlayerData.source
        if not source then return end
        
        -- スターターパックの車両カードを付与
        local success = true
        for _, vehicleData in ipairs(Config.StarterPack.vehicles) do
            -- 車両ラベルを取得
            local vehicleLabel = GetVehicleLabel(vehicleData.model)
            
            -- メタデータ作成
            local metadata = {
                vehicle = vehicleData.model,
                uses = vehicleData.uses,
                max_uses = vehicleData.uses,
                label = string.format('車両カード (%s)', vehicleLabel),
                description = string.format('使用回数: %d/%d | スターターパック', vehicleData.uses, vehicleData.uses)
            }
            
            -- アイテム付与
            local added = exports.ox_inventory:AddItem(source, 'vehicle_card', 1, metadata)
            if not added then
                success = false
                break
            end
        end
        
        if success then
            -- 受け取り記録
            markStarterReceived(citizenid)
            
            -- プレイヤーに通知
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'スターターパック',
                description = Locale.starter_received,
                type = 'success',
                duration = 7000
            })
        end
    end)
    
    -- 管理者用：スターターパックのリセットコマンド
    RegisterCommand('resetstarter', function(source, args)
        -- 権限チェック
        if not IsPlayerAceAllowed(source, 'command.admin') then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'エラー',
                description = Locale.cmd_no_permission,
                type = 'error'
            })
            return
        end
        
        if not args[1] then
            TriggerClientEvent('ox_lib:notify', source, {
                title = '使用方法',
                description = '使用方法: /resetstarter [プレイヤーID]',
                type = 'info'
            })
            return
        end
        
        local targetId = tonumber(args[1])
        local targetPlayer = QBCore.Functions.GetPlayer(targetId)
        
        if not targetPlayer then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'エラー',
                description = Locale.cmd_player_offline,
                type = 'error'
            })
            return
        end
        
        local citizenid = targetPlayer.PlayerData.citizenid
        
        -- データベースから削除
        MySQL.query('DELETE FROM ng_vehiclecard_starter WHERE citizenid = ?', {citizenid}, function(affectedRows)
            if affectedRows > 0 then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = '成功',
                    description = string.format('%s のスターターパック受け取り記録をリセットしました', 
                        targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname),
                    type = 'success'
                })
            else
                TriggerClientEvent('ox_lib:notify', source, {
                    title = '情報',
                    description = 'このプレイヤーはまだスターターパックを受け取っていません',
                    type = 'info'
                })
            end
        end)
    end, false)
    
    print('^2[ng-vehiclecard]^7 Starter pack system enabled')
else
    print('^3[ng-vehiclecard]^7 Starter pack system disabled')
end
