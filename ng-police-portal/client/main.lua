local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local isNearPortal = false
local currentPortal = nil

-- プレイヤーデータ初期化
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

-- 権限チェック関数
local function HasPolicePermission()
    if not PlayerData.job then return false end
    
    for _, job in pairs(Config.PoliceJobs) do
        if PlayerData.job.name == job then
            return true
        end
    end
    return false
end

-- 3Dテキスト描画関数
local function DrawText3D(coords, text)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = #(vector3(px, py, pz) - coords)
    
    if onScreen and dist <= Config.Text3D.DrawDistance then
        local scale = (1 / dist) * 2
        local fov = (1 / GetGameplayCamFov()) * 100
        scale = scale * fov * Config.Text3D.Scale
        
        SetTextScale(0.0, scale)
        SetTextFont(Config.Text3D.Font)
        SetTextProportional(1)
        SetTextColour(Config.Text3D.Color.r, Config.Text3D.Color.g, Config.Text3D.Color.b, Config.Text3D.Color.a)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- マーカー描画関数
local function DrawPortalMarker(coords)
    DrawMarker(
        Config.Marker.Type,
        coords.x, coords.y, coords.z - 1.0,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        Config.Marker.Size.x, Config.Marker.Size.y, Config.Marker.Size.z,
        Config.Marker.Color.r, Config.Marker.Color.g, Config.Marker.Color.b, Config.Marker.Color.a,
        Config.Marker.BobUpAndDown,
        Config.Marker.FaceCamera,
        2,
        Config.Marker.Rotate,
        nil, nil, false
    )
end

-- テレポート先選択メニュー
local function OpenDestinationMenu(portal)
    if not HasPolicePermission() then
        lib.notify({
            title = 'アクセス拒否',
            description = Config.Notifications.NoPermission,
            type = 'error'
        })
        return
    end

    local options = {}
    
    for i, destination in pairs(portal.destinations) do
        table.insert(options, {
            title = destination.name,
            description = destination.description,
            icon = 'fas fa-map-marker-alt',
            onSelect = function()
                TeleportToDestination(destination)
            end
        })
    end
    
    lib.registerContext({
        id = 'ng_police_portal_menu',
        title = portal.name,
        options = options
    })
    
    lib.showContext('ng_police_portal_menu')
end

-- テレポート実行関数
function TeleportToDestination(destination)
    local ped = PlayerPedId()
    
    -- テレポート前エフェクト
    DoScreenFadeOut(500)
    Wait(500)
    
    -- プレイヤーを目的地に移動
    SetEntityCoords(ped, destination.coords.x, destination.coords.y, destination.coords.z, false, false, false, true)
    SetEntityHeading(ped, destination.coords.w or 0.0)
    
    -- カメラを適切に設定
    SetGameplayCamRelativeHeading(0)
    SetGameplayCamRelativePitch(0, 1.0)
    
    Wait(500)
    DoScreenFadeIn(500)
    
    -- 成功通知
    lib.notify({
        title = 'テレポート完了',
        description = destination.name .. 'に移動しました',
        type = 'success'
    })
    
    if Config.Debug then
        print('^2[ng-police-portal]^7 Teleported to: ' .. destination.name)
    end
end

-- メインスレッド
CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        isNearPortal = false
        currentPortal = nil
        
        for _, portal in pairs(Config.Portals) do
            local distance = #(playerCoords - portal.coords)
            
            -- マーカーの描画距離内にいる場合
            if distance <= Config.Marker.DrawDistance then
                sleep = 0
                DrawPortalMarker(portal.coords)
                
                -- テキスト表示
                if distance <= Config.Text3D.DrawDistance then
                    local displayText = portal.name
                    if distance <= Config.Marker.InteractDistance then
                        displayText = displayText .. "\n[" .. Config.Keys.Interact .. "] " .. Config.Notifications.SelectDestination
                    end
                    DrawText3D(portal.coords, displayText)
                end
                
                -- インタラクト距離内にいる場合
                if distance <= Config.Marker.InteractDistance then
                    isNearPortal = true
                    currentPortal = portal
                    break
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- キー入力処理
CreateThread(function()
    while true do
        Wait(0)
        
        if isNearPortal and currentPortal then
            if IsControlJustPressed(0, 38) then -- E キー
                OpenDestinationMenu(currentPortal)
            end
        else
            Wait(500)
        end
    end
end)

-- デバッグ用コマンド（デバッグモードが有効な場合のみ）
if Config.Debug then
    RegisterCommand('portal_debug', function()
        local playerCoords = GetEntityCoords(PlayerPedId())
        print('^3[ng-police-portal Debug]^7 Player Coords: ' .. playerCoords)
        
        for i, portal in pairs(Config.Portals) do
            local distance = #(playerCoords - portal.coords)
            print('^3Portal ' .. i .. ':^7 ' .. portal.name .. ' - Distance: ' .. math.floor(distance * 100) / 100)
        end
    end, false)
end