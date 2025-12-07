local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local isInPortalRange = false
local currentPortal = nil
local lastTeleportTime = 0

-- プレイヤーデータの初期化
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

-- ポータルの制限チェック結果を受信
RegisterNetEvent('ng-teleport:client:portalResult', function(canUse, portalData, reason)
    if canUse then
        TeleportPlayer(portalData)
    else
        if reason == "cooldown" then
            local remainingTime = math.ceil(Config.Settings.cooldownTime - (GetGameTimer() - lastTeleportTime) / 1000)
            lib.notify({
                title = 'ポータル',
                description = Config.Locale["portal_cooldown"]:format(remainingTime),
                type = 'error',
                duration = Config.Settings.notificationTime
            })
        else
            lib.notify({
                title = 'ポータル',
                description = Config.Locale["portal_restricted"],
                type = 'error',
                duration = Config.Settings.notificationTime
            })
        end
    end
end)

-- テレポート実行
function TeleportPlayer(portalData)
    local ped = PlayerPedId()
    
    if Config.Settings.fadeScreen then
        DoScreenFadeOut(Config.Settings.fadeTime)
        Wait(Config.Settings.fadeTime)
        
        lib.notify({
            title = 'ポータル',
            description = Config.Locale["teleporting"],
            type = 'inform',
            duration = 2000
        })
    end
    
    -- テレポート実行
    SetEntityCoords(ped, portalData.teleportPos.x, portalData.teleportPos.y, portalData.teleportPos.z, false, false, false, true)
    SetEntityHeading(ped, portalData.teleportPos.w)
    
    Wait(500)
    
    if Config.Settings.fadeScreen then
        DoScreenFadeIn(Config.Settings.fadeTime)
    end
    
    -- 成功通知
    lib.notify({
        title = 'ポータル',
        description = Config.Locale["portal_teleport"]:format(portalData.name),
        type = 'success',
        duration = Config.Settings.notificationTime
    })
    
    lastTeleportTime = GetGameTimer()
end

-- キー入力チェック
function CheckKeyPress()
    CreateThread(function()
        while true do
            if isInPortalRange and currentPortal then
                if IsControlJustReleased(0, 38) then -- E キー
                    -- クールダウンチェック
                    local currentTime = GetGameTimer()
                    if (currentTime - lastTeleportTime) / 1000 < Config.Settings.cooldownTime then
                        local remainingTime = math.ceil(Config.Settings.cooldownTime - (currentTime - lastTeleportTime) / 1000)
                        lib.notify({
                            title = 'ポータル',
                            description = Config.Locale["portal_cooldown"]:format(remainingTime),
                            type = 'error',
                            duration = Config.Settings.notificationTime
                        })
                    else
                        -- サーバーに制限チェックを要求
                        TriggerServerEvent('ng-teleport:server:checkPortalRestriction', currentPortal.id)
                    end
                end
            end
            Wait(0)
        end
    end)
end

-- ポータルの距離チェック
function CheckPortalDistance()
    CreateThread(function()
        while true do
            local ped = PlayerPedId()
            local pedCoords = GetEntityCoords(ped)
            local wasInRange = isInPortalRange
            isInPortalRange = false
            currentPortal = nil
            
            for _, portal in pairs(Config.Portals) do
                local distance = #(pedCoords - portal.portalPos)
                
                if distance <= portal.interactDistance then
                    isInPortalRange = true
                    currentPortal = portal
                    
                    -- テキスト表示
                    lib.showTextUI(Config.Locale["press_to_teleport"]:format(portal.name), {
                        position = "top-center",
                        icon = 'fa-solid fa-portal-enter'
                    })
                    
                    if not wasInRange then
                        if Config.Settings.debug then
                            print("ポータル範囲に入りました: " .. portal.name)
                        end
                    end
                    break
                end
            end
            
            if wasInRange and not isInPortalRange then
                lib.hideTextUI()
                if Config.Settings.debug then
                    print("ポータル範囲を出ました")
                end
            end
            
            Wait(500)
        end
    end)
end

-- マーカー描画
function DrawPortalMarkers()
    CreateThread(function()
        while true do
            local ped = PlayerPedId()
            local pedCoords = GetEntityCoords(ped)
            
            for _, portal in pairs(Config.Portals) do
                local distance = #(pedCoords - portal.portalPos)
                
                if distance <= 50.0 then -- 描画距離
                    local marker = portal.marker
                    DrawMarker(
                        marker.type,
                        portal.portalPos.x, portal.portalPos.y, portal.portalPos.z,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        marker.size.x, marker.size.y, marker.size.z,
                        marker.color.r, marker.color.g, marker.color.b, marker.color.a,
                        marker.bobUpAndDown,
                        marker.faceCamera,
                        2, -- p19
                        marker.rotate,
                        nil, nil, -- テクスチャ
                        false -- プロジェクト
                    )
                end
            end
            
            Wait(0)
        end
    end)
end

-- スクリプト開始時の初期化
CreateThread(function()
    Wait(1000) -- QBCoreの初期化を待つ
    
    PlayerData = QBCore.Functions.GetPlayerData()
    
    -- 各機能を開始
    CheckKeyPress()
    CheckPortalDistance()
    DrawPortalMarkers()
    
    if Config.Settings.debug then
        print("ng-teleport: クライアント初期化完了")
    end
end)