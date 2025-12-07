local QBCore = exports['qb-core']:GetCoreObject()
local playerCooldowns = {}

-- クールダウン開始
RegisterNetEvent('ng-antidistortion:server:startCooldown', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- クールダウン設定
    playerCooldowns[citizenid] = {
        startTime = os.time(),
        duration = Config.Cooldown
    }
    
    -- クライアントにクールダウン通知
    TriggerClientEvent('ng-antidistortion:client:setCooldown', src)
end)

-- クールダウンチェック
RegisterNetEvent('ng-antidistortion:server:checkCooldown', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local cooldownData = playerCooldowns[citizenid]
    
    if cooldownData then
        local currentTime = os.time()
        local elapsedTime = currentTime - cooldownData.startTime
        local remainingTime = cooldownData.duration - elapsedTime
        
        if remainingTime > 0 then
            -- クールダウン中
            TriggerClientEvent('ng-antidistortion:client:notifyCooldown', src, math.ceil(remainingTime))
        else
            -- クールダウン終了
            playerCooldowns[citizenid] = nil
        end
    end
end)

-- プレイヤー切断時のクリーンアップ
AddEventHandler('playerDropped', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local citizenid = Player.PlayerData.citizenid
        if playerCooldowns[citizenid] then
            playerCooldowns[citizenid] = nil
        end
    end
end)