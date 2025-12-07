local QBCore = exports['qb-core']:GetCoreObject()
local playerCooldowns = {}

-- 報酬を計算
local function CalculateReward(gameType, score)
    local gameData = Config.Minigames[gameType]
    if not gameData then return 0 end

    -- スコアに基づいて報酬を計算（0-100のスコアを想定）
    local rewardRange = gameData.reward.max - gameData.reward.min
    local reward = gameData.reward.min + math.floor((score / 100) * rewardRange)

    return math.max(gameData.reward.min, math.min(reward, gameData.reward.max))
end

-- クールダウンチェック
local function IsOnCooldown(source)
    local identifier = QBCore.Functions.GetPlayer(source).PlayerData.citizenid
    if not identifier then return false end

    if playerCooldowns[identifier] then
        local currentTime = os.time()
        if currentTime < playerCooldowns[identifier] then
            return true
        else
            playerCooldowns[identifier] = nil
        end
    end

    return false
end

-- クールダウン設定
local function SetCooldown(source)
    local identifier = QBCore.Functions.GetPlayer(source).PlayerData.citizenid
    if not identifier then return end

    playerCooldowns[identifier] = os.time() + Config.Cooldown
end

-- 報酬請求イベント
RegisterNetEvent('ng-sidejob:server:claimReward', function(gameType, score)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then
        if Config.Debug then
            print("Player not found: " .. src)
        end
        return
    end

    -- クールダウンチェック
    if IsOnCooldown(src) then
        TriggerClientEvent('QBCore:Notify', src, 'まだクールダウン中です', 'error')
        return
    end

    -- スコア検証（0-100の範囲）
    if type(score) ~= 'number' or score < 0 or score > 100 then
        if Config.Debug then
            print("Invalid score from player " .. src .. ": " .. tostring(score))
        end
        return
    end

    -- ゲームタイプ検証
    if not Config.Minigames[gameType] then
        if Config.Debug then
            print("Invalid game type from player " .. src .. ": " .. tostring(gameType))
        end
        return
    end

    -- 報酬計算
    local reward = CalculateReward(gameType, score)

    -- お金を追加
    Player.Functions.AddMoney('cash', reward, '内職報酬')

    -- クールダウン設定
    SetCooldown(src)

    -- 通知
    TriggerClientEvent('QBCore:Notify', src, string.format('内職完了！報酬: $%d を受け取りました', reward), 'success')

    -- ログ（オプション）
    if Config.Debug then
        print(string.format("[ng-sidejob] Player %s completed %s with score %d and received $%d", 
            Player.PlayerData.citizenid, gameType, score, reward))
    end
end)

-- プレイヤー切断時のクリーンアップ
AddEventHandler('playerDropped', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        local identifier = Player.PlayerData.citizenid
        -- クールダウンは保持（再接続時も有効）
    end
end)

-- リソース停止時のクリーンアップ
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if Config.Debug then
        print("[ng-sidejob] Resource stopped, clearing cooldowns")
    end
    
    playerCooldowns = {}
end)
