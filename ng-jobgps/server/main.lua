-- 変数の初期化
local QBCore = exports['qb-core']:GetCoreObject()
local playerPositions = {}
local playerGPSStatus = {} -- プレイヤーのGPS有効/無効状態を追跡

-- プレイヤーの位置情報を更新
RegisterNetEvent('ng-jobgps:server:updatePosition', function(coords, inVehicle, isDead, vehicleType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local job = Player.PlayerData.job.name
    local onDuty = Player.PlayerData.job.onduty
    
    -- 対象のジョブかどうか確認
    if not Config.Permissions[job] then
        -- 対象外のジョブの場合、位置情報を削除
        if playerPositions[src] then
            playerPositions[src] = nil
            playerGPSStatus[src] = nil
            broadcastGPSData()
        end
        return
    end
    
    -- オンデューティかどうか確認
    if not onDuty then
        -- オフデューティの場合、GPSデータを削除
        if playerPositions[src] then
            playerPositions[src] = nil
            broadcastGPSData()
        end
        return
    end
    
    -- GPSが無効になっている場合は位置情報を更新しない
    if playerGPSStatus[src] == false then return end
    
    playerPositions[src] = {
        source = src,
        name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        job = job,
        coords = coords,
        inVehicle = inVehicle,
        isDead = isDead,
        vehicleType = vehicleType
    }
    
    -- 全ての関連するプレイヤーにGPSデータを送信
    broadcastGPSData()
end)

-- ジョブ変更を検知するイベント（新規追加）
RegisterNetEvent('ng-jobgps:server:jobChanged', function(oldJob, newJob, oldDuty, newDuty)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- 古いジョブが対象ジョブで、新しいジョブが対象外、または新しくオフデューティになった場合
    local oldJobValid = Config.Permissions[oldJob] and oldDuty
    local newJobValid = Config.Permissions[newJob] and newDuty
    
    if oldJobValid and not newJobValid then
        -- GPS対象から外れた場合、位置情報を削除
        if playerPositions[src] then
            playerPositions[src] = nil
            playerGPSStatus[src] = nil
            print("Player " .. src .. " removed from GPS (job changed from " .. oldJob .. " to " .. newJob .. ")")
            broadcastGPSData()
        end
    elseif not oldJobValid and newJobValid then
        -- GPS対象になった場合、GPS状態をリセット
        playerGPSStatus[src] = true
        print("Player " .. src .. " added to GPS (job changed from " .. oldJob .. " to " .. newJob .. ")")
    end
end)

-- GPSの有効/無効を切り替えるイベント
RegisterNetEvent('ng-jobgps:server:toggleGPS', function(state)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local job = Player.PlayerData.job.name
    local onDuty = Player.PlayerData.job.onduty
    
    -- 対象のジョブかどうか確認
    if not Config.Permissions[job] then return end
    
    -- オンデューティかどうか確認
    if not onDuty and state then
        -- オフデューティでGPSをオンにしようとした場合は無視
        return
    end
    
    -- GPSステータスを更新
    playerGPSStatus[src] = state
    
    -- GPSが無効またはオフデューティになった場合、位置情報を削除
    if (state == false or not onDuty) and playerPositions[src] then
        playerPositions[src] = nil
    end
    
    -- 全プレイヤーにGPSデータを更新
    broadcastGPSData()
end)

-- クライアントからのデータ更新要求
RegisterNetEvent('ng-jobgps:server:requestUpdate', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local job = Player.PlayerData.job.name
    local onDuty = Player.PlayerData.job.onduty
    
    -- 対象のジョブかどうか確認
    if not Config.Permissions[job] then return end
    
    -- オンデューティかどうか確認
    if not onDuty then return end
    
    -- このプレイヤーのみにGPSデータを送信
    TriggerClientEvent('ng-jobgps:client:updateGPS', src, playerPositions)
end)

-- 全てのジョブGPSユーザーにデータをブロードキャスト
function broadcastGPSData()
    for _, Player in pairs(QBCore.Functions.GetQBPlayers()) do
        local src = Player.PlayerData.source
        local job = Player.PlayerData.job.name
        local onDuty = Player.PlayerData.job.onduty
        
        -- このジョブがGPSを使う権限があるか確認
        if Config.Permissions[job] and onDuty then
            TriggerClientEvent('ng-jobgps:client:updateGPS', src, playerPositions)
        end
    end
end

-- プレイヤーがサーバーから切断したときの処理
AddEventHandler('playerDropped', function()
    local src = source
    
    -- プレイヤーの位置情報をクリア
    if playerPositions[src] then
        playerPositions[src] = nil
        playerGPSStatus[src] = nil
        broadcastGPSData()
    end
end)

-- リソース起動時の初期化
AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    
    -- プレイヤー位置情報をクリア
    playerPositions = {}
    playerGPSStatus = {}
end)