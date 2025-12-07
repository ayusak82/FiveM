local QBCore = exports['qb-core']:GetCoreObject()

-- プレイヤーのクールダウン管理
local playerCooldowns = {}

-- ポータルの制限をチェック
local function CheckPortalRestrictions(portalData)
    local restrictedJobs = portalData.restrictedJobs
    
    if not restrictedJobs or #restrictedJobs == 0 then
        return true -- 制限なし
    end
    
    -- オンラインプレイヤーをチェック
    local Players = QBCore.Functions.GetQBPlayers()
    
    for _, Player in pairs(Players) do
        if Player and Player.PlayerData and Player.PlayerData.job then
            local playerJob = Player.PlayerData.job.name
            
            -- 制限されたジョブのプレイヤーがオンラインかチェック
            for _, restrictedJob in pairs(restrictedJobs) do
                if playerJob == restrictedJob then
                    if Config.Settings.debug then
                        print("ポータル制限: " .. restrictedJob .. " のプレイヤーがオンラインです")
                    end
                    return false
                end
            end
        end
    end
    
    return true
end

-- プレイヤーのクールダウンをチェック
local function CheckPlayerCooldown(src)
    local currentTime = os.time()
    local lastUsed = playerCooldowns[src]
    
    if not lastUsed then
        return true
    end
    
    local timeDiff = currentTime - lastUsed
    return timeDiff >= Config.Settings.cooldownTime
end

-- クールダウンを設定
local function SetPlayerCooldown(src)
    playerCooldowns[src] = os.time()
end

-- ポータル制限チェックのイベント
RegisterNetEvent('ng-teleport:server:checkPortalRestriction', function(portalId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        if Config.Settings.debug then
            print("ng-teleport: プレイヤーデータが見つかりません - " .. src)
        end
        return
    end
    
    -- ポータルデータを取得
    local portalData = nil
    for _, portal in pairs(Config.Portals) do
        if portal.id == portalId then
            portalData = portal
            break
        end
    end
    
    if not portalData then
        if Config.Settings.debug then
            print("ng-teleport: ポータルが見つかりません - ID: " .. portalId)
        end
        return
    end
    
    -- クールダウンチェック
    if not CheckPlayerCooldown(src) then
        TriggerClientEvent('ng-teleport:client:portalResult', src, false, nil, "cooldown")
        return
    end
    
    -- ジョブ制限チェック
    local canUse = CheckPortalRestrictions(portalData)
    
    if canUse then
        -- クールダウン設定
        SetPlayerCooldown(src)
        
        -- ログ記録
        if Config.Settings.debug then
            print(string.format("ng-teleport: %s (ID: %s) がポータル '%s' を使用しました", 
                Player.PlayerData.name, src, portalData.name))
        end
    else
        if Config.Settings.debug then
            print(string.format("ng-teleport: %s (ID: %s) のポータル '%s' 使用が制限されました", 
                Player.PlayerData.name, src, portalData.name))
        end
    end
    
    -- 結果をクライアントに送信
    TriggerClientEvent('ng-teleport:client:portalResult', src, canUse, portalData, canUse and "success" or "restricted")
end)

-- プレイヤーが切断した時のクリーンアップ
RegisterNetEvent('QBCore:Server:OnPlayerUnload', function(src)
    if playerCooldowns[src] then
        playerCooldowns[src] = nil
        if Config.Settings.debug then
            print("ng-teleport: プレイヤーのクールダウンデータをクリーンアップしました - " .. src)
        end
    end
end)

-- サーバー起動時の初期化
CreateThread(function()
    Wait(1000)
    
    if Config.Settings.debug then
        print("=================================")
        print("ng-teleport: サーバー初期化完了")
        print("読み込まれたポータル数: " .. #Config.Portals)
        for _, portal in pairs(Config.Portals) do
            print("- " .. portal.name .. " (制限ジョブ: " .. table.concat(portal.restrictedJobs, ", ") .. ")")
        end
        print("=================================")
    end
end)

-- 管理者用コマンド（デバッグ用）
if Config.Settings.debug then
    RegisterCommand('ng-teleport-info', function(source, args, rawCommand)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        
        if not Player or Player.PlayerData.job.name ~= 'admin' then
            return
        end
        
        print("=== ng-teleport 情報 ===")
        print("アクティブなクールダウン: " .. tablelength(playerCooldowns))
        print("設定されたポータル: " .. #Config.Portals)
        
        local Players = QBCore.Functions.GetQBPlayers()
        print("オンラインプレイヤーのジョブ:")
        for _, Player in pairs(Players) do
            if Player and Player.PlayerData and Player.PlayerData.job then
                print("- " .. Player.PlayerData.name .. ": " .. Player.PlayerData.job.name)
            end
        end
    end, false)
end

-- テーブルの長さを取得するヘルパー関数
function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end