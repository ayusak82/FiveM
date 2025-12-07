local QBCore = exports['qb-core']:GetCoreObject()

-- エフェクト関数の取得
local function PlayPreTeleportEffects(coords)
    TriggerEvent('ng-teleport:client:PlayPreTeleportEffects', coords)
end

local function PlayPostTeleportEffects(coords)
    TriggerEvent('ng-teleport:client:PlayPostTeleportEffects', coords)
end

-- ブラックリストゾーンのチェック
local function IsInBlacklistZone(coords)
    if not Config.BlacklistZones or #Config.BlacklistZones == 0 then 
        return false 
    end

    for _, zone in ipairs(Config.BlacklistZones) do
        local isInside = IsPointInPolygon(coords.x, coords.y, zone.points)
        if isInside then
            return true, zone.name
        end
    end
    return false
end

-- HP要件のチェック
local function CheckHealthRequirement()
    local ped = PlayerPedId()
    local health = GetEntityHealth(ped)
    local maxHealth = GetEntityMaxHealth(ped)
    local healthPercent = (health / maxHealth) * 100

    return healthPercent >= Config.RequiredHealth, math.floor(healthPercent)
end

-- テレポートの実行
local function DoTeleport(coords)
    local ped = PlayerPedId()
    local currentCoords = GetEntityCoords(ped)
    
    -- 基本チェック
    if IsPedInAnyVehicle(ped, false) then
        lib.notify({
            title = 'エラー',
            description = '車両に乗っているときはテレポートできません',
            type = 'error'
        })
        return false
    end
    
    -- HP要件チェック
    local hasEnoughHealth, currentHealth = CheckHealthRequirement()
    if not hasEnoughHealth then
        TriggerServerEvent('ng-teleport:server:LogError', {
            type = 'health',
            required = Config.RequiredHealth,
            current = currentHealth
        })
        lib.notify({
            title = 'エラー',
            description = string.format('HP が不足しています（現在: %d%%、必要: %d%%）', currentHealth, Config.RequiredHealth),
            type = 'error'
        })
        return false
    end
    
    -- ブラックリストゾーンチェック
    local isBlacklisted, zoneName = IsInBlacklistZone(currentCoords)
    if isBlacklisted then
        TriggerServerEvent('ng-teleport:server:LogError', {
            type = 'blacklist',
            zone = zoneName
        })
        lib.notify({
            title = 'エラー',
            description = string.format('この場所からはテレポートできません（%s）', zoneName),
            type = 'error'
        })
        return false
    end

    -- クールダウンチェック（サーバーサイド）
    local canTeleport = lib.callback.await('ng-teleport:server:CheckCooldown', false)
    if not canTeleport then
        return false
    end
    
    -- テレポート前エフェクト
    PlayPreTeleportEffects(currentCoords)
    
    -- フェードアウト
    DoScreenFadeOut(1000)
    Wait(1000)
    
    -- テレポート実行
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(coords.w)
    
    -- テレポート後エフェクト
    PlayPostTeleportEffects(coords)
    
    Wait(1000)
    DoScreenFadeIn(1000)

    -- テレポート成功ログ
    TriggerServerEvent('ng-teleport:server:LogSuccess', {
        from = currentCoords,
        to = coords
    })
    
    lib.notify({
        title = '成功',
        description = 'テレポートしました',
        type = 'success'
    })
    
    return true
end

-- テレポートメニューを開く
local function OpenTeleportMenu()
    local Player = QBCore.Functions.GetPlayerData()
    if not Player then return end

    local jobLocations = Config.TeleportLocations[Player.job.name]
    if not jobLocations then
        lib.notify({
            title = 'エラー',
            description = 'あなたの職業ではテレポートを使用できません',
            type = 'error'
        })
        return
    end

    local options = {}
    for _, location in ipairs(jobLocations.locations) do
        table.insert(options, {
            title = location.label,
            description = string.format('座標: %.1f, %.1f, %.1f', location.coords.x, location.coords.y, location.coords.z),
            icon = 'location-dot',
            onSelect = function()
                DoTeleport(location.coords)
            end
        })
    end

    lib.registerContext({
        id = 'ng_teleport_menu',
        title = jobLocations.label .. ' - テレポート',
        options = options
    })

    lib.showContext('ng_teleport_menu')
end

-- ポリゴン内のポイントチェック関数
function IsPointInPolygon(x, y, polygon)
    local inside = false
    local j = #polygon
    
    for i = 1, #polygon do
        if (((polygon[i].y > y) ~= (polygon[j].y > y)) and
            (x < (polygon[j].x - polygon[i].x) * (y - polygon[i].y) / 
            (polygon[j].y - polygon[i].y) + polygon[i].x)) then
            inside = not inside
        end
        j = i
    end
    
    return inside
end

-- コマンド登録
RegisterCommand('tpmenu', function()
    OpenTeleportMenu()
end)